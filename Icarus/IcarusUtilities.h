//
//  IcarusUtilities.h
//  Icarus
//
//  Created by Andrea Gerino on 24/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IcarusUtilities : NSObject

+ (void) appendString: (NSString*) string toFileWithName: (NSString*) name;
+ (NSMutableDictionary*) nullObjectSanitizedDictionary: (NSDictionary*) dict;
+ (NSString *) md5: (NSString*) string;
+(NSString*) machineName;

@end