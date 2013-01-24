//
//  LOXePubCocoaApi.m
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

#import "LOXePubCocoaApi.h"
#import "LOXContainer.h"
#import "LOXZipHelper.h"
#import "LOXContainerParser.h"
#import "LOXPackageParser.h"
#import "LOXTemporaryFileStorage.h"
#import "LOXPackage.h"
#import "LOXSpineItemCocoa.h"

@interface LOXePubCocoaApi ()

- (void)cleanup;

@end

@implementation LOXePubCocoaApi

-(id)init
{
    self = [super init];
    if(self){
        _apiType = kePubCocoaApi;
    }
    
    return self;
}

- (void)openFile:(NSString *)file
{
    [self cleanup];

    _tmpDir = [[LOXTemporaryFileStorage alloc] init];

    [LOXZipHelper unzipFile:file toFolder: _tmpDir.rootDirectory];

    _container = [[self parseContainer] retain];
}


- (void)cleanup
{
    [_tmpDir release];
    [_container release];
    _container = nil;
}


- (void)dealloc
{
    [self cleanup];
    [super dealloc];
}

- (NSArray *)getSpineItems
{
    NSMutableArray * spineItems = [NSMutableArray array];

    for (LOXPackage * package in [_container getPackages]){
        [spineItems addObjectsFromArray:[package getSpineItems]];
    }

    return spineItems;
}

- (NSString*)getPathToSpineItem:(id<LOXSpineItem>) spineItem
{
    LOXSpineItemCocoa * spineItemCocoa = (LOXSpineItemCocoa *)spineItem;

    NSString * href = [spineItemCocoa getHref];

    NSString *dir = [spineItemCocoa.package.path stringByDeletingLastPathComponent];

    return [NSString stringWithFormat:@"%@/%@", dir, href];

}


-(LOXContainer *)parseContainer
{
    LOXContainer* container = [[[LOXContainer alloc] init] autorelease];

    LOXContainerParser * parser = [[[LOXContainerParser alloc] init] autorelease];

    NSString *path = [_tmpDir absolutePathForFile:@"META-INF/container.xml"];

    NSData *data = [NSData dataWithContentsOfFile:path];

    NSArray *rootFiles = [parser parseData:data];

    for (NSString * rootFile in rootFiles){
        [container addPackage:[self parsePackage:rootFile]];
    }

    return container;
}

- (LOXPackage *)parsePackage:(NSString*) localPackagePath
{
    NSString *packagePath = [_tmpDir absolutePathForFile:localPackagePath];

    NSData *data = [NSData dataWithContentsOfFile:packagePath];

    LOXPackageParser *parser = [[[LOXPackageParser alloc] init] autorelease];

    [parser parseData:data];

    LOXPackage * package = [parser package];
    package.path = packagePath;

    return package;
}

-(void)prepareResourceWithPath:(NSString *)path
{
    //because we unpack everything - all resources already stored
}


@end
