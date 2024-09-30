//
//  Resource.h
//  Icarus
//
//  Created by Andrea Gerino on 24/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IcarusResource : NSObject

@property (nonatomic, strong) NSString* UrlString;
@property (nonatomic, strong) NSData* payload;

-(IcarusResource*) initWithURL: (NSString*) url;
-(IcarusResource*) initWithURL: (NSString*) url andPayload: (NSData*) payload;
-(IcarusResource*) initWithDictionary: (NSDictionary*) dictionary;

-(NSDictionary*) asDictionary;

@end