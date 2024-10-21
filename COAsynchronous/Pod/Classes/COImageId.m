//
//  COImageId.m
//  hotelesconencanto
//
//  Created by Pablo Viciano Negre on 11/10/12.
//  Copyright (c) 2012 Cuatroochenta. All rights reserved.
//

#import "COImageId.h"

@implementation COImageId
@synthesize image = _image;
@synthesize identifier = _identifier;

- (BOOL)isEqual:(COImageId *)object
{
    return [self.identifier isEqualToString: object.identifier];
}

- (id) initWithImage:(UIImage *) image andIdentifier:(NSString *) identifier
{
    self = [super init];
    if(self)
    {
        self.image = image;
        self.identifier = identifier;
    }
    return self;
}

- (id) init
{
    return [self initWithImage: nil andIdentifier: nil];
}
@end
