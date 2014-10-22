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


@interface LOXCurrentPagesInfo ()
- (void)reset;
@end

@implementation LOXCurrentPagesInfo {

    NSMutableArray* _openPages;
    BOOL _canGoLeft;
    BOOL _canGoRight;
    BOOL _isRightToLeft;
}

@synthesize openPages = _openPages;
@synthesize canGoLeft = _canGoLeft;
@synthesize canGoRight = _canGoRight;
@synthesize isRightToLeft = _isRightToLeft;

-(id)init
{
    if ((self = [super init])) {
        _openPages = [[NSMutableArray alloc] init];
    }

    return self;
}

-(void)fromDictionary:(NSDictionary *)dict canGoLeft:(BOOL)canGoLeft canGoRight:(BOOL)canGoRight
{

    [self reset];

    _canGoLeft = canGoLeft;
    _canGoRight = canGoRight;

    self.isFixedLayout = [[LOXUtil valueForKey:@"isFixedLayout" orDefault:[NSNumber numberWithBool:NO] fromDictionary:dict] boolValue];
    self.spineItemCount = [[LOXUtil valueForKey:@"spineItemCount" orDefault:[NSNumber numberWithInt:0] fromDictionary:dict] integerValue];

    _isRightToLeft = ([[dict valueForKey:@"isRightToLeft"] isEqual:[NSNumber numberWithBool:YES]] ? YES : NO);

    NSArray *arr = (NSArray*)[LOXUtil valueForKey:@"openPages" orDefault:nil fromDictionary:dict];

    if(arr) {

        for(NSDictionary *pageDict in arr) {
            LOXOpenPageInfo *pageInfo = [LOXOpenPageInfo pageInfoFromDictionary:pageDict];
            [_openPages addObject:pageInfo];
        }

    }

}




-(void)reset
{
    self.isFixedLayout = false;
    self.spineItemCount = 0;

    _canGoLeft = NO;
    _canGoRight = NO;
    [_openPages removeAllObjects];
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