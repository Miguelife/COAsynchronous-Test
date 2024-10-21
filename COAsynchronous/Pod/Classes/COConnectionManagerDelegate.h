//
//  COConnectionManagerDelegate.h
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 13/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import <Foundation/Foundation.h>

@class COConnectionManager;
@class COConnectionTask;

@protocol COConnectionManagerDelegate <NSObject>
@optional
- (void) connectionManager:(COConnectionManager *) manager didStartDownloadObject:(COConnectionTask *) object;
- (void) connectionManager:(COConnectionManager *)manager didFinishDownloadObject:(COConnectionTask *) object withResult:(id) result;
- (void) connectionManager:(COConnectionManager *)manager didFailedObject:(COConnectionTask *) object withError:(NSError *) error;

@end
