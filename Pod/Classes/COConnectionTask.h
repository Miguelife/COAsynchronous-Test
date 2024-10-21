//
//  COConnectionTask.h
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 13/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "COConnectionManagerDelegate.h"

@interface COConnectionTask : NSObject
@property (nonatomic, strong) NSURL * url;
@property (nonatomic, strong) NSString * pathToSave;
@property (nonatomic, strong) NSMutableArray * delegates;
@property (nonatomic, assign) CGRect scalingRect;
@property (nonatomic, strong) NSString * typeOfFile;
- (id) initWithURL:(NSURL *) url andPathToSave:(NSString *) path;
- (id) initWithURL:(NSURL *) url withPathToSave:(NSString *) path andDelegates:(NSMutableArray *) delegates;
- (BOOL) existDelegate:(NSObject<COConnectionManagerDelegate> *) delegate;
- (void) appendDelegate:(NSObject<COConnectionManagerDelegate> *) delegate;
- (void) removeDelegate:(NSObject<COConnectionManagerDelegate> *) delegate;
- (NSString *) notificationString;
- (NSString *) notificationErrorString;
@end
