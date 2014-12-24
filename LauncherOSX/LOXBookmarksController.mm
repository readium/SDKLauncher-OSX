//  LauncherOSX
//
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
#import "LOXBookmarksController.h"
#import "LOXBook.h"
#import "LOXBookmark.h"
#import "LOXAppDelegate.h"
#import "LOXBookmarkEditController.h"


@interface LOXBookmarksController ()

- (void)removeBookmarkClicked:(id)sender;

- (NSArray *)createMenuItemsForBookmarks:(NSArray *)bookmarks;

- (NSMenu *)createBookmarkOptionsSubmenuForIndex:(NSInteger)ix;

- (void)bookmarkClicked:(id)sender;


@end

@implementation LOXBookmarksController {

    LOXBook *_book;

}

-(void)awakeFromNib
{
    [self updateUI];
}

-(void) setBook:(LOXBook*) book;
{
    [self.bookmarkEditController closeSheet];

    _book = book;
    [self updateUI];

}

- (void) editBookmarkClicked:(id)sender
{
    NSMenuItem * menuItem = sender;

    LOXBookmark * bookmark = _book.bookmarks[(NSUInteger)menuItem.tag];
    [self.bookmarkEditController editBookmark:bookmark];
}


- (void) removeBookmarkClicked:(id)sender
{
    NSMenuItem * menuItem = sender;

    LOXBookmark * bookmark = _book.bookmarks[(NSUInteger)menuItem.tag];
    [_book removeBookmark:bookmark];

    [self updateUI];
}


-(NSArray *)createMenuItemsForBookmarks:(NSArray *)bookmarks
{
    NSMutableArray *menuItems = [NSMutableArray array];

    for (NSUInteger i = 0; i < bookmarks.count; i++) {

        LOXBookmark *bookmark = [bookmarks objectAtIndex:i];

        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:bookmark.title
                                                       action:@selector(bookmarkClicked:) keyEquivalent:@""];


        [item setTag:i];
        [item setTarget:self];
        [item setSubmenu:[self createBookmarkOptionsSubmenuForIndex:i]];

        [menuItems addObject:item];
    }

    return menuItems;
}

-(NSMenu *)createBookmarkOptionsSubmenuForIndex:(NSInteger) ix
{
    NSMenu *bookmarkOptionsMenu = [[NSMenu alloc] initWithTitle:@"Bookmark Options"];

    NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"Edit bookmark"
                                                   action:@selector(editBookmarkClicked:) keyEquivalent:@""];

    [editItem setTarget:self];
    [editItem setTag:ix];

    [bookmarkOptionsMenu addItem:editItem];

    NSMenuItem *removeItem = [[NSMenuItem alloc] initWithTitle:@"Remove bookmark"
                                                   action:@selector(removeBookmarkClicked:) keyEquivalent:@""];

    [removeItem setTarget:self];
    [removeItem setTag:ix];

    [bookmarkOptionsMenu addItem:removeItem];

    return bookmarkOptionsMenu;

}

-(void) updateUI
{
    [self.addBookmarkMenuItem setEnabled: _book != nil ];

    //remove all bookmarks but leave 'add bookmark' and separator items
    for(NSInteger i = [self.bookmarksMenu numberOfItems] - 1; i > 1; i--) {

        [self.bookmarksMenu removeItemAtIndex:i];
    }

    if(!_book) {
        return;
    }


    NSArray *menuItems = [self createMenuItemsForBookmarks:_book.bookmarks];


    NSArray *sortedArray = [menuItems sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {

        LOXBookmark *first = [_book.bookmarks objectAtIndex:(NSUInteger)((NSMenuItem*)a).tag];
        LOXBookmark *second = [_book.bookmarks objectAtIndex:(NSUInteger)((NSMenuItem*)b).tag];

        return [first.title compare:second.title options:NSCaseInsensitiveSearch];
    }];


    for(NSMenuItem *item in sortedArray) {

       [self.bookmarksMenu addItem:item];
    }
}

- (IBAction)addBookmark:(id)sender
{
    LOXBookmark * bookmark = [self.mainController createBookmark];

    if(!bookmark) {
        return;
    }

    NSInteger n = _book.bookmarks.count + 1;
    bookmark.title = [NSString stringWithFormat:@"Bookmark #%li", n];

    [self.bookmarkEditController editBookmark:bookmark];
}

- (void)finishEditingBookmark:(LOXBookmark *)bookmark
{
    if([bookmark isNew]) {
        [_book addBookmark:bookmark];
    }

    [self updateUI];
}


- (void)bookmarkClicked:(id)sender
{
    NSMenuItem * menuItem = sender;

    LOXBookmark * bookmark = _book.bookmarks[(NSUInteger)menuItem.tag];
    [self.mainController openBookmark: bookmark];
}


@end