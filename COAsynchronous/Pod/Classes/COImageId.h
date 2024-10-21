//
//  COImageId.h
//  hotelesconencanto
//
//  Created by Pablo Viciano Negre on 11/10/12.
//  Copyright (c) 2012 Cuatroochenta. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface COImageId : NSObject
@property (nonatomic, strong) UIImage * image;
@property (nonatomic, strong) NSString * identifier;

- (id) initWithImage:(UIImage *) image andIdentifier:(NSString *) identifier;
@end
