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
#import "LOXeBook.h"

@interface LOXePubCocoaApi ()
- (void)releaseBook;

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
    [self releaseBook];

    _ebook = [[LOXeBook eBookWithFile:file] retain];
}

- (void)releaseBook
{
    if (_ebook) {
        [_ebook release];
        _ebook = nil;
    }
}

- (void)dealloc
{
    [self releaseBook];
    [super dealloc];
}

- (NSArray *)getSpineItems
{
    return [_ebook getSpineItems];
}

- (NSString*)getGetPathToSpineItem:(LOXSpineItem *) spineItem
{
    return [_ebook getPathToSpineItem:spineItem];
}

@end
