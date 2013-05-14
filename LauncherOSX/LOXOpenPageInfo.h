//
// Created by Boris Schneiderman on 2013-05-13.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


//{pageIndex: pageIndex, spineItemIndex: spineItemIndex, idref: idref, spineItemPageCount: spineItemPageCount }


@interface LOXOpenPageInfo : NSObject


@property (nonatomic, retain) NSString* idref;
@property (nonatomic) int spineItemPageIndex;
@property (nonatomic) int spineItemPageCount;
@property (nonatomic) int spineItemIndex;


+ (LOXOpenPageInfo *)pageInfoFromDictionary:(NSDictionary *)dictionary;
@end