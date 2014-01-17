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


@interface LOXSpineItem ()
- (NSString *)findProperty:(NSString *)propName withPrefix:(NSString *)prefix;
@end

@implementation LOXSpineItem

@synthesize idref = _idref;
//@synthesize packageStorageId = _packageStorageId;
@synthesize href = _href;
@synthesize page_spread = _page_spread;
@synthesize rendition_layout = _rendition_layout;
@synthesize rendition_flow = _rendition_flow;
@synthesize rendition_spread = _rendition_spread;
@synthesize media_overlay_id = _media_overlay_id;


- (ePub3::SpineItemPtr)sdkSpineItem
{
    return _sdkSpineItem;
}

//- (id)initWithStorageId:(NSString *)storageId forSdkSpineItem:(ePub3::SpineItemPtr)sdkSpineItem fromPackage:(LOXPackage*)package
- (id)initWithSdkSpineItem:(ePub3::SpineItemPtr)sdkSpineItem fromPackage:(LOXPackage*)package
{
    self = [super init];
    if(self) {
        auto str = sdkSpineItem->Idref().c_str();

        auto manifestItem = sdkSpineItem->ManifestItem();
        _href = [NSString stringWithUTF8String:manifestItem->BaseHref().c_str()];
        [_href retain];
        //_packageStorrageId = storageId;
        //[_packageStorrageId retain];
        _idref = [[NSString stringWithUTF8String:str] retain];
        _sdkSpineItem = sdkSpineItem;

        _page_spread = [self findProperty:@"page-spread-left" withPrefix:@"rendition"];
        if([_page_spread length] == 0) {
            _page_spread = [self findProperty:@"page-spread-right" withPrefix:@"rendition"];
            if([_page_spread length] == 0) {
                _page_spread = [self findProperty:@"page-spread-center" withPrefix:@"rendition"];
            }
        }
        [_page_spread retain];

        _rendition_spread = [self findProperty:@"spread" withPrefix:@"rendition"];
        [_rendition_spread retain];

        _rendition_layout = [self findProperty:@"layout" withPrefix:@"rendition"];
        [_rendition_layout retain];

        _rendition_flow = [self findProperty:@"flow" withPrefix:@"rendition"];
        [_rendition_flow retain];

        auto mediaOverlayID = sdkSpineItem->ManifestItem()->MediaOverlayID();
        _media_overlay_id = [[NSString alloc] initWithUTF8String: mediaOverlayID.c_str()];
    }

    return self;

}

- (NSString *) findProperty:(NSString *)propName withPrefix:(NSString *)prefix
{
    auto prop = _sdkSpineItem->PropertyMatching([propName UTF8String], [prefix UTF8String]);
    if(prop != nullptr) {
        return [NSString stringWithUTF8String: prop->Value().c_str()];
    }

    return @"";
}

- (NSDictionary *)toDictionary
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];

    [dict setObject:_href forKey:@"href"];
    [dict setObject:_idref forKey:@"idref"];
    [dict setObject:_page_spread forKey:@"page_spread"];
    [dict setObject:_rendition_layout forKey:@"rendition_layout"];
    [dict setObject:_rendition_spread forKey:@"rendition_spread"];
    [dict setObject:_rendition_flow forKey:@"rendition_flow"];
    [dict setObject:_media_overlay_id forKey:@"media_overlay_id"];

    return dict;
}

- (void)dealloc
{
    //[_packageStorageId release];
    [_idref release];
    [_href release];
    [_page_spread release];
    [_rendition_layout release];
    [_rendition_spread release];
    [_media_overlay_id release];
    [_rendition_flow release];
    [super dealloc];
}

@end