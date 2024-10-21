//
//  COImageCache.h
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 14/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "COAsyncComponent.h"
#define IMAGE_FILE_LIFEIME 864000.0


@interface COImageCache : NSObject

@property (atomic, assign) BOOL log;
@property (atomic, assign) NSInteger numCacheFiles;

+ (COImageCache *) sharedInstance;
+ (NSString *) imageCacheFolderPath;
- (NSString *) imagePathWithKey:(NSString *) key;
- (void)createFolder;
- (void) imageForKey:(NSString *)key withComponent:(NSObject<COAsyncComponent> *) component;
- (void) imageForKey:(NSString *)key withComponent:(NSObject<COAsyncComponent> *)component andScalingWithCGRect:(CGRect) rect;
- (void) imageForKeyWithParameters:(NSString *)key withComponent:(NSObject<COAsyncComponent> *) component;
- (void) imageForKeyWithParameters:(NSString *)key withComponent:(NSObject<COAsyncComponent> *)component andScalingWithCGRect:(CGRect) rect;

- (UIImage *)imageForKeySynchronously:(NSString *)key;
- (UIImage *)imageForKeyWithParametersSynchronously:(NSString *) key;
- (BOOL)existImageWithKey:(NSString *)key;
- (BOOL)existImageWithKeyWithParameters:(NSString *) key;
- (void)removeImageWithKey:(NSString *)key;
- (void)removeImageWithKeyWithParameters:(NSString *)key;
- (void)removeAllImages;
- (NSString *) pathToSave:(NSString *) imagePath;
- (NSString *) pathToSaveWithParameters:(NSString *) imagePath;
- (void) saveImage:(UIImage *) image withKey:(NSString *)key;
- (void) saveImage:(UIImage *) image withKeyWithParameters:(NSString *)key;

@end
