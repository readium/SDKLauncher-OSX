//
//  LOXZipHelper.m
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

#import "LOXZipHelper.h"
#import "ZipFile.h"
#import "ZipReadStream.h"
#import "FileInZipInfo.h"
#import "LOXUtil.h"

@interface LOXZipHelper ()


@end

@implementation LOXZipHelper


+ (void)unzipFile:(NSString *)fileName toFolder:(NSString *)destinationFolder
{
    ZipFile *unzipFile = [[ZipFile alloc] initWithFileName:fileName mode:ZipFileModeUnzip];
    [unzipFile goToFirstFileInZip];

    for (int i = 0; i < [unzipFile numFilesInZip]; i++) {
        FileInZipInfo *info = [unzipFile getCurrentFileInZipInfo];

        ZipReadStream *read = [unzipFile readCurrentFileInZip];
        NSMutableData *data = [[NSMutableData alloc] initWithLength:info.length];
        [read readDataWithBuffer:data];
        NSString* fullPath = [NSString stringWithFormat:@"%@/%@", destinationFolder, info.name];
        [LOXUtil ensureDirectoryForFile:fullPath];
        [data writeToFile:fullPath atomically:NO];
        [data release];
        [read finishedReading];

        [unzipFile goToNextFileInZip];

    }

    [unzipFile close];
    [unzipFile release];

}


@end
