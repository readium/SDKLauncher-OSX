//
//  LOXePubApi.m
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

#import "LOXePubApi.h"
#import "LOXePubSdkApi.h"
#import "LOXePubCocoaApi.h"
#import "LOXSpineItemSdk.h"


@interface LOXePubApi ()

@end

@implementation LOXePubApi

@synthesize apiType = _apiType;


+ (LOXePubApi *)ePubApiOfType:(ePubApiType)apiType
{
    if(apiType == kePubSdkApi){
        return [[[LOXePubSdkApi alloc] init] autorelease];
    }

    if (apiType == kePubCocoaApi) {
        return [[[LOXePubCocoaApi alloc] init] autorelease];
    }

    @throw [NSException exceptionWithName:@"Not Supported" reason:@"Unrecognized ePub Api Type" userInfo:nil];

}

- (void)openFile:(NSString *)file
{
    @throw [NSException exceptionWithName:@"Not Implemented" reason:@"Method must be overriden" userInfo:nil];
}

- (NSArray *)getSpineItems
{
    @throw [NSException exceptionWithName:@"Not Implemented" reason:@"Method must be overriden" userInfo:nil];
}

- (NSString *)getPathToSpineItem:(id<LOXSpineItem>)spineItem
{
    @throw [NSException exceptionWithName:@"Not Implemented" reason:@"Method must be overriden" userInfo:nil];
}

-(void)prepareResourceWithPath:(NSString *)path
{
    @throw [NSException exceptionWithName:@"Not Implemented" reason:@"Method must be overriden" userInfo:nil];
}


@end
