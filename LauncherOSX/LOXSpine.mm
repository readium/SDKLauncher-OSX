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


#import "LOXSpine.h"
#import "LOXSpineItem.h"


@implementation LOXSpine {

    NSMutableArray* _items;

}

@synthesize direction = _direction;
@synthesize items = _items;

- (id)initWithDirection:(NSString*)direction
{
    if ((self = [super init])) {
        _items = [[NSMutableArray alloc] init];
        _direction = direction;
    }

    return self;
}

- (void)addItem:(LOXSpineItem *)spineItem
{
    [_items addObject:spineItem];
}

- (void)clear
{
    [_items removeAllObjects];
}

-(NSInteger)itemCount
{
    return [_items count];
}


-(NSDictionary *) toDictionary
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];

    NSMutableArray * itemDicts = [NSMutableArray array];

    for(LOXSpineItem * item in _items) {
        [itemDicts addObject:[item toDictionary]];
    }

    [dict setObject:_direction forKey:@"direction"];
    [dict setObject:itemDicts forKey:@"items"];

    return dict;
}

- (LOXSpineItem *)getSpineItemWithId:(NSString *)idref {

    for(LOXSpineItem *item in _items) {
        if([item.idref isEqualToString:idref]) {
            return item;
        }
    }

    return nil;
}


@end