//
//  VolatileStorage.m
//  Icarus
//
//  Created by Andrea Gerino on 25/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//

#import "VolatileStorage.h"

@interface VolatileStorage (){
    
    NSMutableArray* resourceArray;
    NSMutableSet* pendingResources;

}

@end

@implementation VolatileStorage

- (VolatileStorage*)init{
    
    self = [super init];
    if (self) {
        
        resourceArray = [[NSMutableArray alloc] init];
        pendingResources = [[NSMutableSet alloc] init];
        
    }
    
    return self;
    
}

-(BOOL) appendResource:(IcarusResource *)resource{
    
    @try {
        
        @synchronized(resourceArray) {

            [resourceArray addObject:resource];
            
        }
        
        return true;
        
    }
    
    @catch (NSException *exception) {
    
        //NSLog(@"%@", exception);
        
    }
    
    return false;
    
}

-(IcarusResource*) nextResource{
    
    IcarusResource* nextResource = nil;
    
    @synchronized(resourceArray) {
        
        if([resourceArray count]>0){
        
            for(IcarusResource* resource in resourceArray){
                
                if(![pendingResources containsObject:resource]){
                    
                    nextResource = resource;
                    break;
                    
                }
                
            }
            
        }
        
        if(nextResource!=nil)
            [pendingResources addObject:nextResource];

    }

    return nextResource;
    
}

-(BOOL) removeResource:(IcarusResource *)resource{
    
    @synchronized(resourceArray){
    
        [resourceArray removeObject:resource];
        
    }
    
    return true;
    
}

@end
