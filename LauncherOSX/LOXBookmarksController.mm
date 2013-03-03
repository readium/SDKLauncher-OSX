//
// Created by boriss on 2013-02-26.
//
// To change the template use AppCode | Preferences | File Templates.
//


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
    for(int i = [self.bookmarksMenu numberOfItems] - 1; i > 1; i--) {

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
    NSLog(@"Bookmark menu item clicked");
}

- (void)dealloc
{
     [super dealloc];
}


@end