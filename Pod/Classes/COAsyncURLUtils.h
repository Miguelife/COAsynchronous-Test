//
//  UrlUtils.h
//  Nomepierdoniuna
//
//  Created by UJI on 04/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface COAsyncURLUtils : NSObject {

}

+ (NSString *) urlEncodedString: (NSString *) string;
+ (NSString *) urlDecodedString: (NSString *) string;
+ (NSString *) urlQueryWithDictionary: (NSDictionary *) dict;

	
@end
