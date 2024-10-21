//
//  COAsyncImageView.h
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 14/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "COAsyncComponent.h"


@protocol COAsyncImageViewDelegate;

@interface COAsyncImageView : UIView<COAsyncComponent>

@property (nonatomic, strong) UIImage * defaultImage;
@property (nonatomic, strong) UIImage * image;
@property (nonatomic, assign) UIActivityIndicatorViewStyle activityIndicatorStyle;
@property (nonatomic, strong) UIImageView * imageView;
@property (nonatomic, assign) BOOL showActivityIndicator;
@property (nonatomic, assign) BOOL alwaysAsTemplate;
@property (nonatomic, assign) BOOL renderInGrayscale;


@property (nonatomic, weak) NSObject<COAsyncImageViewDelegate> * delegate;

- (void) loadImageFromURL:(NSString *) key;
- (void) loadImageFromURLWithParameters:(NSString *) key;
- (void) loadImage:(UIImage *) image;


- (void) loadImageFromURL:(NSString *)key withScaling:(BOOL) scaling;
- (void) loadImageFromURLWithParameters:(NSString *)key withScaling:(BOOL) scaling;
- (void) loadImageFromNSURL:(NSURL *) key;

- (void) loadDefaultImage;
- (void) clearImage;
- (void) loadThumbnailImageFromURL:(NSString *)url withWidth:(int) width andHeight:(int) height;
- (UIImage*) convertToGrayScaleImage: (UIImage*) image;
@end


@protocol COAsyncImageViewDelegate

@optional;
- (void) startDownloadingImageAsync: (id) sender;
- (void) endDownloadingImageAsync: (id) sender;
- (void) errorDownloadingImageAsync: (id) sender;

@end
