//
//  LOXePubSdkApi.h
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




@class LOXTemporaryFileStorage;
@class LOXToc;
@class LOXSpineItem;

namespace ePub3 {
    class Container;
    class Package;
}

@interface LOXePubSdkApi : NSObject {

@private
    ePub3::Container *_container;
    const ePub3::Package *_package;

    NSMutableArray *_spineItems;
    NSMutableArray *_packageStorages;
}

@property(nonatomic, retain) NSMutableArray *packageStorages;


+(void)initialize;

- (void)prepareResourceWithPath:(NSString *)path;

- (void)openFile:(NSString *)file;

- (NSArray *)getSpineItems;

- (NSString*)getPathToSpineItem:(LOXSpineItem *) spineItem;

- (NSString *)getPackageID;


- (NSString *)getPackageTitle;

- (NSString *)getCfiForSpineItem:(LOXSpineItem *)spineItem;

- (LOXSpineItem *)findSpineItemWithBasePath:(NSString *)string;

- (LOXSpineItem *)findSpineItemWithIdref:(NSString *)idref;

- (LOXToc*)getToc;


@end
