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

#import <ePub3/container.h>
#import <ePub3/nav_table.h>
#include <ePub3/initialization.h>

#include <ePub3/utilities/error_handler.h>

#import "LOXSpineItem.h"
#import "LOXPackage.h"



@interface LOXePubSdkApi ()

- (void)cleanup;

- (void)readPackages;

@end

@implementation LOXePubSdkApi {
    NSMutableArray *_packages;

    ePub3::ContainerPtr _container;

    LOXPackage* _currentPackage;
}

bool LauncherErrorHandler(const ePub3::error_details& err)
{
    const char * msg = err.message();
    NSLog(@"%s\n", msg);

    return ePub3::DefaultErrorHandler(err);
}

+(void)initialize
{
    ePub3::ErrorHandlerFn launcherErrorHandler = LauncherErrorHandler;
    ePub3::SetErrorHandler(launcherErrorHandler);

    ePub3::InitializeSdk();
    ePub3::PopulateFilterManager();
}

- (id)init
{
    self = [super init];
    
    if(self){

        _packages = [NSMutableArray array];
    }

    return self;
}

- (LOXPackage *)openFile:(NSString *)file
{
    [self cleanup];

     _container = ePub3::Container::OpenContainer([file UTF8String]);

    [self readPackages];

    if([_packages count] > 0) {
        return [_packages objectAtIndex:0];
    }

    return nil;
}

- (void)readPackages
{
    auto packages = _container->Packages();

    for (auto package = packages.begin(); package != packages.end(); ++package) {

        [_packages addObject:[[LOXPackage alloc] initWithSdkPackage:*package]];
    }
}


- (void)dealloc
{
    [self cleanup];
}

- (void)cleanup
{
    [_packages removeAllObjects];
    _currentPackage = nil;
}






@end
