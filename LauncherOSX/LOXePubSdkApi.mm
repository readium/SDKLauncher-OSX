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
#import "LOXSpineItem.h"

@interface LOXePubSdkApi ()

- (void)releaseContainer;

- (LOXSpineItem *)createSpineItemWith:(const ePub3::SpineItem *)spineItem;

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
    }

    return self;
}

- (void)openFile:(NSString *)file
{
    [self releaseContainer];
    _container = new ePub3::Container([file UTF8String]);
}

- (NSArray *)getSpineItems
{
    NSAssert(_container != nil, @"openFile must be called before using the Api");

    NSMutableArray *loxSpineItems = [[[NSMutableArray alloc] init] autorelease];

    auto packages = _container->Packages();

    for (auto package = packages.begin(); package != packages.end(); ++package) {
        const ePub3::SpineItem *spineItem = (*package)->FirstSpineItem();
        while (spineItem) {
            [loxSpineItems addObject:[self createSpineItemWith:spineItem]];
            spineItem = spineItem->Next();
        }
    }

    return loxSpineItems;
}

- (LOXSpineItem *)createSpineItemWith:(const ePub3::SpineItem *)spineItem
{
    auto str = spineItem->Idref().c_str();

    NSString *idref =  [NSString stringWithUTF8String:str];

    LOXSpineItem *loxSpineItem = [LOXSpineItem spineItemWithIdref:idref];

    [idref release];

    return loxSpineItem;
}

- (void)dealloc
{
    [self releaseContainer];
    [super dealloc];
}

- (void)releaseContainer
{
    if (_container != nil) {
        delete _container;
        _container = nil;
    }
}

@end
