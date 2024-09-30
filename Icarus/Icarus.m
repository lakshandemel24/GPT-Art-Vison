//
//  Icarus.m
//  Icarus
//
//  Created by Andrea Gerino on 24/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//

#import "Icarus.h"

#import "IcarusUtilities.h"
#import "NetworkManager.h"

@interface Icarus ()

+(void) reportException: (NSException*) exception withUserInfo:(NSDictionary *)userInfo;

//Generic methods
+(void) getResourceAtURL: (NSString*) urlString withCallback: (void (^)(id resource, NSURLResponse * response, NSError * error)) block;
+(void) postResource:(id)resource atURL: (NSString*) urlString withCallback: (void (^)(id resource, NSURLResponse * response, NSError * error)) block;

@property (nonatomic, strong) NetworkManager* networkManager;

@end

@implementation Icarus

NSString * const kAPI_Entrypoint = @"https://webdev.ewlab.di.unimi.it/icarus";
NSString * const kAPI_Icarus_StorageRes = @"str";

NSString * const kDef_UUID = @"kDef_UUID";
NSString * const kLib_Name = @"Icarus";

NSString * const kApi_parameter_name = @"appname";
NSString * const kApi_parameter_version = @"appversion";

NSString * const kApi_parameter_os = @"os";
NSString * const kApi_parameter_device = @"device";
NSString * const kApi_parameter_uuid = @"uuid";
NSString * const kApi_parameter_lang = @"lang";
NSString * const kApi_parameter_voiceover = @"voiceover";

NSString * const kApi_parameter_timestamp = @"timestamp";
NSString * const kApi_parameter_utc = @"utc";
NSString * const kApi_parameter_user = @"user";
NSString * const kApi_parameter_app_data = @"appdata";
NSString * const kApi_parameter_user_data = @"userdata";

NSString * const kApi_parameter_exception = @"exception";
NSString * const kApi_parameter_exception_name = @"name";
NSString * const kApi_parameter_exception_reason = @"reason";
NSString * const kApi_parameter_exception_callstack = @"callstack";
NSString * const kApi_parameter_exception_catched = @"catched";
NSString * const kApi_parameter_exception_user_info = @"userinfo";

NSString * const kApi_parameter_debug = @"debug";

static Icarus* _instance = nil;

void IcarusExceptionHandler (NSException * exception){
    
    [Icarus performReportException:exception withUserInfo:nil isCatched:NO];
    
}

+(Icarus*) instance{
    
    if (_instance==nil) {
        
        _instance = [[Icarus alloc] initProperly];
        
    }
    
    return _instance;
    
}

-(Icarus*) init{
    
    NSAssert(false, @"This object cannot be directly initialized");
    return nil;
    
}

-(Icarus*) initProperly{
    
    self = [super init];
    if (self) {
    
        [self setNetworkManager:[[NetworkManager alloc] init]];

        NSSetUncaughtExceptionHandler(IcarusExceptionHandler);
        
    }
    
    return self;
    
}

+(void) fetchResourceWithID: (NSString*) r_id andCallback: (void (^)(id resource, NSURLResponse * response, NSError * error)) block{
    
    [Icarus getResourceAtURL:[NSString stringWithFormat:@"%@/%@/%@",kAPI_Entrypoint,kAPI_Icarus_StorageRes,r_id] withCallback:block];
    
}

+(void) pushResource:(id)resource withCallback: (void (^)(id resource, NSURLResponse * response, NSError * error)) block{

    [Icarus postResource:resource atURL:[NSString stringWithFormat:@"%@/%@/",kAPI_Entrypoint,kAPI_Icarus_StorageRes] withCallback:block];
    
}

+(void) reportException:(NSException *)exception withUserInfo: (NSDictionary*) userInfo{

    [self performReportException:exception withUserInfo:userInfo isCatched:YES];
    
}

+(void) performReportException:(NSException *)exception withUserInfo: (NSDictionary*) userInfo isCatched: (BOOL) catched{
    
    NSMutableDictionary* exceptionDictionary = [NSMutableDictionary dictionary];
    [exceptionDictionary setObject:[exception name] forKey:kApi_parameter_exception_name];
    [exceptionDictionary setObject:@(catched) forKey:kApi_parameter_exception_catched];
    [exceptionDictionary setObject:[exception reason] forKey:kApi_parameter_exception_reason];

    if([exception callStackSymbols]!=nil){
    
        [exceptionDictionary setObject:[exception callStackSymbols] forKey:kApi_parameter_exception_callstack];
    
    }
    
    if(userInfo!=nil){
        
        [exceptionDictionary setObject:userInfo forKey:kApi_parameter_exception_user_info];
        
    }
    
    [Icarus postResource:@{kApi_parameter_exception: exceptionDictionary} atURL:[NSString stringWithFormat:@"%@/%@/",kAPI_Entrypoint,kAPI_Icarus_StorageRes] withCallback:nil];
    
}

#pragma mark Generic methods

+(void) getResourceAtURL:(NSString *) urlString withCallback:(void (^)(id _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))block{
    
    Icarus* me = [Icarus instance];
    [[me networkManager] getResourceAtURL:urlString withCallback:^(NSData * data, NSURLResponse * response, NSError * error) {
        
        [me handleResponse:response withError:error andData:data andCallback:block];
        
    }];
    
}

+(void) postResource:(id)resource atURL:(NSString *) urlString withCallback:(void (^)(id, NSURLResponse *, NSError *))block{
    
    //if([resource isKindOfClass:[NSDictionary class]]||[resource isKindOfClass:[NSArray class]]){

        Icarus* me = [Icarus instance];
        
        NSDictionary* toBeSent = [me dictionaryWithAppInformationAndResource:resource];
        
        NSError* JSONError;
        NSData* toBeSentData;
        
        @try {

            toBeSentData = [NSJSONSerialization dataWithJSONObject:toBeSent options:0 error: &JSONError];
            
        }
        @catch (NSException *exception) {
            
            [Icarus reportException:exception withUserInfo:nil];
            
        }
        
        if(JSONError==noErr){
            
            // Convert JSON data to string format for logging
            //NSString *jsonString = [[NSString alloc] initWithData:toBeSentData encoding:NSUTF8StringEncoding];
            
            //NSLog(@"Request Body: %@", jsonString);
            
            [[me networkManager] postResource:toBeSentData atURL:urlString withCallback:^(NSData * data, NSURLResponse * response, NSError * error) {
                
                [me handleResponse:response withError:error andData:data andCallback:block];
                
            }];
        
        }else{
            
            block(nil, nil, JSONError);
            
        }
        
    //}else{
        
        //NSLog(@"Posting resources of class %@ is not supported by this version of Icarus",[resource class]);
        
    //}
    
}

#pragma mark - Helper methods

- (void)handleResponse:(NSURLResponse *)response withError:(NSError *)error andData:(NSData *)data andCallback:(void (^)(id, NSURLResponse *, NSError *))callback {

    if(error==noErr&&data!=nil){
        
        // Cast NSURLResponse to NSHTTPURLResponse to access the status code
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        //NSInteger statusCode = httpResponse.statusCode;
        
        // Log the status code
        //NSLog(@"HTTP Status Code: %ld", (long)statusCode);
        
        //Check if data is a JSONObject and build it, otherwise return the raw data
        NSError* JSONError;
        id responseJSONObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&JSONError];
        
        if(JSONError==noErr){

            if(callback!=nil)
                callback(responseJSONObject, response, noErr);
            
        }else{

            if(callback!=nil)
                callback(data, response, noErr);
            
        }
        
    }else{
        
        // Log the error if there is one
        if (error != nil) {
            NSLog(@"Request failed with error: %@", error.localizedDescription);
        }

        if(callback!=nil)
            callback(nil, response, error);
        
    }

}

-(NSDictionary*) dictionaryWithAppInformationAndResource: (id) resource{

    NSTimeZone* userTimezone = [NSTimeZone localTimeZone];
    
    NSTimeInterval absoluteSeconds = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval relativeSeconds = absoluteSeconds + [userTimezone secondsFromGMT];
    
    NSDictionary* timeDictionary = @{@"utc":@(absoluteSeconds),@"user":@(relativeSeconds)};
    
    NSString* loggingLibrary = @"MUSA_Logging_System";//[NSString stringWithFormat:@"%@:%f", kLib_Name, IcarusVersionNumber];

    NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSString* appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString* appLang = [[NSLocale preferredLanguages] objectAtIndex:0];

    NSString* os = [[UIDevice currentDevice] systemVersion];
    NSString* device = [IcarusUtilities machineName];
    
    NSString* uuid = [self getUUID];

    NSNumber* voiceover = [NSNumber numberWithBool:UIAccessibilityIsVoiceOverRunning()];
    
    NSMutableDictionary *appObject = [[NSMutableDictionary alloc] init];
    [appObject setObject:loggingLibrary forKey:kApi_parameter_lang];
    
    [appObject setObject:appName forKey:kApi_parameter_name];
    [appObject setObject:appVersion forKey:kApi_parameter_version];
    [appObject setObject:appLang forKey:kApi_parameter_lang];
    
    [appObject setObject:os forKey:kApi_parameter_os];
    [appObject setObject:device forKey:kApi_parameter_device];
    
    [appObject setObject:uuid forKey:kApi_parameter_uuid];
    
    [appObject setObject:voiceover forKey:kApi_parameter_voiceover];
    
    BOOL debug;
    
#ifdef DEBUG

    debug = 1;

#else

    debug = 0;

#endif
    
    return @{kApi_parameter_debug:@(debug),kApi_parameter_timestamp:timeDictionary,kApi_parameter_app_data:appObject,kApi_parameter_user_data:resource};
    
}

-(NSString*) getUUID{
    
    NSString* uuid = [[NSUserDefaults standardUserDefaults] objectForKey:kDef_UUID];
    if(uuid==nil){
        
        uuid = [[NSUUID UUID] UUIDString];
        [[NSUserDefaults standardUserDefaults] setObject:uuid forKey:kDef_UUID];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
    }
    
    return uuid;
    
}

@end
