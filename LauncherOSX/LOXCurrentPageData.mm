//
// Created by Boris Schneiderman on 2013-05-07.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXCurrentPageData.h"


FOUNDATION_EXPORT NSString *const LOXPageChangedEvent;

@implementation LOXCurrentPageData {

}

@synthesize pageIndex = _pageIndex;
@synthesize pageCount = _pageCount;
@synthesize idref = _idref;


-(void) setCurrentPage:(int)index pageCount:(int)count spineIdRef:(NSString*)idref
{
    _pageIndex = index;
    _pageCount = count;

    [_idref release];
    _idref = idref;
    [_idref retain];

    [[NSNotificationCenter defaultCenter] postNotificationName:LOXPageChangedEvent object:self];
}

- (void)dealloc {
    [_idref release];
    [super dealloc];
}

@end