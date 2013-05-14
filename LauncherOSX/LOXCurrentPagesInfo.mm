//
// Created by Boris Schneiderman on 2013-05-07.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXCurrentPagesInfo.h"
#import "LOXOpenPageInfo.h"
#import "LOXUtil.h"


FOUNDATION_EXPORT NSString *const LOXPageChangedEvent;

@interface LOXCurrentPagesInfo ()
- (void)reset;
@end

@implementation LOXCurrentPagesInfo {

    NSMutableArray* _openPages;
}

@synthesize openPages = _openPages;

-(id)init
{
    if ((self = [super init])) {
        _openPages = [[NSMutableArray alloc] init];
    }

    return self;
}

-(void)fromDictionary:(NSDictionary *)dict
{

    [self reset];

    self.isFixedLayout = [[LOXUtil valueForKey:@"isFixedLayout" orDefault:[NSNumber numberWithBool:NO] fromDictionary:dict] boolValue];
    self.spineItemCount = [[LOXUtil valueForKey:@"spineItemCount" orDefault:[NSNumber numberWithInt:0] fromDictionary:dict] integerValue];

    NSArray *arr = (NSArray*)[LOXUtil valueForKey:@"openPages" orDefault:nil fromDictionary:dict];

    if(arr) {

        for(NSDictionary *pageDict in arr) {
            LOXOpenPageInfo *pageInfo = [LOXOpenPageInfo pageInfoFromDictionary:pageDict];
            [_openPages addObject:pageInfo];
        }

    }


    [[NSNotificationCenter defaultCenter] postNotificationName:LOXPageChangedEvent object:self];
}




-(void)reset
{
    self.isFixedLayout = false;
    self.spineItemCount = 0;

    [_openPages removeAllObjects];
}

- (void)dealloc
{

    [_openPages release];
    [super dealloc];
}

-(bool)canGoNext
{
    if(_openPages.count == 0) {
        return NO;
    }

    LOXOpenPageInfo *lastOpenPage = [_openPages lastObject];
    return lastOpenPage.spineItemIndex < _spineItemCount - 1 || lastOpenPage.spineItemPageIndex < lastOpenPage.spineItemPageCount - 1;
}


-(bool)canGoPrev
{
    LOXOpenPageInfo *firstOpenPage = [_openPages objectAtIndex:0];
    return firstOpenPage.spineItemIndex > 0 || firstOpenPage.spineItemPageIndex > 0;
}

-(LOXOpenPageInfo *) firstOpenPage
{
    if(_openPages.count == 0) {
        return nil;
    }

    return _openPages[0];
}

-(NSArray *)getPageNumbers
{
    NSMutableArray *arr = [NSMutableArray array];

    for(LOXOpenPageInfo *pageInfo in _openPages) {

        int pageIndex = self.isFixedLayout ? pageInfo.spineItemIndex : pageInfo.spineItemPageIndex;

        [arr addObject: [NSNumber numberWithInt:pageIndex + 1]];
    }

    return arr;
}

-(bool)isOpen
{
    return _openPages.count > 0;
}

-(int)getPageCount
{
    if(![self isOpen]) {
        return 0;
    }

    return _isFixedLayout ? _spineItemCount : [self firstOpenPage].spineItemPageCount;
}

@end