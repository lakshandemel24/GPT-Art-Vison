//
//  IcarusUtilities.m
//  Icarus
//
//  Created by Andrea Gerino on 24/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//

#import "IcarusUtilities.h"
#import <CommonCrypto/CommonDigest.h>
#import <sys/utsname.h>

@implementation IcarusUtilities

+ (void) appendString: (NSString*) string toFileWithName: (NSString*) name{
    
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *path = [documentsPath stringByAppendingPathComponent:name];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:path]) {
        
        NSError *error = noErr;
        [@"" writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
    }
    
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:path];
    [fileHandle seekToEndOfFile];
    
    NSData *textData = [string dataUsingEncoding:NSUTF8StringEncoding];
    [fileHandle writeData:textData];
    [fileHandle closeFile];
    
}

+ (NSMutableDictionary*) nullObjectSanitizedDictionary: (NSDictionary*) dict{
    
    NSMutableDictionary *sanitizedDict = [NSMutableDictionary dictionary];
    
    for(id key in [dict allKeys]){
        
        id obj = [dict objectForKey:key];
        if([obj isKindOfClass:[NSDictionary class]]){
            
            [sanitizedDict setObject:[self nullObjectSanitizedDictionary:obj] forKeyedSubscript:key];
            
        }else{
            
            if(![obj isKindOfClass:[NSNull class]])
                [sanitizedDict setValue:obj forKey:key];
            
        }
        
    }
    
    return sanitizedDict;
    
}

+ (NSString *)md5: (NSString*) string{
    
    const char *cStr = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (int)strlen(cStr), result );
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
    
}

+(NSString*) machineName{
    
    struct utsname systemInfo;
    uname(&systemInfo);
    
    return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    
}

@end