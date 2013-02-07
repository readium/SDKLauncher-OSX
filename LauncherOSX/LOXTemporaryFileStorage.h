///  Created by Boris Schneiderman.
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

#import <Foundation/Foundation.h>


@interface LOXTemporaryFileStorage : NSObject{

@private
    NSString *_rootDirectory;
    NSString *_uuid;

}
- (NSString *)absolutePathForFile:(NSString *)fileName;

@property(nonatomic, readonly) NSString *uuid;
@property(nonatomic, readonly) NSString *rootDirectory;

-(id)initWithUUID:(NSString *)uuid forBasePath:(NSString *)basePath;

- (bool)isResoursFoundAtPath:(NSString *)fullPath;

- (bool)isLocalResourcePath:(NSString *)path;

- (NSString *)relativePathFromFullPath:(NSString *)fullPath;

- (void)saveData:(NSData *)data toPaht:(NSString *)path;


@end