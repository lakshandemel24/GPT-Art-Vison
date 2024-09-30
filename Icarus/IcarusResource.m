//
//  Resource.m
//  Icarus
//
//  Created by Andrea Gerino on 24/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//

#import "IcarusResource.h"
#import "IcarusUtilities.h"

@interface IcarusResource ()

@end

@implementation IcarusResource

-(IcarusResource*) initWithURL: (NSString*) url andPayload: (NSData*) payload{

    self = [super init];
    if (self) {
        
        [self setUrlString:url];
        [self setPayload:payload];
    
    }
    
    return self;
    
}

-(IcarusResource*) initWithURL: (NSString*) url{
    
    return [self initWithURL:url andPayload:nil];
    
}

-(IcarusResource*) initWithDictionary: (NSDictionary*) dictionary{
    
    if(dictionary!=nil){
        
        NSString* url = [dictionary objectForKey:@"url"];
        NSData* payload = [dictionary objectForKey:@"payload"];
        
        return [self initWithURL:url andPayload:payload];
        
    }
    
    return nil;
    
}

#pragma mark - 

-(NSString*) description{

    return [IcarusUtilities md5:[[self asDictionary] description]];
    
}

-(BOOL) isEqual:(id)object{
    
    if([object class]!=[self class]){
        
        return NO;
        
    }else{

        IcarusResource* castedObject = (IcarusResource*) object;
        
        if(![[castedObject UrlString] isEqual:[self UrlString]])
            return NO;
        
        if(![[castedObject description] isEqual:[self description]])
            return NO;
        
    }
    
    return YES;
    
}

#pragma mark - Persistence helper methods

-(NSDictionary*) asDictionary{
    
    NSMutableDictionary* returnDictionary = [[NSMutableDictionary alloc] init];
    
    if ([self UrlString]!=nil) {
    
        [returnDictionary setObject:[self UrlString] forKey:@"url"];
    
    }
    
    if ([self payload]!=nil) {
        
        [returnDictionary setObject:[self payload] forKey:@"payload"];
        
    }
    
    return returnDictionary;
    
}

@end