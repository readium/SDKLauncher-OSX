//  Created by Boris Schneiderman.
//
//  Copyright (c) 2014 Readium Foundation and/or its licensees. All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice, this 
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  3. Neither the name of the organization nor the names of its contributors may be 
//  used to endorse or promote products derived from this software without specific 
//  prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
//  OF THE POSSIBILITY OF SUCH DAMAGE.

#import "LOXBook.h"
#import "LOXBookmark.h"

@interface LOXBook()

@property (strong, nonatomic, readwrite) NSArray *bookmarks;


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
    LOXBook * book = [[LOXBook alloc] init];

    for(id key in dict.allKeys) {

        if([@"bookmarks" isEqualToString:key]) {
            for (NSDictionary * bmDict in dict[key]) {
                [book addBookmark:[LOXBookmark bookmarkFromDictionary:bmDict]];
            }
        }
        else if([@"lastOpenPage" isEqualToString:key]) {
            NSDictionary *bookmarkDict = dict[key];
            if(bookmarkDict) {
                book.lastOpenPage = [LOXBookmark bookmarkFromDictionary:dict[key]];
            }
        }
        else {
            if([book respondsToSelector:NSSelectorFromString(key)]) {
                [book setValue:dict[key] forKey:key];
            }
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

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setObject:self.filePath forKey:@"filePath"];
    [dict setObject:self.packageId forKey:@"packageId"];
    [dict setObject:self.name forKey:@"name"];
    [dict setObject:self.dateCreated forKey:@"dateCreated"];
    [dict setObject:self.dateOpened forKey:@"dateOpened"];
    [dict setObject:bookmarks forKey:@"bookmarks"];
    if(self.lastOpenPage) {
        [dict setObject:[self.lastOpenPage toDictionary] forKey:@"lastOpenPage"];
    }

    return dict;
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

- (void)removeBookmark:(LOXBookmark *)bookmark
{
    [_bookmarks removeObject:bookmark];
}
@end
