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
#import "LOXUtil.h"

@interface LOXePubSdkApi ()

- (void)cleanup;

- (LOXTemporaryFileStorage *)findStorageWithId:(NSString *)storageId;

- (void)saveContentOfReader:(ePub3::ArchiveReader const *)reader toPath:(NSString *)path inStorrage:(LOXTemporaryFileStorage *)storage;


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
        _packageStorages = [[NSMutableArray array] retain];
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

        LOXTemporaryFileStorage *storage = [self createStorageForPackage: *package];
        [_packageStorages addObject:storage];

        const ePub3::SpineItem *spineItem = (*package)->FirstSpineItem();
        while (spineItem) {
            LOXSpineItemSdk *loxSpineItem = [[[LOXSpineItemSdk alloc] initWithStorageId:storage.uuid forSdkSpineItem:spineItem] autorelease];
            [_spineItems addObject:loxSpineItem];
            spineItem = spineItem->Next();
        }
    }
}

- (LOXTemporaryFileStorage *)createStorageForPackage:(const ePub3::Package*)package
{
    NSString *packageBasePath = [NSString stringWithUTF8String:package->BasePath().c_str()];
    return [[[LOXTemporaryFileStorage alloc] initWithUUID:[LOXUtil uuid] forBasePath:packageBasePath] autorelease];
}

- (NSArray *)getSpineItems
{
    return _spineItems;
}

- (void)dealloc
{
    [self cleanup];

    [_spineItems release];
    [_packageStorages release];
    [super dealloc];
}

- (void)cleanup
{
    [_packageStorages removeAllObjects];
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

    LOXTemporaryFileStorage *storage = [self findStorageWithId:spineItemSdk.packageStorageId];


    NSString *href = [NSString stringWithUTF8String:manifestItem->BaseHref().c_str()];


    if (!storage) {
        NSLog(@"Package storrage with id %@ not found", spineItemSdk.packageStorageId);
        return href;
    }

    NSString *fullPath = [storage absolutePathForFile:href];

    return fullPath;
}

-(LOXTemporaryFileStorage *)findStorageWithId:(NSString *)storageId
{
    for(LOXTemporaryFileStorage * storage in _packageStorages)   {
        if([storage.uuid isEqualToString:storageId]) {
            return storage;
        }
    } 
    
    return nil;
}

-(LOXTemporaryFileStorage *)findStorrageForPath:(NSString *) path
{
    for(LOXTemporaryFileStorage * storage in _packageStorages)   {
        if([path rangeOfString:storage.uuid].location != NSNotFound ) {
            return storage;
        }
    }

    return nil;
}

-(void)prepareResourceWithPath:(NSString *)path
{
    LOXTemporaryFileStorage *storage = [self findStorrageForPath:path];

    if(!storage) {
        return;
    }
    
    if (![storage isLocalResourcePath:path]) {
        return;
    }

    if([storage isResoursFoundAtPath:path]) {
        return;
    }

    NSString * relativePath = [storage relativePathFromFullPath:path];

    std::string str([relativePath UTF8String]);
    auto reader = _package->ReaderForRelativePath(str);

    if(reader == NULL){
        NSLog(@"No archive found for path %@", relativePath);
        return;
    }

    [self saveContentOfReader:reader toPath: path inStorrage:storage];
}

- (void)saveContentOfReader:(const ePub3::ArchiveReader *)reader toPath:(NSString *)path inStorrage:(LOXTemporaryFileStorage *)storage
{
    char buffer[1024];

    NSMutableData * data = [NSMutableData data];

    ssize_t readBytes = reader->read(buffer, 1024);

    while (readBytes > 0) {
        [data appendBytes:buffer length:(NSUInteger) readBytes];
        readBytes = reader->read(buffer, 1024);
    }

    [storage saveData:data  toPaht:path];
}

@end
