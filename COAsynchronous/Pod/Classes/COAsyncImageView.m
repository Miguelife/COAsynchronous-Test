//
//  COAsyncImageView.m
//  COAsyncImage
//
//  Created by Pablo Viciano Negre on 14/08/12.
//  Copyright (c) 2012 Pablo Viciano Negre. All rights reserved.
//

#import "COAsyncImageView.h"
#import "COImageCache.h"
#import "COAsyncURLUtils.h"
#import "COAsyncConstants.h"
#import <pthread.h>
#import "COConnectionTask.h"

@interface COAsyncImageView ()
{
    UIImage * _defaultImage;
    UIImage * _image;
    UIActivityIndicatorView * _activityIndicatorView;
    UIActivityIndicatorViewStyle _activityIndicatorStyle;
    UIImageView * _imageView;
    BOOL _showActivityIndicator;
    BOOL _alwaysAsTemplate;
    BOOL _renderInGrayscale;

    pthread_mutex_t mutex;
}
@property (nonatomic, strong) UIActivityIndicatorView * activityIndicatorView;
@property (nonatomic, weak) COImageCache * imageCache;
- (void) update:(NSNotification *) notification;
- (void) failedUpdate: (NSNotification *) notification;
- (void) create;
- (void) startActivityIndicator;
- (void) stopActivityIndicator;
@end


@implementation COAsyncImageView

@synthesize defaultImage = _defaultImage;
@synthesize image = _image;
@synthesize activityIndicatorStyle =_activityIndicatorStyle;
@synthesize activityIndicatorView = _activityIndicatorView;
@synthesize imageView = _imageView;
@synthesize showActivityIndicator = _showActivityIndicator;
@synthesize alwaysAsTemplate = _alwaysAsTemplate;
@synthesize renderInGrayscale = _renderInGrayscale;
@synthesize imageCache = _imageCache;
@synthesize delegate = _delegate;

typedef enum {
    ALPHA = 0,
    BLUE = 1,
    GREEN = 2,
    RED = 3
} PIXELS;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    pthread_mutex_destroy(&mutex);
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self create];
    }
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder: aDecoder];
    if(self)
    {
        [self create];
    }
    return self;
}

- (id) init
{
    self = [super init];
    if(self)
    {
        [self create];
    }
    return self;
}

- (UIImageView *)imageView
{
    if(!_imageView)
    {
        _imageView = [[UIImageView alloc] init];
        [self addSubview: _imageView];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary * views = @{ @"selfView": self,
                                  @"imageView": _imageView};
        
        [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView(==selfView)]|" options:0 metrics:nil views:views]];
        [self addConstraints: [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView(==selfView)]|" options:0 metrics:nil views:views]];
        
    }return _imageView;
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode: contentMode];
    self.imageView.contentMode = contentMode;
}

- (void)setAutoresizingMask:(UIViewAutoresizing)autoresizingMask
{
    [super setAutoresizingMask: autoresizingMask];
    self.imageView.autoresizingMask = autoresizingMask;
}

- (void) loadImage:(UIImage *)image
{
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    
    if(self.imageView.image == image)
    {
        return;
    }
    
    if(image == nil || image.size.width == 0 || image.size.height == 0)
        image = self.defaultImage;

    self.imageView.image = image;
    
    if ([_delegate respondsToSelector:@selector(endDownloadingImageAsync:)]){
        [_delegate performSelector: @selector(endDownloadingImageAsync:) withObject: self];
    }
}

- (void)updateConstraintsIfNeeded
{
    [super updateConstraintsIfNeeded];
    if(self.imageView)
        [self.imageView updateConstraintsIfNeeded];
}

- (void)updateConstraints
{
    [super updateConstraints];
    if(self.imageView)
        [self.imageView updateConstraints];
}

- (void)loadImageFromURL:(NSString *)key
{
    key = [key stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    [self loadImageFromURL: key withScaling: NO];
}

- (void)loadImageFromURL:(NSString *)key withScaling:(BOOL)scaling
{
    if(self.defaultImage)
        [self loadDefaultImage];
    
    if(!key || [key isEqualToString:@""])
        return;
    
    key = [key stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    if ([_delegate respondsToSelector:@selector(startDownloadingImageAsync:)]){
        [_delegate performSelector: @selector(startDownloadingImageAsync:) withObject: self];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    if(scaling)
        [self.imageCache imageForKey: key withComponent: self andScalingWithCGRect: self.bounds];
    else
        [self.imageCache imageForKey: key withComponent: self];
}

- (void) loadImageFromNSURL:(NSURL *) key{
   if (key.isFileURL){
        [self loadImage: [UIImage imageWithContentsOfFile: key.path]];
    }
    else{
        [self loadImageFromURL: key.absoluteString];
    }
}

- (void)loadImageFromURLWithParameters:(NSString *)key
{
    [self loadImageFromURLWithParameters: key withScaling: NO];
}

- (void)loadImageFromURLWithParameters:(NSString *)key withScaling:(BOOL)scaling
{
    if(self.defaultImage)
        [self loadDefaultImage];
    
    if(!key || [key isEqualToString:@""])
        return;
    
    if ([_delegate respondsToSelector:@selector(startDownloadingImageAsync:)]){
        [_delegate performSelector: @selector(startDownloadingImageAsync:) withObject: self];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    if(scaling)
        [self.imageCache imageForKeyWithParameters: key withComponent: self andScalingWithCGRect: self.bounds];
    else
        [self.imageCache imageForKeyWithParameters: key withComponent: self];
}

- (void) loadDefaultImage
{
    if(self.imageView.image == self.defaultImage)
        return;
    /*if(self.imageView != nil)
    {
        [self.imageView removeFromSuperview];
    }
    self.imageView = nil;
    if(self.defaultImage == nil || self.defaultImage.size.width == 0 || self.defaultImage.size.height == 0)
        return;
    self.imageView = [[UIImageView alloc] initWithImage: self.defaultImage];
    self.imageView.contentMode = self.contentMode;
    self.imageView.autoresizingMask = self.autoresizingMask;
    self.imageView.frame = self.bounds;
    self.imageView.backgroundColor = [UIColor clearColor];
    [self addSubview: self.imageView];
     */
    self.imageView.image = self.defaultImage;
    [self.imageView performSelectorOnMainThread:@selector(setNeedsLayout) withObject: nil waitUntilDone: NO];
    [self performSelectorOnMainThread:@selector(setNeedsLayout) withObject:nil waitUntilDone: NO];

}

- (void) clearImage
{
    [self.imageView removeFromSuperview];
    self.imageView = nil;
}

#pragma mark Private methods
- (void) create
{
    pthread_mutex_init(&mutex, NULL);
    self.imageCache = [COImageCache sharedInstance];
    self.clipsToBounds = YES;
    self.activityIndicatorStyle = UIActivityIndicatorViewStyleGray;
    self.showActivityIndicator = YES;
}

- (void) startActivityIndicator
{
    if(self.activityIndicatorView == nil)
    {
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: self.activityIndicatorStyle];
        self.activityIndicatorView.hidesWhenStopped = YES;
        //self.activityIndicatorView.frame = CGRectMake(self.bounds.size.width/2 - 10, self.bounds.size.height/2 - 10, 20, 20);
        [self addSubview: self.activityIndicatorView];
        self.activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addConstraint: [NSLayoutConstraint constraintWithItem: self.activityIndicatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem: self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [self addConstraint: [NSLayoutConstraint constraintWithItem: self.activityIndicatorView attribute:NSLayoutAttributeCenterY relatedBy: NSLayoutRelationEqual toItem: self attribute: NSLayoutAttributeCenterY multiplier: 1.0 constant:0]];
        
        [self.activityIndicatorView updateConstraintsIfNeeded];
        [self updateConstraintsIfNeeded];
        
    }else
    {
        if([self.activityIndicatorView superview] == nil)
        {
            [self addSubview: self.activityIndicatorView];
        }
    }
    [self bringSubviewToFront: self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
}

- (void) stopActivityIndicator
{
    [self.activityIndicatorView stopAnimating];
    [self.activityIndicatorView removeFromSuperview];
    self.activityIndicatorView = nil;
}

- (void)update: (NSNotification *) notification
{
    //pthread_mutex_lock(&mutex);
    if(self.showActivityIndicator)
        [self stopActivityIndicator];
    
    if ([_delegate respondsToSelector:@selector(endDownloadingImageAsync:)]){
        [_delegate performSelector: @selector(endDownloadingImageAsync:) withObject: self];
    }

    [self setImage: [self.imageCache imageForKeySynchronously: notification.name]];
    //pthread_mutex_unlock(&mutex);
}

- (void) failedUpdate:(NSNotification *)notification
{
    if(self.showActivityIndicator)
       [self stopActivityIndicator];
    
    if ([_delegate respondsToSelector:@selector(errorDownloadingImageAsync:)]){
        [_delegate performSelector: @selector(errorDownloadingImageAsync:) withObject: self];
    }


    [self loadDefaultImage];
}

#pragma mark COAsyncComponent
- (void)subscribeToNotification:(NSString *)notification andNotificationError:(NSString *)notificationError
{
    //pthread_mutex_lock(&mutex);
    [[NSNotificationCenter defaultCenter] removeObserver: self];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(update:) name: notification object: nil];
    [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(failedUpdate:) name: notificationError object:nil];
    [self loadDefaultImage];
    if(self.showActivityIndicator)
        [self startActivityIndicator];
    //pthread_mutex_unlock(&mutex);
}

- (void) setImage:(UIImage *)image
{
    if(self.showActivityIndicator)
    {
        [self stopActivityIndicator];
    }
    _image = image;

    if (_renderInGrayscale){  //Carga la imagen en escala de grises
        [self loadImage:_image];
        dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // Add code here to do background processing
            UIImage * grayImage = [self convertToGrayScaleImage:_image];
            if (grayImage){
                _image = grayImage;
            }
            dispatch_async( dispatch_get_main_queue(), ^{
                // Add code here to update the UI/send notifications based on the
                // results of the background processing
                [self loadImage:_image];
            });
        });
        return;
    }else if (_alwaysAsTemplate){    //Carga la imagen como template si está activado el flag
        _image = [_image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    [self loadImage: _image];
}

- (void) loadThumbnailImageFromURL:(NSString *)url withWidth:(int) width andHeight:(int) height
{
    NSString *result = [NSString stringWithFormat: @"%@?w=%d&h=%d&ruta=%@&cache=%d",THUMB_IMAGE_BASE,width,height, [COAsyncURLUtils urlEncodedString:url],THUMB_IMAGE_CACHE_ENABLED];
    [self loadImageFromURL: result];
}

- (UIImage*) convertToGrayScaleImage: (UIImage*) image{
    
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    CGSize size = [image size];
    int width = size.width *scale;
    int height = size.height *scale;
    
    // the pixels will be painted to this array
    uint32_t *pixels = (uint32_t *) malloc(width * height * sizeof(uint32_t));
    
    // clear the pixels so any transparency is preserved
    memset(pixels, 0, width * height * sizeof(uint32_t));
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // create a context with RGBA pixels
    CGContextRef context = CGBitmapContextCreate(pixels, width, height, 8, width * sizeof(uint32_t), colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedLast);
    
    // paint the bitmap to our context which will fill in the pixels array
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
    
    for(int y = 0; y < height; y++) {
        for(int x = 0; x < width; x++) {
            uint8_t *rgbaPixel = (uint8_t *) &pixels[y * width + x];
            
            // convert to grayscale using recommended method: http://en.wikipedia.org/wiki/Grayscale#Converting_color_to_grayscale
            uint32_t gray = 0.3 * rgbaPixel[RED] + 0.59 * rgbaPixel[GREEN] + 0.11 * rgbaPixel[BLUE];
            
            // set the pixels to gray
            rgbaPixel[RED] = gray;
            rgbaPixel[GREEN] = gray;
            rgbaPixel[BLUE] = gray;
        }
    }
    
    // create a new CGImageRef from our context with the modified pixels
    CGImageRef newImage = CGBitmapContextCreateImage(context);
    
    // we're done with the context, color space, and pixels
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    free(pixels);
    
    // make a new UIImage to return
    UIImage *resultUIImage = [UIImage imageWithCGImage:newImage scale:scale orientation:UIImageOrientationUp];
    
    // we're done with image now too
    CGImageRelease(newImage);
    
    return resultUIImage;
}
@end
