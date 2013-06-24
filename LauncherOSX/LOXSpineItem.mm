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

#import <ePub3/manifest.h>
#import <ePub3/spine.h>
#import "LOXSpineItem.h"
#import "LOXPackage.h"


@implementation LOXSpineItem

@synthesize idref = _idref;
@synthesize packageStorageId = _packageStorrageId;
@synthesize href = _href;
@synthesize page_spread = _page_spread;
@synthesize rendition_layout = _rendition_layout;

- (ePub3::SpineItemPtr)sdkSpineItem
{
    return _sdkSpineItem;
}

- (id)initWithStorageId:(NSString *)storageId forSdkSpineItem:(ePub3::SpineItemPtr)sdkSpineItem fromPackage:(LOXPackage*)package
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

        if(sdkSpineItem->Spread() == ePub3::PageSpread::Left) {
            _page_spread = @"page-spread-left";
        }
        else if(sdkSpineItem->Spread() == ePub3::PageSpread::Right) {
            _page_spread = @"page-spread-right";
        }
        else{
            _page_spread = @"";
        }
        [_page_spread retain];

        _rendition_layout = [package getProperty:"layout" withPrefix:"rendition" forObject:_sdkSpineItem.get()];
        [_rendition_layout retain];
    }

    return self;

}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];

    [dict setObject:_href forKey:@"href"];
    [dict setObject:_idref forKey:@"idref"];
    [dict setObject:_page_spread forKey:@"page_spread"];
    [dict setObject:_rendition_layout forKey:@"rendition_layout"];

    return dict;
}


- (void)dealloc
{
    [_packageStorrageId release];
    [_idref release];
    [_href release];
    [_page_spread release];
    [_rendition_layout release];
    [super dealloc];
}

@end