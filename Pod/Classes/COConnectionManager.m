//
//  COConnectionManager.m
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 13/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import "COConnectionManager.h"
#import "COTaskOperation.h"
#import <COCommons/Commons.h>
#import <pthread.h>

#define MAX_CONCURRENT_TASKS 15
#define TIMER_INTERVAL 0.5
#define DEFAULT_PATH_CONNECTION_MANAGER [[COFileUtils defaultImagePathLibrary] stringByAppendingPathComponent: @"Connection Manager"]

@interface COConnectionManager ()<COTaskOperationDelegate>
{
    NSObject<COQueue> * _taskQueue;
    NSOperationQueue * _operationQueue;
    NSUInteger _maxConcurrentTasks;
    NSString * _defaultPath;
    BOOL _log;
    
    pthread_mutex_t task_mutex;
    pthread_mutex_t timer_mutex;
    pthread_mutex_t operation_update_mutex;
    
    NSTimer * _updateTimer;
}

@property (atomic, strong) NSOperationQueue * operationQueue;
@property (atomic, strong) NSObject<COQueue> * taskQueue;
@property (atomic, strong) NSTimer * updateTimer;

- (void) startNextOperation;
- (void) startTimer;
- (void) doUpdate;
- (void) stopTimer;
- (void) updateTimerState;
@end

@implementation COConnectionManager
@synthesize operationQueue = _operationQueue;
@synthesize taskQueue = _taskQueue;

@synthesize maxConcurrentTasks = _maxConcurrentTasks;
@synthesize currentTasks;

@synthesize defaultPath = _defaultPath;
@synthesize updateTimer = _updateTimer;
@synthesize log = _log;

GTMOBJECT_SINGLETON_BOILERPLATE(COConnectionManager, getInstance);

- (id) init
{
    self = [super init];
    if(self)
    {
        pthread_mutex_init(&task_mutex, NULL);
        pthread_mutex_init(&timer_mutex, NULL);
        pthread_mutex_init(&operation_update_mutex, NULL);
        self.defaultPath = [DEFAULT_PATH_CONNECTION_MANAGER copy];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.maxConcurrentTasks = MAX_CONCURRENT_TASKS;
        self.taskQueue = [[CODefaultQueue alloc] init];
        self.log = NO;
    }
    return self;
}

- (void)dealloc
{
    pthread_mutex_destroy(&task_mutex);
    pthread_mutex_destroy(&timer_mutex);
    pthread_mutex_destroy(&operation_update_mutex);
    [_updateTimer invalidate];
}

- (NSUInteger) currentTasks
{
    if(self.operationQueue)
        return self.operationQueue.operationCount;
    return 0;
}
- (void)setDefaultPath:(NSString *)defaultPath
{
    _defaultPath = defaultPath;
    BOOL isDirectory = NO;
    NSError * error;
    
    if(!([[NSFileManager defaultManager] fileExistsAtPath: _defaultPath isDirectory:&isDirectory] && isDirectory))
    {
        [[NSFileManager defaultManager]  createDirectoryAtPath: _defaultPath withIntermediateDirectories:YES attributes:nil error:&error];
        [COFileUtils addSkipBackupAttributeToFile: _defaultPath];
    }
    if(self.log)
    {
        NSLog(@"Created path %@", _defaultPath);
    }
}

- (void) downloadTask:(COConnectionTask *)task
{
    [self executeDownloadTask: task];
}

- (void) executeDownloadTask:(COConnectionTask *) task
{
    //NSString * notification = [task notificationString];
    BOOL found = NO;
    for(COTaskOperation * operation in self.operationQueue.operations)
    {
        if([operation.task isEqual: task])
        {
            pthread_mutex_lock(&operation_update_mutex);
            for(NSObject<COConnectionManagerDelegate> * delegate in task.delegates)
                [operation.task appendDelegate: delegate];
            
            found = YES;
            //notification = [operation.task notificationString];
            if(self.log)
            {
                NSLog(@"Updated listener in task %@", [task notificationString]);
            }
            pthread_mutex_unlock(&operation_update_mutex);
            break;
        }
    }
    if(!found)
    {
        if([self.taskQueue contains: task])
        {
            COConnectionTask * qTask = (COConnectionTask * )[self.taskQueue getObject: task];
            for(NSObject<COConnectionManagerDelegate> * delegate in task.delegates)
                [qTask appendDelegate: delegate];
            
            if(self.log)
            {
                NSLog(@"Updated listener in task %@", [task notificationString]);
            }
            
            //notification = [qTask notificationString];
            
        }else
            [self.taskQueue push_back: task];
    }
    
    if(!self.updateTimer)
        [self startTimer];
    
    
    //return notification;
}

- (NSData *) downloadDataSynchronously:(COConnectionTask *) task
{
    NSString * path = task.pathToSave;
    if(!task.pathToSave || [task.pathToSave compare: @""] == NSOrderedSame)
    {
        path = [self.defaultPath stringByAppendingPathComponent:[COFileUtils getFileNameForUrl: task.url]];
    }
    NSData * data = [[NSData alloc] initWithContentsOfURL: task.url];
    if(self.log)
    {
        NSLog(@"Download data %@", [task notificationString]);
    }
    [data writeToFile: path atomically: YES];
    return data;
}

#pragma mark Private methods

- (void) startNextOperation
{
    pthread_mutex_lock(&task_mutex);
    if(self.currentTasks < self.maxConcurrentTasks && ![self.taskQueue empty])
    {
        COConnectionTask * task = (COConnectionTask *) [self.taskQueue top] ;
        [self.taskQueue pop];
        if(!task.pathToSave || [task.pathToSave compare: @""] == NSOrderedSame)
        {
            task.pathToSave = [self.defaultPath stringByAppendingPathComponent:[COFileUtils getFileNameForUrl: task.url]];
        }
        
        for(NSObject<COConnectionManagerDelegate> * delegate in task.delegates)
        {
            if([delegate respondsToSelector:@selector(connectionManager:didStartDownloadObject:)])
                [delegate connectionManager: self didStartDownloadObject: task];
        }
        
        COTaskOperation * operation = [[COTaskOperation alloc] initWithTask: task andDelegate: self];
        [self.operationQueue addOperation: operation];
        
        if(self.log)
        {
            NSLog(@"Created operation for task %@", [task notificationString]);
        }
    }else
    {
        [self updateTimerState];
    }
    pthread_mutex_unlock(&task_mutex);
}

- (void) startTimer
{
    pthread_mutex_lock(&timer_mutex);
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval: TIMER_INTERVAL target: self selector:@selector(doUpdate) userInfo:nil repeats:YES];
    if(self.log)
    {
        NSLog(@"Started update timer");
    }
    pthread_mutex_unlock(&timer_mutex);
}

- (void) doUpdate
{
    while(![self.taskQueue empty] && self.currentTasks < self.maxConcurrentTasks)
        [self startNextOperation];
    if (self.log) {
        NSLog(@"Update timer %d operations and %d taks", self.operationQueue.operationCount, self.taskQueue.count);
    }
}

- (void) stopTimer
{
    pthread_mutex_lock(&timer_mutex);
    [self.updateTimer invalidate];
    self.updateTimer = nil;
    if(self.log)
    {
        NSLog(@"Stopped update timer %d operations and %d taks", self.operationQueue.operationCount, self.taskQueue.count);
    }
    pthread_mutex_unlock(&timer_mutex);
}

- (void) updateTimerState
{
    
    if([self.taskQueue empty])
        [self stopTimer];
 }

#pragma mark COTaskOperationDelegate
- (void)operation:(COTaskOperation *)operation taskCompleteDone:(COConnectionTask *)task withResult:(id) result
{
    BOOL success = NO;
    if([result isKindOfClass:[NSData class]])
       success = [((NSData *) result) writeToFile: task.pathToSave
                             atomically: YES];
    for(NSObject<COConnectionManagerDelegate> * delegate in task.delegates)
    {
        if([delegate respondsToSelector:@selector(connectionManager:didFinishDownloadObject:withResult:)])
            [delegate connectionManager: self didFinishDownloadObject: task withResult: result];
    }
    [self updateTimerState];
    //[operation release];
    if(self.log)
    {
        NSLog(@"Task %@ completed done!! %d operations and %d taks",  [task notificationString], self.operationQueue.operationCount, self.taskQueue.count);
    }

}

- (void)operation:(COTaskOperation *)operation taskWentWrong:(COConnectionTask *)task withError:(NSError *)error
{
 
    for(NSObject<COConnectionManagerDelegate> * delegate in task.delegates)
    {
        if([delegate respondsToSelector:@selector(connectionManager:didFailedObject:withError:)])
            [delegate connectionManager: self didFailedObject: task withError:error];
    }
    [self updateTimerState];
    if(self.log)
    {
        NSLog(@"Task %@ with errors :(  %d operations and %d taks",  [task notificationString], self.operationQueue.operationCount, self.taskQueue.count);
    }

}

@end
