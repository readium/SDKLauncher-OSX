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
#include "package.h"

#import "LOXSpineItemSdk.h"
#import "LOXTemporaryFileStorage.h"

@interface LOXePubSdkApi ()

- (void)cleanup;

- (void)saveContentOfReader:(ePub3::ArchiveReader const *)reader toPath:(NSString *)path;

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
    [self cleanup];

     _container = new ePub3::Container([file UTF8String]);

    [self readPackages];
}

- (void)readPackages
{
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
    [self cleanup];

    [_tmpStorage release];
    [_spineItems release];
    [super dealloc];
}

- (void)cleanup
{
    [_spineItems removeAllObjects];

    if (_container != NULL) {
        delete _container;
        _container = NULL;
    }
}


- (NSString*)getPathToSpineItem:(id<LOXSpineItem>) spineItem
{
    LOXSpineItemSdk *spineItemSdk = (LOXSpineItemSdk *)spineItem;

    auto manifestItem = [spineItemSdk sdkSpineItem]->ManifestItem();
    _package = manifestItem->Package();

    [_tmpStorage release];

    NSString *packageBasePath = [NSString stringWithUTF8String:_package->BasePath().c_str()];
    _tmpStorage = [[LOXTemporaryFileStorage alloc] initWithBasePath:packageBasePath];


    NSString *href = [NSString stringWithUTF8String:manifestItem->BaseHref().c_str()];

    NSString *fullPath = [_tmpStorage absolutePathForFile:href];

    return fullPath;
}

-(void)prepareResourceWithPath:(NSString *)path
{
    if (![_tmpStorage isLocalResourcePath:path]) {
        return;
    }

    if([_tmpStorage isResoursFoundAtPath:path]) {
        return;
    }

    NSString * relativePath = [_tmpStorage relativePathFromFullPath:path];

    std::string str([relativePath UTF8String]);
    auto reader = _package->ReaderForRelativePath(str);

    if(reader == NULL){
        NSLog(@"No archive found for path %@", relativePath);
        return;
    }

    [self saveContentOfReader:reader toPath: path];
}

- (void)saveContentOfReader:(const ePub3::ArchiveReader *)reader toPath:(NSString *)path
{
    char buffer[1024];

    NSMutableData * data = [NSMutableData data];

    ssize_t readBytes = reader->read(buffer, 1024);

    while (readBytes > 0) {
        [data appendBytes:buffer length:(NSUInteger) readBytes];
        readBytes = reader->read(buffer, 1024);
    }

    [_tmpStorage saveData:data  toPaht:path];
}

@end
