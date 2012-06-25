//
//  EDStorageManager.m
//  storage
//
//  Created by Andrew Sliwinski on 6/23/12.
//  Copyright (c) 2012 DIY, Co. All rights reserved.
//

#import "EDStorageManager.h"

//

@interface EDStorageManager ()
@property (nonatomic, retain) NSOperationQueue *queue;
@end

//

@implementation EDStorageManager

@synthesize queue;

#pragma mark - Init

+ (EDStorageManager *)sharedInstance
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (id)init
{
    self = [super init];
    if (self)
    {
        NSOperationQueue *tQueue = [[NSOperationQueue alloc] init];
        self.queue = tQueue;
        self.queue.maxConcurrentOperationCount = 2;
        
        //
        
        [tQueue release];
    }
    return self;
}

#pragma mark - Public methods

- (void)persistData:(id)data withExtension:(NSString *)ext toLocation:(Location)location success:(void (^)(NSURL *, NSUInteger))success failure:(void (^)(NSException *))failure
{       
    // Create URL
    NSURL *url = [self createAssetFileURLForLocation:location withExtension:ext];
    
    // Perform operation
    EDStorageOperation *operation = [[EDStorageOperation alloc] initWithData:data forURL:url];
    [operation setCompletionBlock:^{
        // @note Handle errors & exceptions here...
        success(operation.target, operation.size);
                
        //
        
        [operation setCompletionBlock:nil];     // Force dealloc
    }];
    [queue addOperation:operation];
    [operation release];
}

#pragma mark - Private methods

/**
 * Creates an asset file url (path) using location declaration and file extension.
 *
 * @param {Location} ENUM type
 * @param {NSString} Extension (e.g. @"jpg")
 *
 * @return {NSURL}
 */
- (NSURL *)createAssetFileURLForLocation:(Location)location withExtension:(NSString *)extension
{
    NSArray *paths = nil;
    NSString *directory = nil;
    
    switch (location) {
        case kEDStorageDirectoryCache:
            paths          = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
            directory      = [paths objectAtIndex:0];
            break;
        case kEDStorageDirectoryTemp:
            directory      = NSTemporaryDirectory();
            break;
        case kEDStorageDirectoryDocuments:
            paths          = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
            directory      = [paths objectAtIndex:0];
            break;
        default:
            break;
    }
    
    NSString *assetName    = [NSString stringWithFormat:@"%@.%@", [[NSProcessInfo processInfo] globallyUniqueString], extension];
    NSString *assetPath    = [directory stringByAppendingPathComponent:assetName];
    
    return [NSURL fileURLWithPath:assetPath];
}

#pragma mark - Dealloc

- (void)releaseObjects
{
    [queue release]; queue = nil;
}

- (void)dealloc
{
    [self releaseObjects];
    [super dealloc];
}

@end