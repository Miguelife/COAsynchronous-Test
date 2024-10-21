//
//  COConnectionTask.m
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 13/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import "COConnectionTask.h"
#import <COCommons/Commons.h>
#import "COAsyncConstants.h"

@interface COConnectionTask ()
{
    NSURL * _url;
    NSString * _pathToSave;
    NSMutableArray * _delegates;
}
@end

@implementation COConnectionTask
@synthesize url = _url;
@synthesize pathToSave = _pathToSave;
@synthesize delegates = _delegates;


- (id) init
{
    return [self initWithURL: nil andPathToSave: nil];
}

- (id) initWithURL:(NSURL *) theUrl andPathToSave:(NSString *) path
{
    return [self initWithURL: theUrl withPathToSave: path andDelegates: nil];
}

- (id) initWithURL:(NSURL *) theUrl withPathToSave:(NSString *) path andDelegates:(NSMutableArray *) delegates;
{
    self = [super init];
    if(self)
    {
        self.url = theUrl;
        self.pathToSave = path;
        self.delegates = delegates;
        self.scalingRect = CGRectNull;
    }
    return self;
}

- (NSString *)notificationString
{
    NSMutableString * notification = [[self.url absoluteString] mutableCopy];
    if(!CGRectEqualToRect(self.scalingRect, CGRectNull)) [notification insertString:NSStringFromCGRect(self.scalingRect) atIndex:notification.length - 4];
    return notification;
}

- (NSString *) notificationErrorString
{
    return [self.notificationString stringByAppendingString: NOTIFICATION_APPENDIX_ERROR];
}

- (BOOL)isEqual:(id)object
{
    if(![object isKindOfClass: [self class]])
        return NO;
    COConnectionTask * other = (COConnectionTask *) object;
    return [self.url isEqualToURL: other.url];
}

- (NSMutableArray *) delegates
{
    if(!_delegates)
    {
        _delegates = [[NSMutableArray alloc] init];
    }
    return _delegates;
}

- (BOOL) existDelegate:(NSObject<COConnectionManagerDelegate> *) delegate
{
    return delegate && [self.delegates containsObject: delegate];
}

- (void) appendDelegate:(NSObject<COConnectionManagerDelegate> *) delegate
{
    if(delegate && ![self existDelegate: delegate])
        [self.delegates addObject: delegate];
}

- (void) removeDelegate:(NSObject<COConnectionManagerDelegate> *) delegate
{
    if(delegate && [self existDelegate: delegate])
        [self.delegates removeObject: delegate];
        
}

@end
