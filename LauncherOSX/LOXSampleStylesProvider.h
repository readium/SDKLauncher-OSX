//
// Created by Boris Schneiderman on 2013-07-31.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class LOXCSSStyle;


@interface LOXSampleStylesProvider : NSObject

-(id)init;


- (NSArray *)styles;

- (LOXCSSStyle *)styleForIndex:(int)index;
@end