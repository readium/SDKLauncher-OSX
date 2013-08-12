//
// Created by Boris Schneiderman on 2013-08-06.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface LOXCSSParser : NSObject

+ (NSArray *)parseCSS:(NSString *)cssContent;

+ (NSDictionary *)parseDeclarationsString:(NSString *)block error:(NSError**)error;
@end