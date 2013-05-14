//
// Created by Boris Schneiderman on 2013-05-07.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class LOXOpenPageInfo;


NSString *const LOXPageChangedEvent = @"PageChangedEvent";

@interface LOXCurrentPagesInfo : NSObject


@property (nonatomic, readonly) NSArray *openPages;
@property (nonatomic) bool isFixedLayout;
@property (nonatomic) int spineItemCount;


- (void)fromDictionary:(NSDictionary *)dict;

- (bool)canGoNext;

- (bool)canGoPrev;

- (LOXOpenPageInfo *)firstOpenPage;

- (NSArray *)getPageNumbers;

- (bool)isOpen;

- (int)getPageCount;
@end