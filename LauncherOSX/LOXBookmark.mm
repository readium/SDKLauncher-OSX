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

#import "LOXBookmark.h"
#import "LOXBook.h"


@implementation LOXBookmark

@synthesize idref;
@synthesize book;
@synthesize title;
@synthesize spineItemCFI;
@synthesize contentCFI;
@synthesize basePath = _basePath;


+(id) bookmarkFromDictionary:(NSDictionary *)dict
{
    LOXBookmark * bookmark = [[[LOXBookmark alloc] init] autorelease];

    for (id key in dict.allKeys) {
        [bookmark setValue:dict[key] forKey:key];
    }

    return bookmark;
}

-(NSDictionary *) toDictionary
{
    return @{@"idref"        : self.idref,
             @"basePath"     : self.basePath,
             @"title"        : self.title,
             @"spineItemCFI" : self.spineItemCFI,
             @"contentCFI"   : self.contentCFI };
}

- (id) init
{
    self = [super init];

    if(self) {
        self.idref = @"";
        self.basePath = @"";
        self.title = @"";
        self.spineItemCFI = @"";
        self.contentCFI = @"";
    }

    return self;
}

- (bool)isNew
{
    return self.book == nil;
}

- (void)dealloc
{
    [idref release];
    [title release];
    [spineItemCFI release];
    [contentCFI release];
    [_basePath release];
    [super dealloc];
}

@end
