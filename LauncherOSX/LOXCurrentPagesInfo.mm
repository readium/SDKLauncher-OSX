//  Created by Boris Schneiderman.
//
//  Copyright (c) 2014 Readium Foundation and/or its licensees. All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice, this 
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  3. Neither the name of the organization nor the names of its contributors may be 
//  used to endorse or promote products derived from this software without specific 
//  prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
//  OF THE POSSIBILITY OF SUCH DAMAGE.

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