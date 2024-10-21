//
//  COAudioCache.h
//  COAsyncFramework
//
//  Created by Pablo Viciano Negre on 11/01/13.
//  Copyright (c) 2013 Cuatroochenta. All rights reserved.
//

#import <Foundation/Foundation.h>

@class COAudioCache;

@protocol COAudioCacheDelegate <NSObject>
- (void) audioCache:(COAudioCache *) audioCache didSuccessFullDownloadAudioData:(NSData *) data withFileName:(NSString *) fileName;
- (void) audioCache:(COAudioCache *) audioCache failToDownloadAudioWithError:(NSError *) error;
@end

@interface COAudioCache : NSObject
@property (atomic, assign) BOOL log;
+ (COAudioCache *) sharedInstance;
+ (NSString *) audioCacheFolderPath;

- (void) addDelegate:(NSObject<COAudioCacheDelegate> *) delegate;
- (void) removeDelegate:(NSObject<COAudioCacheDelegate> *) delegate;

- (void) createFolder;
- (BOOL) existAudioWithFileName:(NSString *) audioFileName;
- (NSData *) audioSynchronouslyForURL:(NSURL *) url withFileName:(NSString *) fileName;
- (void) audioForURL:(NSURL *) url withFileName:(NSString *) fileName;
- (void) removeAudioWithFileName:(NSString *) audioFilename;
- (void) removeAllAudios;
@end
