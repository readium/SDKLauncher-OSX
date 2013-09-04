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

        NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:bookmark.title
                                                       action:@selector(bookmarkClicked:) keyEquivalent:@""] autorelease];


        [item setTag:i];
        [item setTarget:self];
        [item setSubmenu:[self createBookmarkOptionsSubmenuForIndex:i]];

        [menuItems addObject:item];
    }

    return menuItems;
}

-(NSMenu *)createBookmarkOptionsSubmenuForIndex:(NSInteger) ix
{
    NSMenu *bookmarkOptionsMenu = [[[NSMenu alloc] initWithTitle:@"Bookmark Options"] autorelease];

    NSMenuItem *editItem = [[[NSMenuItem alloc] initWithTitle:@"Edit bookmark"
                                                   action:@selector(editBookmarkClicked:) keyEquivalent:@""] autorelease];

    [editItem setTarget:self];
    [editItem setTag:ix];

    [bookmarkOptionsMenu addItem:editItem];

    NSMenuItem *removeItem = [[[NSMenuItem alloc] initWithTitle:@"Remove bookmark"
                                                   action:@selector(removeBookmarkClicked:) keyEquivalent:@""] autorelease];

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

- (void)dealloc
{
     [super dealloc];
}


@end