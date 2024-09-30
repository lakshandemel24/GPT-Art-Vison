//
//  Icarus.h
//  Icarus
//
//  Created by Andrea Gerino on 24/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//
//  Keep the right distance from the sun
//

#import <UIKit/UIKit.h>

FOUNDATION_EXPORT double IcarusVersionNumber;
FOUNDATION_EXPORT const unsigned char IcarusVersionString[];

@interface Icarus : NSObject

+(Icarus*) instance;

//Default methods
+(void) fetchResourceWithID: (NSString*) r_id andCallback: (void (^)(id resource, NSURLResponse * response, NSError * error)) block;
+(void) pushResource:(id)resource withCallback: (void (^)(id resource, NSURLResponse * response, NSError * error)) block;
+(void) reportException:(NSException *)exception withUserInfo: (NSDictionary*) userInfo;

@end