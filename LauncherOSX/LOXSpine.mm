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
//


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

- (void)dealloc {
    [_items release];
    [super dealloc];
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