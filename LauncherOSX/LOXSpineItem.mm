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

#include "manifest.h"
#import "spine.h"
#import "LOXSpineItem.h"


@implementation LOXSpineItem

@synthesize idref = _idref;
@synthesize packageStorageId = _packageStorrageId;
@synthesize href = _href;
@synthesize spread = _spread;

- (const ePub3::SpineItem *)sdkSpineItem
{
    return _sdkSpineItem;
}

- (id)initWithStorageId:(NSString *)storageId forSdkSpineItem:(const ePub3::SpineItem *)sdkSpineItem
{
    self = [super init];
    if(self) {
        auto str = sdkSpineItem->Idref().c_str();

        auto manifestItem = sdkSpineItem->ManifestItem();
        _href = [NSString stringWithUTF8String:manifestItem->BaseHref().c_str()];
        [_href retain];
        _packageStorrageId = storageId;
        [_packageStorrageId retain];
        _idref = [[NSString stringWithUTF8String:str] retain];
        _sdkSpineItem = sdkSpineItem;

        if(sdkSpineItem->Spread() == ePub3::SpineItem::PageSpread::Left) {
            _spread = @"Left";
        }
        else if(sdkSpineItem->Spread() == ePub3::SpineItem::PageSpread::Right) {
            _spread = @"Right";
        }
        else{
            _spread = @"";
        }

    }

    return self;

}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];

    [dict setObject:_href forKey:@"href"];
    [dict setObject:_idref forKey:@"idref"];
    [dict setObject:_spread forKey:@"spread"];

    return dict;
}


- (void)dealloc
{
    [_packageStorrageId release];
    [_idref release];
    [_href release];
    [super dealloc];
}

@end