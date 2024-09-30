//
//  NetworkManager.m
//  Icarus
//
//  Created by Andrea Gerino on 26/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//

#import "NetworkManager.h"
#import "FsStorage.h"

@interface NetworkManager (){
    
    NSURLSession* myUrlSession;
    
    id <LocalStorageProtocol> dataStore;
    NSMutableDictionary* callbackStore;
    
}

@end

@implementation NetworkManager

-(NetworkManager*) init{
    
    self = [super init];
    if (self) {
    
        myUrlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration ephemeralSessionConfiguration]];
        callbackStore = [[NSMutableDictionary alloc] init];
        
        dataStore = [[FsStorage alloc] init];
        
        //Check for pending objects
        [self checkPendingResources];
        
    }
    
    return self;

}

-(void) getResourceAtURL:(NSString *)urlString withCallback:(void (^)(NSData *, NSURLResponse *, NSError *))block{

    NSURL* myUrl = [NSURL URLWithString:urlString];
    NSURLSessionDataTask* myTask = [myUrlSession dataTaskWithURL:myUrl completionHandler:block];
    [myTask resume];

}

-(void) postResource:(NSData *)data atURL:(NSString *)urlString withCallback:(void (^)(NSData *, NSURLResponse *, NSError *))block {

    //Build the IcarusResource Object
    IcarusResource* newResource = [[IcarusResource alloc] initWithURL:urlString andPayload:data];
    
    //Store the callback
    [callbackStore setObject:block forKey:[newResource description]];
    
    //Store the object
    [dataStore appendResource:newResource];
    
    //Check for pending objects
    [self checkPendingResources];
    
}

-(void) checkPendingResources{
    
    IcarusResource* nextResource = [dataStore nextResource];
    if(nextResource!=nil){
        
        [self performPostIcaruseResource:nextResource];
        
    }
    
}

-(void) performPostIcaruseResource: (IcarusResource*) resource{
    
    NSURL* myUrl = [NSURL URLWithString:[resource UrlString]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:myUrl];
    
    request.HTTPMethod = @"POST";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    request.HTTPBody = resource.payload;
    
    void (^block)(NSData *, NSURLResponse *, NSError *) = [callbackStore objectForKey:[resource description]];
    
    NSURLSessionDataTask* myTask = [myUrlSession dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if(error==noErr){
        
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*) response;
            
            if(httpResponse.statusCode==201){

                [self->dataStore removeResource:resource];
                
            }
            
            [self checkPendingResources];
            
        }
        
        if (block!=nil)
            block(data, response, error);
        
    }];
    
    [myTask resume];
    
}

@end
