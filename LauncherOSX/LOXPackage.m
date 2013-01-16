//
//  LOXPackage.m
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



#import "LOXPackage.h"
#import "LOXManifestItem.h"
#import "LOXSpineItem.h"

@interface LOXPackage ()


@end

@implementation LOXPackage

- (id)init
{
    self = [super init];
    if (self) {
        _spine = [[NSMutableArray alloc] init];
        _manifestDictionary = [[NSMutableDictionary alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [_spine release];
    [_manifestDictionary release];
    [super dealloc];
}

- (void)addManifestItem:(LOXManifestItem *)manifestItem
{
    NSAssert(![_manifestDictionary objectForKey:manifestItem.id], @"Manifest Item should have unique id");
    [_manifestDictionary setObject:manifestItem forKey:manifestItem.id];
}

- (NSArray *)spine
{
    return _spine;
}

- (NSString *)getHrefForItem:(LOXSpineItem *)spineItem
{
    LOXManifestItem * manifestItem = [_manifestDictionary objectForKey:spineItem.idref];

    if(!manifestItem) {
        @throw [NSException exceptionWithName:@"EPUB Format" reason:[NSString stringWithFormat:@"id %@ not found in Manifest", spineItem.idref] userInfo:nil];
    }

    return manifestItem.href;
}


- (NSString *)getItemPathForIdref:(NSString *)idRef
{
    LOXManifestItem *item = [_manifestDictionary objectForKey:idRef];

    if (item) {
        return item.href;
    }

    NSException *myException = [NSException exceptionWithName:@"ePub Parse Ecxeption"
                                                       reason:[NSString stringWithFormat:@"Spine item %@ was not found", idRef]
                                                     userInfo:nil];
    @throw myException;
}

- (void)addSpineItem:(LOXSpineItem *)spineItem
{
    [_spine addObject:spineItem];
}


@end
