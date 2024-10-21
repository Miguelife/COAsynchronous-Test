//
//  UrlUtils.m
//  Nomepierdoniuna
//
//  Created by UJI on 04/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "COAsyncURLUtils.h"


static NSString *toString(id object) {
	return [NSString stringWithFormat: @"%@", object];
}

// helper function: get the url encoded string form of any object
static NSString *urlEncode(id object) {
	NSString *string = toString(object);
	return [string stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
}

@implementation COAsyncURLUtils

+ (NSString *)urlEncodedString: (NSString *) string{
	//return [toString(string) stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
	return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)string, NULL, CFSTR(":/?#[]@!$&’()*+,;="), kCFStringEncodingUTF8));
}

+ (NSString *)urlDecodedString: (NSString *) string {
	return [toString(string) stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}



+ (NSString*) urlQueryWithDictionary: (NSDictionary *) dict {
	NSMutableArray *parts = [NSMutableArray array];
	for (id key in dict) {
		id value = [dict objectForKey: key];
		NSString *part = [NSString stringWithFormat: @"%@=%@", [COAsyncURLUtils urlEncodedString:key], [COAsyncURLUtils urlEncodedString:value]];
		[parts addObject: part];
	}
	return [parts componentsJoinedByString: @"&"];
}
																													
@end
