//
//  COTaskOperation.m
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 13/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import "COTaskOperation.h"
#import "COAsynchronousAF.h"


@interface COTaskOperation ()
{
    COConnectionTask * _task;
}
@property (atomic, strong) AFHTTPRequestOperation * request;
@property (atomic, assign) BOOL canceled;
@property (atomic, assign) BOOL finished;
- (void)requestFinished:(AFHTTPRequestOperation *)request responseObject:(id) responseObject;
- (void)requestFailed:(AFHTTPRequestOperation *)request error:(NSError *) error;
@end

@implementation COTaskOperation
@synthesize task = _task;
@synthesize request = _request;
@synthesize delegate;
@synthesize finished = _finished;

- (id) init
{
    return [self initWithTask: nil];
}

- (id) initWithTask:(COConnectionTask *)task
{
    return  [self initWithTask: task andDelegate: nil];
}

- (id) initWithTask:(COConnectionTask *)task andDelegate:(NSObject<COTaskOperationDelegate> *) theDelegate
{
    self = [super init];
    if(self)
    {
        self.task = task;
        self.delegate = theDelegate;
        self.canceled = NO;
        self.finished = NO;
    }
    return self;
}

- (void) main
{
    self.request = [[AFHTTPRequestOperation alloc] initWithRequest: [NSURLRequest requestWithURL:self.task.url]];
    __weak AFHTTPRequestOperation * operation = self.request;
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self requestFinished: operation responseObject: responseObject];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self requestFailed: operation error: error];
    }];
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperation:operation];
}

- (BOOL)isFinished
{
    return self.finished;
}

- (void)setFinished:(BOOL)finished
{
    [self willChangeValueForKey: @"isFinished"];
    _finished = finished;
    [self didChangeValueForKey: @"isFinished"];
}

- (void)setCanceled:(BOOL)canceled
{
    [self willChangeValueForKey: @"isCanceled"];
    _canceled = canceled;
    [self didChangeValueForKey: @"isCanceled"];
}

- (BOOL)isCancelled
{
    return self.canceled;
}

- (BOOL)cancel
{
    self.canceled = YES;
    return self.canceled;
}


#pragma mark ASIHTTPRequestDelegate
- (void)requestFinished:(AFHTTPRequestOperation *)request responseObject:(id) responseObject
{
    if([self.delegate respondsToSelector:@selector(operation:taskCompleteDone:withResult:)])
        [self.delegate operation: self taskCompleteDone: self.task withResult:responseObject];
    self.finished = YES;
}

- (void)requestFailed:(AFHTTPRequestOperation *)request error:(NSError *) error
{
    if([self.delegate respondsToSelector:@selector(operation:taskWentWrong:withError:)])
        [self.delegate operation: self taskWentWrong: self.task withError: [request error]];
    self.finished = YES;
}

@end
