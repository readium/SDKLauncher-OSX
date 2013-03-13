//
//  Bookmark.m
//  LauncherOSX
//
//  Created by Boris Schneiderman on 2013-02-19.
//  Copyright (c) 2013 Boris Schneiderman. All rights reserved.
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
