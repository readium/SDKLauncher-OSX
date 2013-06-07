//  Created by Boris Schneiderman.
//  Copyright (c) 2012-2013 The Readium Foundation.
//
//  The Readium SDK is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.


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
    self.pageProgressionDirection = [LOXUtil valueForKey:@"pageProgressionDirection" orDefault:@"default" fromDictionary:dict];

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

-(bool)canGoLeft
{
    return [self.pageProgressionDirection isEqualToString:@"rtl"] ? [self canGoNext] : [self canGoPrev];
}

-(bool)canGoRight
{
    return [self.pageProgressionDirection isEqualToString:@"rtl"] ? [self canGoPrev] : [self canGoNext];
}

-(bool)canGoPrev
{
    if(_openPages.count == 0) {
        return NO;
    }

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