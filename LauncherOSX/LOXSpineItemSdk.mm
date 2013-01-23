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

#import "spine.h"
#import "LOXSpineItemSdk.h"


@implementation LOXSpineItemSdk

@synthesize idref = _idref;

- (const ePub3::SpineItem *)sdkSpineItem
{
    return _sdkSpineItem;
}

- (id)initWithSdkSpineItem:(const ePub3::SpineItem *)sdkSpineItem
{
    self = [super init];
    if(self) {
        auto str = sdkSpineItem->Idref().c_str();

        _idref = [[NSString stringWithUTF8String:str] retain];
        _sdkSpineItem = sdkSpineItem;
    }

    return self;

}

- (void)dealloc
{
    [_idref release];
    [super dealloc];
}

@end