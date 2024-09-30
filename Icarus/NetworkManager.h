//
//  NetworkManager.h
//  Icarus
//
//  Created by Andrea Gerino on 26/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NetworkManager : NSObject

-(void) getResourceAtURL: (NSString*) urlString withCallback: (void (^)(NSData *, NSURLResponse *, NSError *))block;
-(void) postResource:(NSData*) data atURL: (NSString*) urlString withCallback: (void (^)(NSData *, NSURLResponse *, NSError *))block;
//-(void) putResource:(NSData*) data atURL: (NSString*) urlString withCallback: (void (^)(NSData *, NSURLResponse *, NSError *))block;
//-(void) deleteResourceAtURL: (NSString*) urlString withCallback: (void (^)(NSData *, NSURLResponse *, NSError *))block;

@end