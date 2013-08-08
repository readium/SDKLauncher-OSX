//
// Created by Boris Schneiderman on 2013-08-01.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface LOXCSSStyle : NSObject


- (id)initWithSelector:(NSString *)selector declarationsBlock:(NSString *)declarations;

@property (nonatomic, retain) NSString* selector;
@property (nonatomic, copy) NSString* declarationsBlock;

@end