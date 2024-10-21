//
//  COConnectionManager.h
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 13/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "COConnectionTask.h"

@interface COConnectionManager : NSObject

@property (atomic, assign) NSUInteger maxConcurrentTasks;
@property (atomic, readonly) NSUInteger currentTasks;
@property (nonatomic, strong) NSString * defaultPath;
@property (atomic, assign) BOOL log;

+ (COConnectionManager *) getInstance;
- (void) downloadTask:(COConnectionTask *) task;
- (void) executeDownloadTask:(COConnectionTask *) task;
- (NSData *) downloadDataSynchronously:(COConnectionTask *) task;
@end
