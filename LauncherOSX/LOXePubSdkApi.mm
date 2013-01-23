//
//  LOXePubSdkApi.m
//  LauncherOSX
//
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

#import "LOXePubSdkApi.h"

#include "container.h"
#import "LOXSpineItemSdk.h"

@interface LOXePubSdkApi ()

- (void)releaseContainer;

- (void)readPackages;


@end

@implementation LOXePubSdkApi


+(void)initialize
{
    ePub3::Archive::Initialize();
}

- (id)init
{
    self = [super init];
    if(self){
        
        _apiType = kePubSdkApi;
        _spineItems = [[NSMutableArray array] retain];
    }

    return self;
}

- (void)openFile:(NSString *)file
{
    [self releaseContainer];
    _container = new ePub3::Container([file UTF8String]);

    [self readPackages];
}

- (void)readPackages
{
    [_spineItems removeAllObjects];

    auto packages = _container->Packages();

    for (auto package = packages.begin(); package != packages.end(); ++package) {
        const ePub3::SpineItem *spineItem = (*package)->FirstSpineItem();
        while (spineItem) {
            LOXSpineItemSdk *loxSpineItem = [[[LOXSpineItemSdk alloc] initWithSdkSpineItem:spineItem] autorelease];
            [_spineItems addObject:loxSpineItem];
            spineItem = spineItem->Next();
        }
    }
}

- (NSArray *)getSpineItems
{
    return _spineItems;
}

- (void)dealloc
{
    [self releaseContainer];
    [_spineItems release];
    [super dealloc];
}

- (void)releaseContainer
{
    if (_container != NULL) {
        delete _container;
        _container = NULL;
    }
}


- (NSString*)getPathToSpineItem:(id<LOXSpineItem>) spineItem
{
    LOXSpineItemSdk *spineItemSdk = (LOXSpineItemSdk *)spineItem;

    const ePub3::ManifestItem *manifestItem = [spineItemSdk sdkSpineItem]->ManifestItem();
    auto reader = manifestItem->Reader();

//    reader->read(<#(void *)p#>, <#(size_t)len#>)

//  Reader  reader->read(<#(void *)p#>, <#(size_t)len#>)

    return @"";
}

@end
