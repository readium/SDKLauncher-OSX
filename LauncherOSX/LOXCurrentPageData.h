//
// Created by Boris Schneiderman on 2013-05-07.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


NSString *const LOXPageChangedEvent = @"PageChangedEvent";

@interface LOXCurrentPageData : NSObject

@property (nonatomic, readonly) int pageIndex;
@property (nonatomic, readonly) int pageCount;
@property (nonatomic, readonly) NSString* idref;


- (void)setCurrentPage:(int)index pageCount:(int)count spineIdRef:(NSString *)idref;


@end