//
//  FsStorage.m
//  Icarus
//
//  Created by Andrea Gerino on 25/11/15.
//  Copyright © 2015 EveryWare Technologies. All rights reserved.
//

#import "FsStorage.h"

#define kAttemptThreshold 1800

@interface FsStorage (){
    
    NSMutableDictionary* pendingResources;
    
}

@end

@implementation FsStorage

- (FsStorage*)init{
    
    self = [super init];
    if (self) {
        
        pendingResources = [[NSMutableDictionary alloc] init];
        
    }
    
    return self;
    
}

-(BOOL) appendResource:(IcarusResource *)resource{

    NSString* objectId = [resource description];
    //NSLog(@"<Icarus:FS> Appending object: %@", objectId);

    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString* filePath = [NSString stringWithFormat:@"%@/%@.icarus", documentsPath, objectId];

    NSDictionary* resourceDictionaryRepresentation = [resource asDictionary];
    
    BOOL saved = NO;
    
    @synchronized(pendingResources) {

        saved = [resourceDictionaryRepresentation writeToFile:filePath atomically:YES];;
        
    }
    
    return saved;
    
}

-(IcarusResource*) nextResource{
    
    //NSLog(@"<Icarus:FS> - Checking for pending resources");
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    IcarusResource* toBeReturned = nil;
    
    @synchronized(pendingResources) {
        
        NSArray *filelist= [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsPath error:nil];
        if ([filelist count]>0) {
            
            //NSLog(@"<Icarus:FS> - I have %lu scheduled POSTs", (unsigned long)[filelist count]);
            
            NSString* nextResourceFilePath;
            
            for(NSString* fileName in filelist){
                
                if(![fileName containsString:@".icarus"])
                    continue;
                
                NSString* candidateResourceFilePath = [NSString stringWithFormat:@"%@/%@",documentsPath,fileName];
                
                if([pendingResources objectForKey:candidateResourceFilePath]==nil){
                    
                    //We never tried to send the object
                    nextResourceFilePath = candidateResourceFilePath;
                    break;
                    
                }else{
                    
                    //We tried before. Let's check if enough time has passed
                    NSDate* lastAttemptDate = [pendingResources objectForKey:candidateResourceFilePath];
                    if(fabs([lastAttemptDate timeIntervalSinceNow])>kAttemptThreshold){

                        //NSLog(@"Resource %@ has been waiting more than %us", candidateResourceFilePath, kAttemptThreshold);
                        nextResourceFilePath = candidateResourceFilePath;
                        break;
                    
                    }else{
                        
                        //NSLog(@"Resource %@ should wait %us", candidateResourceFilePath, kAttemptThreshold);
                        
                    }
                    
                }
                
            }
            
            if(nextResourceFilePath!=nil){
                
                NSDictionary* fileDictionary = [NSDictionary dictionaryWithContentsOfFile:nextResourceFilePath];
                
                toBeReturned = [[IcarusResource alloc] initWithDictionary:fileDictionary];
                [pendingResources setObject:[NSDate date] forKey: nextResourceFilePath];
                
            }
            
        }
        
    }
    
    return toBeReturned;
    
}

-(BOOL) removeResource:(IcarusResource *)resource{
    
    NSString* documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    NSString* objectId = [resource description];
    //NSLog(@"<Icarus:FS> Deleting object: %@", objectId);

    NSString* filePath = [NSString stringWithFormat:@"%@/%@.icarus", documentsPath, objectId];
    
    @synchronized(pendingResources) {
    
        NSError* deletionError;
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:&deletionError];
        
        if(deletionError!=noErr){
            
            //NSLog(@"<Icarus:FS> - Error while deleting object: %@", deletionError);
            return false;
            
        }else{
            
            [pendingResources removeObjectForKey:filePath];
            
        }
    
    }
    
    return true;
    
}

@end