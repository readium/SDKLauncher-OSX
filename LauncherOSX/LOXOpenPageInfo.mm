//
// Created by Boris Schneiderman on 2013-05-13.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXOpenPageInfo.h"
#import "LOXUtil.h"


@implementation LOXOpenPageInfo {

}

+ (LOXOpenPageInfo *)pageInfoFromDictionary:(NSDictionary *)dictionary {

    LOXOpenPageInfo *pageInfo = [[[LOXOpenPageInfo alloc] init] autorelease];

    pageInfo.idref = [LOXUtil valueForKey:@"idref" orDefault:@"" fromDictionary:dictionary];
    pageInfo.spineItemPageIndex = [[LOXUtil valueForKey:@"spineItemPageIndex" orDefault:[NSNumber numberWithInt:0] fromDictionary:dictionary] integerValue];
    pageInfo.spineItemPageCount = [[LOXUtil valueForKey:@"spineItemPageCount" orDefault:[NSNumber numberWithInt:0] fromDictionary:dictionary] integerValue];
    pageInfo.spineItemIndex = [[LOXUtil valueForKey:@"spineItemIndex" orDefault:[NSNumber numberWithInt:0] fromDictionary:dictionary] integerValue];

    return pageInfo;
}

@end