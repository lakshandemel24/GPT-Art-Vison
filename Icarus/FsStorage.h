//
//  FsStorage.h
//  Icarus
//
//  Created by Andrea Gerino on 25/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LocalStorageProtocol.h"

// IMPORTANT: FsStorage will persist only objects that can be natively serialized to a Dictionary. If you need a more flexible solution consider <NSCoding> and CoreData

@interface FsStorage : NSObject <LocalStorageProtocol>

@end
