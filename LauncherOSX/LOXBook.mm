//
//  LOXBook.m
//  LauncherOSX
//
//  Created by Boris Schneiderman on 2013-02-19.
//  Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//

#import "LOXBook.h"
#import "LOXBookmark.h"

@interface LOXBook()

@property (retain, nonatomic, readwrite) NSArray *bookmarks;

@end

@implementation LOXBook {

    NSMutableArray *_bookmarks;
}

@synthesize name;
@synthesize filePath;
@synthesize bookmarks = _bookmarks;
@synthesize dateCreated;
@synthesize dateOpened;

+(id) bookFromDictionary:(NSDictionary *)dict
{
    LOXBook * book = [[[LOXBook alloc] init] autorelease];

    for(id key in dict.allKeys) {

        if([@"bookmarks" isEqualToString:key]) {

            for (NSDictionary * bmDict in dict[key]) {
                [book addBookmark:[LOXBookmark bookmarkFromDictionary:bmDict]];
            }

        }
        else {

            [book setValue:dict[key] forKey:key];
        }

    }

    return book;
}

-(NSDictionary *) toDictionary
{
    NSMutableArray *bookmarks = [NSMutableArray array];

    for (LOXBookmark *bookmark in self.bookmarks) {
        [bookmarks addObject:[bookmark toDictionary]];
    }

    return @{   @"filePath"       : self.filePath,
                @"packageId"      : self.packageId,
                @"name"           : self.name,
                @"dateCreated"    : self.dateCreated,
                @"dateOpened"     : self.dateOpened,
                @"bookmarks"      : bookmarks };
}

-(id)init
{
    self = [super init];
    if (self){

        self.name = @"";
        self.filePath = @"";
        self.bookmarks = [NSMutableArray array];
        self.dateCreated = [NSDate date];
        self.dateOpened = self.dateCreated;
    }

    return self;
}

-(void)addBookmark:(LOXBookmark *)bookmark
{
    bookmark.book = self;
    [_bookmarks addObject:bookmark];
}

- (void)dealloc
{
    [name release];
    [filePath release];
    [dateOpened release];
    [dateCreated release];
    [_bookmarks release];
    [super dealloc];
}

- (void)removeBookmark:(LOXBookmark *)bookmark
{
    [_bookmarks removeObject:bookmark];
}
@end
