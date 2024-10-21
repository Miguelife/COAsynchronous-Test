//
//  COAudioCache.m
//  COAsyncFramework
//
//  Created by Pablo Viciano Negre on 11/01/13.
//  Copyright (c) 2013 Cuatroochenta. All rights reserved.
//

#import "COAudioCache.h"
#import <COCommons/Commons.h>
#import "COConnectionManager.h"

#define DEFAULT_PATH_AUDIO_CACHE [[COFileUtils defaultImagePathLibrary] stringByAppendingPathComponent: @"Audio Cache"]
#define TYPE_OF_FILE @"AUDIO"
@interface COAudioCache ()<COConnectionManagerDelegate>
@property (atomic, strong) NSFileManager * fileManager;
@property (nonatomic, weak) COConnectionManager * connectionManager;
@property (atomic, strong) NSMutableSet * delegates;
- (NSString *) pathToSaveWithFileName:(NSString *) fileName;
- (NSData *) loadAudioWithFileName:(NSString *) fileName;
@end

@implementation COAudioCache
GTMOBJECT_SINGLETON_BOILERPLATE(COAudioCache, sharedInstance);

- (id)init
{
    self = [super init];
    if (self) {
        self.connectionManager = [COConnectionManager getInstance];
        self.fileManager = [NSFileManager defaultManager];
        self.log = NO;
        self.delegates = [[NSMutableSet alloc] init];
        [self createFolder];
    }
    return self;
}

- (void)addDelegate:(NSObject<COAudioCacheDelegate> *)delegate
{
    [self.delegates addObject: delegate];
}

- (void)removeDelegate:(NSObject<COAudioCacheDelegate> *)delegate
{
    [self.delegates removeObject: delegate];
}

- (void)createFolder
{
    BOOL isDirectory = NO;
    NSError * error;
    
    if(!([[NSFileManager defaultManager] fileExistsAtPath: DEFAULT_PATH_AUDIO_CACHE isDirectory:&isDirectory] && isDirectory))
    {
        [[NSFileManager defaultManager]  createDirectoryAtPath: DEFAULT_PATH_AUDIO_CACHE withIntermediateDirectories:YES attributes:nil error:&error];
        [COFileUtils addSkipBackupAttributeToFile: DEFAULT_PATH_AUDIO_CACHE];
    }
    if(self.log)
    {
        NSLog(@"Created path %@", DEFAULT_PATH_AUDIO_CACHE);
    }
}

+ (NSString *)audioCacheFolderPath
{
    return DEFAULT_PATH_AUDIO_CACHE;
}

- (void)removeAudioWithFileName:(NSString *) fileName
{
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath: DEFAULT_PATH_AUDIO_CACHE error: nil];
    for(NSString * file in files)
    {
        if([file caseInsensitiveCompare: fileName] == NSOrderedSame)
        {
            NSString * path = [DEFAULT_PATH_AUDIO_CACHE stringByAppendingPathComponent: file];
            NSError * error = nil;
            [self.fileManager removeItemAtPath: path error: &error];
            if(self.log)
            {
                NSLog(@"Removed file %@", path);
            }
        }
    }
}

- (NSData *) audioSynchronouslyForURL:(NSURL *)url withFileName:(NSString *)fileName
{
    if([self existAudioWithFileName: fileName])
        return [self loadAudioWithFileName: fileName];
    if(self.log)
        NSLog(@"Audio %@ not exist, download synchronously", fileName);
    COConnectionTask * task = [[COConnectionTask alloc] initWithURL: url andPathToSave: [self pathToSaveWithFileName: fileName]];
    task.typeOfFile = TYPE_OF_FILE;
    return [self.connectionManager downloadDataSynchronously: task];
}

- (void) audioForURL:(NSURL *)url withFileName:(NSString *)fileName
{
    if([self existAudioWithFileName: fileName])
    {
        NSSet * delegates = [NSSet setWithSet: self.delegates];
        for(NSObject<COAudioCacheDelegate> * delegate in delegates)
        {
            if([delegate respondsToSelector:@selector(audioCache:didSuccessFullDownloadAudioData:withFileName:)])
                [delegate audioCache:self didSuccessFullDownloadAudioData: [self loadAudioWithFileName: fileName] withFileName: fileName];
        }
    }else
    {
        COConnectionTask * task = [[COConnectionTask alloc] initWithURL: url andPathToSave: [self pathToSaveWithFileName: fileName]];
        task.typeOfFile = TYPE_OF_FILE;
        [task appendDelegate: self];
        [[COConnectionManager getInstance] executeDownloadTask: task];
    }
}

- (void)removeAllAudios
{
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath: DEFAULT_PATH_AUDIO_CACHE error: nil];
    for(NSString * file in files)
    {
        NSString * path = [DEFAULT_PATH_AUDIO_CACHE stringByAppendingPathComponent: file];
        NSError * error = nil;
        [self.fileManager removeItemAtPath: path error: &error];
        if(self.log)
        {
            NSLog(@"Removed file %@", path);
        }
    }
}

- (BOOL) existAudioWithFileName:(NSString *) fileName
{
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath: DEFAULT_PATH_AUDIO_CACHE error: nil];
    for(NSString * file in files)
    {
        if([file caseInsensitiveCompare: fileName] == NSOrderedSame)
            return YES;
    }
    return NO;
}

#pragma mark Private methods
- (NSString *) pathToSaveWithFileName:(NSString *) fileName
{
    return [DEFAULT_PATH_AUDIO_CACHE stringByAppendingPathComponent: fileName];
}

- (NSData *) loadAudioWithFileName:(NSString *) fileName
{
    return [NSData dataWithContentsOfFile: [self pathToSaveWithFileName:fileName]];
}

#pragma mark COConnectionManagerDelegate

- (void)connectionManager:(COConnectionManager *)manager didFailedObject:(COConnectionTask *)object withError:(NSError *)error
{
    NSSet * delegates = [NSSet setWithSet: self.delegates];
    for(NSObject<COAudioCacheDelegate> * delegate in delegates)
    {
        if([delegate respondsToSelector:@selector(audioCache:failToDownloadAudioWithError:)])
            [delegate audioCache: self failToDownloadAudioWithError: error];
    }
}

- (void) connectionManager:(COConnectionManager *)manager didFinishDownloadObject:(COConnectionTask *)object withResult:(id)result
{
    if([object.typeOfFile isEqualToString: TYPE_OF_FILE])
    {
        NSSet * delegates = [NSSet setWithSet: self.delegates];
        NSString * fileName = [object.pathToSave lastPathComponent];
        for(NSObject<COAudioCacheDelegate> * delegate in delegates)
        {
            if([delegate respondsToSelector:@selector(audioCache:didSuccessFullDownloadAudioData:withFileName:)])
                [delegate audioCache:self didSuccessFullDownloadAudioData:result withFileName: fileName];
        }
    }
}

@end
