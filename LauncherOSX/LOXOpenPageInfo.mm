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

#import "LOXOpenPageInfo.h"
#import "LOXUtil.h"


@implementation LOXOpenPageInfo {

}

+ (LOXOpenPageInfo *)pageInfoFromDictionary:(NSDictionary *)dictionary {

    LOXOpenPageInfo *pageInfo = [[LOXOpenPageInfo alloc] init];

    pageInfo.idref = [LOXUtil valueForKey:@"idref" orDefault:@"" fromDictionary:dictionary];
    pageInfo.spineItemPageIndex = [[LOXUtil valueForKey:@"spineItemPageIndex" orDefault:[NSNumber numberWithInt:0] fromDictionary:dictionary] integerValue];
    pageInfo.spineItemPageCount = [[LOXUtil valueForKey:@"spineItemPageCount" orDefault:[NSNumber numberWithInt:0] fromDictionary:dictionary] integerValue];
    pageInfo.spineItemIndex = [[LOXUtil valueForKey:@"spineItemIndex" orDefault:[NSNumber numberWithInt:0] fromDictionary:dictionary] integerValue];

    return pageInfo;
}

@end