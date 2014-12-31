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

#import <ePub3/manifest.h>
#import <ePub3/spine.h>
#import "LOXSpineItem.h"
#import "LOXPackage.h"


@interface LOXSpineItem ()
{}
- (NSString *)findProperty:(NSString *)propName withOptionalPrefix:(NSString *)prefix;
- (NSString *)findProperty:(NSString *)propName withPrefix:(NSString *)prefix;
@end

@implementation LOXSpineItem

@synthesize idref = _idref;
//@synthesize packageStorageId = _packageStorageId;
@synthesize href = _href;
@synthesize linear = _linear;
@synthesize page_spread = _page_spread;
@synthesize rendition_layout = _rendition_layout;
@synthesize rendition_flow = _rendition_flow;
@synthesize rendition_orientation = _rendition_orientation;
@synthesize rendition_spread = _rendition_spread;
@synthesize media_type = _media_type;
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

        bool l = sdkSpineItem->Linear();
        _linear = l ? @"yes" : @"no";

        auto manifestItem = sdkSpineItem->ManifestItem();
        _href = [NSString stringWithUTF8String:manifestItem->BaseHref().c_str()];
       
        _media_type = [NSString stringWithUTF8String:manifestItem->MediaType().c_str()];
        
        _media_overlay_id = [[NSString alloc] initWithUTF8String: manifestItem->MediaOverlayID().c_str()];
        
        _idref = [NSString stringWithUTF8String:str];
        _sdkSpineItem = sdkSpineItem;

        _page_spread = [self findProperty:@"page-spread" withOptionalPrefix:@"rendition"];
 
        _rendition_spread = [self findProperty:@"spread" withPrefix:@"rendition"];

        _rendition_orientation = [self findProperty:@"orientation" withPrefix:@"rendition"];

        _rendition_layout = [self findProperty:@"layout" withPrefix:@"rendition"];

        _rendition_flow = [self findProperty:@"flow" withPrefix:@"rendition"];
        
    }

    return self;

}

- (NSString *) findProperty:(NSString *)propName withOptionalPrefix:(NSString *)prefix
{
    NSString* value = [self findProperty:propName withPrefix:prefix];

    if([value length] == 0) {
        value = [self findProperty:propName withPrefix:@""];
    }

    return value;

}

- (NSString *) findProperty:(NSString *)propName withPrefix:(NSString *)prefix
{
    auto prop = _sdkSpineItem->PropertyMatching([propName UTF8String], [prefix UTF8String], false);
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
    [dict setObject:_linear forKey:@"linear"];
    [dict setObject:_page_spread forKey:@"page_spread"];
    [dict setObject:_rendition_layout forKey:@"rendition_layout"];
    [dict setObject:_rendition_orientation forKey:@"rendition_orientation"];
    [dict setObject:_rendition_spread forKey:@"rendition_spread"];
    [dict setObject:_rendition_flow forKey:@"rendition_flow"];
    [dict setObject:_media_overlay_id forKey:@"media_overlay_id"];
    [dict setObject:_media_type forKey:@"media_type"];

    return dict;
}


@end
