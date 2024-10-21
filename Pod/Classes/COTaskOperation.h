//
//  COTaskOperation.h
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 13/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COConnectionTask.h"

@class COTaskOperation;

@protocol COTaskOperationDelegate <NSObject>

- (void) operation:(COTaskOperation *) operation taskCompleteDone:(COConnectionTask *) task withResult:(id) result;
- (void) operation:(COTaskOperation *) operation taskWentWrong:(COConnectionTask *) task withError:(NSError *) error;

@end

@interface COTaskOperation : NSOperation
@property (atomic, strong) COConnectionTask * task;
@property (nonatomic, weak) NSObject<COTaskOperationDelegate> * delegate;

- (id) initWithTask:(COConnectionTask *) task;
- (id) initWithTask:(COConnectionTask *)task andDelegate:(NSObject<COTaskOperationDelegate> *) theDelegate;
@end
