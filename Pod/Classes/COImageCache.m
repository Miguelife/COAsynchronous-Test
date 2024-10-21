//
//  COImageCache.m
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 14/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import "COImageCache.h"
#import <COCommons/Commons.h>
#import "COImageId.h"
#import <pthread.h>
#import "COConnectionManagerDelegate.h"
#import "COConnectionManager.h"
#import <ImageIO/ImageIO.h>


#define MEMORY_CACHE_SIZE 10

#define DEFAULT_PATH_IMAGE_CACHE [[COFileUtils defaultImagePathLibrary] stringByAppendingPathComponent: @"Image Cache"]
#define TYPE_OF_FILE @"IMAGE"

@interface COImageCache()<COConnectionManagerDelegate>
{
    NSFileManager * _fileManager;
    BOOL _log;
    BOOL _useMemoryCache;
    pthread_mutex_t componentMutex;
    pthread_mutex_t notification_mutex;
}
@property (atomic, strong) NSFileManager * fileManager;
- (NSString *) getFileFromString:(NSString *) file;
- (NSString *) getPathFileFromString:(NSString *) file;
- (UIImage *) loadImage:(NSString *) imageFile;
@property (nonatomic, weak) COConnectionManager * connectionManager;
@property (nonatomic, strong) COMaxQueue * queue;
- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;
@property (nonatomic, strong) NSMutableArray * cacheImages;
@end

@implementation COImageCache
@synthesize log = _log;
@synthesize fileManager = _fileManager;
@synthesize connectionManager;
@synthesize queue = _queue;
@synthesize numCacheFiles = _numCacheFiles;

GTMOBJECT_SINGLETON_BOILERPLATE(COImageCache, sharedInstance);

-(void)dealloc
{
    pthread_mutex_destroy(&componentMutex);
    pthread_mutex_destroy(&notification_mutex);
}

-(id) init
{
    self = [super init];
    if(self)
    {
        self.connectionManager = [COConnectionManager getInstance];
        self.fileManager = [NSFileManager defaultManager];
        self.log = NO;
        pthread_mutex_init(&componentMutex, NULL);
        pthread_mutex_init(&notification_mutex, NULL);
        self.numCacheFiles = MEMORY_CACHE_SIZE;
        self.queue = [[COMaxQueue alloc] initWithSize: self.numCacheFiles];
        self.cacheImages = [NSMutableArray array];
        [self createFolder];
    }
    return self;
}

- (void)setNumCacheFiles:(NSInteger)numCacheFiles
{
    @synchronized(self)
    {
        _numCacheFiles = numCacheFiles;
        self.queue = [COMaxQueue maxQueueWithQueue: self.queue andSize: _numCacheFiles];
    }
}

- (NSInteger)numCacheFiles
{
    return _numCacheFiles;
}

- (void)createFolder
{
    BOOL isDirectory = NO;
    NSError * error;
    
    if(!([[NSFileManager defaultManager] fileExistsAtPath: DEFAULT_PATH_IMAGE_CACHE isDirectory:&isDirectory] && isDirectory))
    {
        [[NSFileManager defaultManager]  createDirectoryAtPath: DEFAULT_PATH_IMAGE_CACHE withIntermediateDirectories:YES attributes:nil error:&error];
        [COFileUtils addSkipBackupAttributeToFile: DEFAULT_PATH_IMAGE_CACHE];
    }
    if(self.log)
    {
        NSLog(@"Created path %@", DEFAULT_PATH_IMAGE_CACHE);
    }
}

+ (NSString *)imageCacheFolderPath
{
    return DEFAULT_PATH_IMAGE_CACHE;
}


- (NSString *) imagePathWithKey:(NSString *) key
{
    return [self existImageWithKey: key] ? [DEFAULT_PATH_IMAGE_CACHE stringByAppendingPathComponent: [self getFileFromString: key]] : nil;
}

- (void) imageForKey:(NSString *)key withComponent:(NSObject<COAsyncComponent> *) component;
{
    [self imageForKey:key withComponent: component andScalingWithCGRect: CGRectNull];
}

- (void)imageForKey:(NSString *)key withComponent:(NSObject<COAsyncComponent> *)component andScalingWithCGRect:(CGRect)rect
{
    NSMutableString * imageKey = [key mutableCopy];
    if(!CGRectEqualToRect(rect, CGRectNull))
       [imageKey insertString:NSStringFromCGRect(rect) atIndex:imageKey.length -4];
    if([self existImageWithKey: imageKey])
        [component setImage: [self loadImage: imageKey]];
    else if([self existImageWithKey: key])
    {
        UIImage * image = [self loadImage: key];
        [self saveImage: UIImagePNGRepresentation(image) toPath: [self pathToSave: imageKey] andScaling: rect];
        [component setImage: [self loadImage: imageKey]];
    }
    else
    {
        UIImage * image = [UIImage imageWithContentsOfFile: key];
        if(image)
        {
            if (rect.size.width>0){
                image = [self imageWithImage: image scaledToSize: rect.size];
            }
            NSData * data = UIImagePNGRepresentation(image);
            [data writeToFile: [self pathToSave: imageKey] atomically:YES];
            [component setImage: [self loadImage: imageKey]];
        }else
        {
            COConnectionTask * task = [[COConnectionTask alloc] initWithURL: [NSURL URLWithString: key] andPathToSave: [self pathToSave: imageKey]];
            task.scalingRect = rect;
            [task appendDelegate: self];
            task.typeOfFile = TYPE_OF_FILE;
            //pthread_mutex_lock(&componentMutex);
            [[COConnectionManager getInstance] executeDownloadTask: task];
            [component subscribeToNotification: task.notificationString andNotificationError:  task.notificationErrorString];
            //pthread_mutex_unlock(&componentMutex);
        }
    }
}

- (void)imageForKeyWithParameters:(NSString *)key withComponent:(NSObject<COAsyncComponent> *)component
{
    [self imageForKeyWithParameters:key withComponent: component andScalingWithCGRect: CGRectNull];
}


- (void)imageForKeyWithParameters:(NSString *)key withComponent:(NSObject<COAsyncComponent> *)component andScalingWithCGRect:(CGRect)rect
{
    NSMutableString * imageKey = [key mutableCopy];
    if(!CGRectEqualToRect(rect, CGRectNull))
        [imageKey insertString:NSStringFromCGRect(rect) atIndex:imageKey.length -4];
    if([self existImageWithKeyWithParameters: imageKey])
        [component setImage: [self loadImageWithParameters: imageKey]];
    else if([self existImageWithKeyWithParameters: key])
    {
        UIImage * image = [self loadImageWithParameters: key];
        [self saveImage: UIImagePNGRepresentation(image) toPath: [self pathToSaveWithParameters: imageKey] andScaling: rect];
        [component setImage: [self loadImageWithParameters: imageKey]];
    }
    else
    {
        UIImage * image = [UIImage imageWithContentsOfFile: key];
        if(image)
        {
            if (rect.size.width>0){
                image = [self imageWithImage: image scaledToSize: rect.size];
            }
            NSData * data = UIImagePNGRepresentation(image);
            [data writeToFile: [self pathToSaveWithParameters: imageKey] atomically:YES];
            [component setImage: [self loadImageWithParameters: imageKey]];
        }else
        {
            COConnectionTask * task = [[COConnectionTask alloc] initWithURL: [NSURL URLWithString: key] andPathToSave: [self pathToSaveWithParameters: imageKey]];
            task.scalingRect = rect;
            [task appendDelegate: self];
            task.typeOfFile = TYPE_OF_FILE;
            //pthread_mutex_lock(&componentMutex);
            [[COConnectionManager getInstance] executeDownloadTask: task];
            [component subscribeToNotification: task.notificationString andNotificationError:  task.notificationErrorString];
            //pthread_mutex_unlock(&componentMutex);
        }
    }
}

- (void) saveImage:(UIImage *) image withKey:(NSString *)key{
    NSString * fileName = [self pathToSave: key];
    [self saveImage: UIImagePNGRepresentation(image) toPath: fileName andScaling: CGRectNull];
}

- (void) saveImage:(UIImage *) image withKeyWithParameters:(NSString *)key{
    NSString * fileName = [self pathToSaveWithParameters: key];
    [self saveImage: UIImagePNGRepresentation(image) toPath: fileName andScaling: CGRectNull];
}


- (UIImage *)imageForKeySynchronously:(NSString *)key
{
    if([self existImageWithKey: key])
        return [self loadImage: key];
    
    if(self.log)
    {
        NSLog(@"Image %@ not exist, download synchronously", key);
    }
    COConnectionTask * task = [[COConnectionTask alloc] initWithURL: [NSURL URLWithString: key] andPathToSave: [self pathToSave: key]];
    task.typeOfFile = TYPE_OF_FILE;
    NSData * data = [[COConnectionManager getInstance] downloadDataSynchronously: task];
    
    return [UIImage imageWithData: data];
}

- (UIImage *)imageForKeyWithParametersSynchronously:(NSString *)key
{
    if([self existImageWithKeyWithParameters: key])
        return [self loadImageWithParameters: key];
    
    if(self.log)
    {
        NSLog(@"Image %@ not exist, download synchronously", key);
    }
    COConnectionTask * task = [[COConnectionTask alloc] initWithURL: [NSURL URLWithString: key] andPathToSave: [self pathToSaveWithParameters: key]];
    task.typeOfFile = TYPE_OF_FILE;
    NSData * data = [[COConnectionManager getInstance] downloadDataSynchronously: task];
    
    return [UIImage imageWithData: data];
}

- (BOOL)existImageWithKey:(NSString *)key
{
    NSString * path = [self pathToSave: key];
    return [[NSFileManager defaultManager] fileExistsAtPath: path];
}

- (BOOL)existImageWithKeyWithParameters:(NSString *)key
{
    NSString * fileName = [self getPathFileFromString: key];
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath: DEFAULT_PATH_IMAGE_CACHE error: nil];
    for(NSString * file in files)
    {
        if([file caseInsensitiveCompare: fileName] == NSOrderedSame)
            return YES;
    }
    return NO;
}

- (void)removeImageWithKey:(NSString *)key
{
    NSString * fileName = [self getFileFromString: key];
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath: DEFAULT_PATH_IMAGE_CACHE error: nil];
    for(NSString * file in files)
    {
        if([file caseInsensitiveCompare: fileName] == NSOrderedSame)
        {
            NSString * path = [DEFAULT_PATH_IMAGE_CACHE stringByAppendingPathComponent: file];
            NSError * error = nil;
            [self.fileManager removeItemAtPath: path error: &error];
            if(self.log)
            {
                NSLog(@"Removed file %@", path);
            }
        }
    }
}

- (void)removeImageWithKeyWithParameters:(NSString *)key
{
    NSString * fileName = [self getPathFileFromString: key];
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath: DEFAULT_PATH_IMAGE_CACHE error: nil];
    for(NSString * file in files)
    {
        if([file caseInsensitiveCompare: fileName] == NSOrderedSame)
        {
            NSString * path = [DEFAULT_PATH_IMAGE_CACHE stringByAppendingPathComponent: file];
            NSError * error = nil;
            [self.fileManager removeItemAtPath: path error: &error];
            if(self.log)
            {
                NSLog(@"Removed file %@", path);
            }
        }
    }
}

- (void)removeAllImages
{
    NSArray * files = [self.fileManager contentsOfDirectoryAtPath: DEFAULT_PATH_IMAGE_CACHE error: nil];
    for(NSString * file in files)
    {
        NSString * path = [DEFAULT_PATH_IMAGE_CACHE stringByAppendingPathComponent: file];
        NSError * error = nil;
        [self.fileManager removeItemAtPath: path error: &error];
        if(self.log)
        {
            NSLog(@"Removed file %@", path);
        }
    }
}

#pragma mark Private methods
- (NSString *) getFileFromString:(NSString *) file
{
    NSURL * url = [NSURL URLWithString: file];
    if(!url)
        return [COFileUtils getFileNameForString: file];
    else
        return [COFileUtils getFileNameForUrl: url];
}

- (NSString *) getPathFileFromString:(NSString *) file
{
    return [[file md5] stringByAppendingPathExtension:@"png"];
}

- (UIImage *) loadImage:(NSString *) imageFile
{
    NSString * file = [self getFileFromString: imageFile];
    COImageId * imageid = [[COImageId alloc] initWithImage: nil andIdentifier: file];
    COImageId * newImage = (COImageId *) [self.queue getObject: imageid];
    if(newImage)
    {
        return newImage.image;
    }else
    {
        imageid.image = [UIImage imageWithContentsOfFile: [DEFAULT_PATH_IMAGE_CACHE stringByAppendingPathComponent: file]];
        [self.queue push_back: imageid];
        return imageid.image;
    }
}

- (UIImage *) loadImageWithParameters:(NSString *) imageFile
{
    NSString * file = [self getPathFileFromString: imageFile];
    COImageId * imageid = [[COImageId alloc] initWithImage: nil andIdentifier: file];
    COImageId * newImage = (COImageId *) [self.queue getObject: imageid];
    if(newImage)
    {
        return newImage.image;
    }else
    {
        imageid.image = [UIImage imageWithContentsOfFile: [DEFAULT_PATH_IMAGE_CACHE stringByAppendingPathComponent: file]];
        [self.queue push_back: imageid];
        return imageid.image;
    }
}

- (NSString *) pathToSave:(NSString *) imagePath
{
    NSString * fileName = [self getFileFromString: imagePath];
    if([fileName pathExtension] == nil || [[fileName pathExtension] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0)
       fileName = [fileName stringByAppendingPathExtension: @"png"];

    return [DEFAULT_PATH_IMAGE_CACHE stringByAppendingPathComponent: fileName];
}

- (NSString *) pathToSaveWithParameters:(NSString *) imagePath
{
    NSString * fileName = [self getPathFileFromString: imagePath];
    if([fileName pathExtension] == nil || [[fileName pathExtension] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0)
        fileName = [fileName stringByAppendingPathExtension: @"png"];
    
    return [DEFAULT_PATH_IMAGE_CACHE stringByAppendingPathComponent: fileName];
}

- (void) saveImage:(NSData *) dataImage toPath:(NSString *) path andScaling:(CGRect) rect
{
    UIImage * image = [UIImage imageWithData: dataImage];
    if(!CGRectEqualToRect(rect, CGRectNull))
    {
        CGImageRef ref = image.CGImage;
        CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo( ref);
        if(alphaInfo == kCGImageAlphaNone)
            alphaInfo = kCGImageAlphaNoneSkipLast;
        CGRect draw = CGRectNull;
        
        CGFloat widthImage = image.size.width;
        CGFloat heightImage = image.size.height;
        
        CGFloat widthComponent = CGRectGetWidth(rect);
        CGFloat heightComponent = CGRectGetHeight(rect);
        
        if(widthImage <= widthComponent && heightImage <= heightComponent)
            draw = rect;
        else
        {
            CGFloat relation = widthImage / heightImage;
            CGFloat newHeight = 0;
            CGFloat newWidth = 0;
            if(widthImage > heightImage)
            {
                if(widthImage > widthComponent)
                {
                    newWidth = widthComponent;
                    newHeight = widthComponent / relation;
                    
                }else if(heightImage > heightComponent)
                {
                    newHeight = heightComponent;
                    newWidth = heightComponent * relation;
                }
            }else
            {
                if(heightImage > heightComponent)
                {
                    newHeight = heightComponent;
                    newWidth = heightComponent * relation;
                }
                else if(widthImage > widthComponent)
                {
                    newWidth = widthComponent;
                    newHeight = widthComponent / relation;
                } 
            }
            
            rect = CGRectMake(0, 0, newWidth*2, newHeight*2);
            CGRect originalRect = CGRectMake(0, 0, widthImage, heightComponent);
            if(CGRectGetWidth(originalRect) < CGRectGetWidth(rect) || CGRectGetHeight(originalRect) < CGRectGetHeight(originalRect))
                rect = originalRect;
        }
        
        /*[dataImage writeToFile: path atomically: YES];
        [self saveImage2: dataImage toPath: path andScaling: CGRectGetWidth(rect)];
        CGContextRef bitmap = CGBitmapContextCreate(NULL, CGRectGetWidth(rect),
                                                    CGRectGetHeight(rect),
                                                    CGImageGetBitsPerComponent(ref),
                                                    4 * (int) CGRectGetWidth(rect),
                                                    CGImageGetColorSpace(ref),
                                                    //rgbColorSpace,
                                                    alphaInfo);
        CGContextSetInterpolationQuality(bitmap, kCGInterpolationHigh);
        CGContextDrawImage(bitmap, rect, ref);
        CGImageRef newImage = CGBitmapContextCreateImage(bitmap);
        UIImage * result = [UIImage imageWithCGImage: newImage];
        CGContextRelease(bitmap);
        CGImageRelease(newImage);
        dataImage = UIImagePNGRepresentation(result);*/
        UIImage * result = [self imageWithImage: image scaledToSize: rect.size];
        dataImage = UIImagePNGRepresentation(result);
        [dataImage writeToFile: path atomically: YES];
    }else
     [dataImage writeToFile: path atomically: YES];
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    /*
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGImageRef imageRef = image.CGImage;
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);
    
    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);
    
    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(context);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
    
    CGImageRelease(newImageRef);
    UIGraphicsEndImageContext();
    */
    return newImage;
}


- (void) saveImage2:(NSData *) dataImage toPath:(NSString *) path andScaling:(CGFloat) max
{
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:path], NULL);
    if (!imageSource)
        return;
    
    CFDictionaryRef options = (__bridge CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailWithTransform,
                                                (id)kCFBooleanTrue, (id)kCGImageSourceCreateThumbnailFromImageIfAbsent,
                                                (id)[NSNumber numberWithFloat:max], (id)kCGImageSourceThumbnailMaxPixelSize,
                                                nil];
    CGImageRef imgRef = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options);
    
    UIImage* scaled = [UIImage imageWithCGImage:imgRef];
    NSData * data = UIImagePNGRepresentation(scaled);
    [data writeToFile: path atomically: YES];
    
    CGImageRelease(imgRef);
    CFRelease(imageSource);
}
#pragma mark COConnectionManagerDelegate

- (void)connectionManager:(COConnectionManager *)manager didFailedObject:(COConnectionTask *)object withError:(NSError *)error
{
    [[NSNotificationCenter defaultCenter] postNotificationName: object.notificationErrorString object: object];
}

- (void) connectionManager:(COConnectionManager *)manager didFinishDownloadObject:(COConnectionTask *)object withResult:(id)result
{
    if([object.typeOfFile isEqualToString: TYPE_OF_FILE])
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if(!CGRectEqualToRect(object.scalingRect, CGRectNull))
                [self saveImage:result toPath:object.pathToSave andScaling:object.scalingRect];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName: [object notificationString] object: object];
            });
        });
    }
}
@end
