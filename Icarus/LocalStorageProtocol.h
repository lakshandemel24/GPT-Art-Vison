//
//  LocalStorageProtocol.h
//  Icarus
//
//  Created by Andrea Gerino on 24/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "IcarusResource.h"

@protocol LocalStorageProtocol <NSObject>

-(BOOL) appendResource: (IcarusResource*) resource;
-(BOOL) removeResource: (IcarusResource*) resource;

-(IcarusResource*) nextResource;

@end