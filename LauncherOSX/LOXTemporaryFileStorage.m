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


#import "LOXTemporaryFileStorage.h"
#import "LOXUtil.h"


@interface LOXTemporaryFileStorage ()

- (void)createCleanDirectory:(NSString *)directory;


@end

@implementation LOXTemporaryFileStorage

@synthesize uuid = _uuid;
@synthesize rootDirectory = _rootDirectory;

-(id)initWithUUID:(NSString *)uuid forBasePath:(NSString *)basePath
{
    self = [super init];

    if(self) {

        _uuid = uuid;
        [_uuid retain];

        NSString *subdir;

        if(basePath && basePath.length > 0 && ![basePath isEqualToString:@"/"]) {
            subdir = [_uuid stringByAppendingPathComponent:basePath];
        }
        else {
            subdir = uuid;
        }

        if([subdir hasSuffix:@"/"]) {
            subdir = [subdir substringToIndex:subdir.length - 1];
        }

        _rootDirectory = [[NSTemporaryDirectory() stringByAppendingPathComponent:subdir] retain];

        [self createCleanDirectory:_rootDirectory];

    }

    return self;
}

- (void)createCleanDirectory:(NSString *)directory
{
    BOOL isDir;

    if ([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir]) {
        [[NSFileManager defaultManager] removeItemAtPath:directory error:nil];
    }

    [self ensureDirectory:directory];
}

-(bool)isLocalResourcePath:(NSString*)path
{
    return [path hasPrefix:_rootDirectory];
}

-(NSString *)relativePathFromFullPath:(NSString*)fullPath
{
    if ([fullPath hasPrefix:_rootDirectory]) {
        return [fullPath substringFromIndex:_rootDirectory.length + 1];
    }

    return fullPath;

}

- (void)saveData:(NSData *)data toPaht:(NSString *)path
{
    NSString *directory = [path stringByDeletingLastPathComponent];

    [self ensureDirectory:directory];

    [data writeToFile:path atomically:YES];
}

- (void)ensureDirectory:(NSString *) path
{
    BOOL isDir;

    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
        return;
    }

    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES attributes:nil error:nil];
}


-(bool) isResoursFoundAtPath:(NSString *)fullPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:fullPath];
}

- (NSString *)absolutePathForFile:(NSString *)fileName
{
    return [NSString stringWithFormat:@"%@/%@", _rootDirectory, fileName];
}

- (void)dealloc
{
    [_rootDirectory release];
    [_uuid release];

    [super dealloc];
}

@end