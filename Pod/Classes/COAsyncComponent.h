//
//  COAsyncComponent.h
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 14/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol COAsyncComponent <NSObject>
- (void) subscribeToNotification:(NSString *) notification andNotificationError:(NSString *) notificationError;
- (void) setImage:(UIImage *) image;
@end
