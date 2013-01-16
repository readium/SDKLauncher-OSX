//
//  LOXeBook.m
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

#import "LOXeBook.h"
#import "LOXUtil.h"
#import "LOXZipHelper.h"
#import "LOXPackageParser.h"
#import "LOXPackage.h"
#import "LOXContainerParser.h"
#import "LOXSpineItem.h"

@interface LOXeBook ()
- (void)parsePackage;

- (NSString *)createTmpFolderForBook;

@property(nonatomic, retain) NSString *fileName;
@property(nonatomic, retain) NSString *bookUUID;

- (void)parseContainer;

-(NSString*)absolutePathForFile:(NSString*)fileName;

@end


@implementation LOXeBook {

@private
    LOXPackage *_package;
    NSString *_tempRootFolder;
    NSMutableArray *_rootFiles;
}

+ (id)eBookWithFile:(NSString *)fileName
{
    return [[[LOXeBook alloc] initWithFile:fileName] autorelease];
}

- (id)initWithFile:(NSString *)fileName
{
    self = [super init];
    if (self) {
        _rootFiles = [[NSMutableArray alloc] init];
        self.bookUUID = [LOXUtil GetUUID];
        self.fileName = fileName;
        _tempRootFolder = [[self createTmpFolderForBook] retain];
        [LOXZipHelper unzipFile:fileName toFolder:_tempRootFolder];
        [self parseContainer];
        [self parsePackage];
    }

    return self;
}

- (void)dealloc
{
    self.bookUUID = nil;
    self.fileName = nil;

    [_rootFiles release];
    [_tempRootFolder release];
    [_package release];
    [super dealloc];
}


- (NSString *)createTmpFolderForBook
{
    NSString *tempFolder = [NSTemporaryDirectory() stringByAppendingPathComponent:self.bookUUID];

    BOOL isDir;

    if ([[NSFileManager defaultManager] fileExistsAtPath:tempFolder isDirectory:&isDir]) {
        [[NSFileManager defaultManager] removeItemAtPath:tempFolder error:nil];
    }

    [[NSFileManager defaultManager] createDirectoryAtPath:tempFolder
                              withIntermediateDirectories:NO attributes:nil error:nil];

    return tempFolder;
}

-(void)parseContainer
{
    LOXContainerParser * parser = [[[LOXContainerParser alloc] init] autorelease];

    NSData *data = [self readFileWithRelativeName:@"META-INF/container.xml"];

    [_rootFiles addObjectsFromArray:[parser parseData:data]];
}

- (NSString *)absolutePathForFile:(NSString *)fileName
{
    return [NSString stringWithFormat:@"%@/%@", _tempRootFolder, fileName];
}


- (void)parsePackage
{
    NSAssert(_rootFiles.count > 0, @"Mast have root files");

    NSString *packagePath = [self absolutePathForFile:[_rootFiles objectAtIndex:0]];

    NSData *data = [NSData dataWithContentsOfFile:packagePath];

    LOXPackageParser *parser = [[[LOXPackageParser alloc] init] autorelease];

    _package = [[parser parseData:data] retain];
    _package.path = packagePath;
}

- (NSData *)readFileWithRelativeName:(NSString *)fileName
{
    NSString *path = [self absolutePathForFile:fileName];

    NSData *data = [NSData dataWithContentsOfFile:path];

    return data;
}


- (NSArray *)getSpineItems
{
    return [_package spine];
}

-(NSString *)getPathToSpineItem:(LOXSpineItem *)spineItem
{
    NSString * href = [_package getHrefForItem:spineItem];

    NSString *dir = [_package.path stringByDeletingLastPathComponent];

    return [NSString stringWithFormat:@"%@/%@", dir, href];
}

@end
