//
//  LOXAppDelegate.m
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

#import "LOXAppDelegate.h"
#import "LOXePubSdkApi.h"

#import <ePub3/container.h>
#import "LOXUserData.h"
#import "LOXBook.h"
#import "LOXBookmarksController.h"
#import "LOXBookmark.h"
#import "LOXSpineItem.h"
#import "LOXTocViewController.h"
#import "LOXSpine.h"
#import "LOXPackage.h"
#import "LOXCurrentPageData.h"
#import "LOXPageNumberTextController.h"


using namespace ePub3;

@interface LOXAppDelegate ()


- (NSString *)selectFile;

- (void)reportError:(NSString *)error;

- (bool)openDocumentWithPath:(NSString *)path;

@end



@implementation LOXAppDelegate {
@private

    LOXePubSdkApi *_epubApi;
    LOXUserData *_userData;
    LOXBook*_currentBook;
    LOXPackage *_package;
}

@synthesize currentPageData = _currentPageData;

- (id)init
{
    self = [super init];
    if (self) {

        _currentPageData = [[LOXCurrentPageData alloc] init];
        _userData = [[LOXUserData alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [_package release];
    [_epubApi release];
    [_userData release];
    [_currentPageData release];
    [super dealloc];
}


-(void) awakeFromNib
{
    _epubApi = [[LOXePubSdkApi alloc] init];

    self.webViewController.currentPageData = _currentPageData;
    self.pageNumController.currentPageData = _currentPageData;
    self.spineViewController.selectionChangedLiscener = self.webViewController;

}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}


- (IBAction)openDocument:(id)sender;
{
    NSString *path = [self selectFile];

    if (path == nil) {
        return;
    }

    [self openDocumentWithPath:path];
}

- (bool)openDocumentWithPath:(NSString *)path
{
    try {

        [_package release];
        _package = [_epubApi openFile:path];

        if(!_package) {
            return NO;
        }

        [_package retain];

        [self.tocViewController setPackage: _package];
        [self.spineViewController setPackage:_package];

        _currentBook = [self getBookForPath:path];
        _currentBook.dateOpened = [NSDate date];
        [self.bookmarksController setBook:_currentBook];

        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];

        [self.window setTitle:[path lastPathComponent]];

        [self.webViewController openPackage:_package];

        return YES;
    }
    catch (NSException *e) {
        [self reportError:[e reason]];
    }
    catch (std::exception& e) {
        auto msg = e.what();
        [self reportError:[NSString stringWithUTF8String:msg]];
    }
    catch (...) {
        [self reportError:@"unknown exceprion"];
    }

    return NO;

}

- (LOXBook *)getBookForPath:(NSString *)path
{
    LOXBook * book = [_userData findBookForPath:path];

    if(!book) {
        book = [[[LOXBook alloc] init] autorelease];
        book.filePath = path;
        book.packageId = _package.packageId;
        book.name = _package.title;
        [_userData addBook: book];
    }

    return book;
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    return [self openDocumentWithPath:filename];
}

- (void)reportError:(NSString *)error
{
    NSLog(@"%@", error);

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:error];
    [alert runModal];
}




- (NSString *)selectFile
{
    NSOpenPanel *dlg = [NSOpenPanel openPanel];

    NSArray *fileTypesArray = [NSArray arrayWithObjects:@"epub", nil];

    [dlg setCanChooseFiles:YES];
    [dlg setAllowedFileTypes:fileTypesArray];
    [dlg setAllowsMultipleSelection:FALSE];

    if ([dlg runModal] == NSOKButton) {
        NSURL *url = [dlg URL];

        return [url path];
    }

    return nil;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [_userData save];

    return NSTerminateNow;
}


- (LOXBookmark *)createBookmark
{
    LOXSpineItem *spineItem = [_package.spine getSpineItemWithId:_currentPageData.idref];

    if(!spineItem) {
        return nil;
    }

    NSInteger n = _currentBook.bookmarks.count + 1;

    LOXBookmark *bookmark = [[[LOXBookmark alloc] init] autorelease];

    bookmark.title = [NSString stringWithFormat:@"Bookmark #%li", n];
    bookmark.idref = spineItem.idref;
    bookmark.basePath = spineItem.href;
    bookmark.spineItemCFI = [_package getCfiForSpineItem: spineItem];
    bookmark.contentCFI = [self.webViewController getCurrentPageCfi];

    return bookmark;
}


- (void)openBookmark:(LOXBookmark *)bookmark
{
    [self.webViewController openSpineItem:bookmark.idref elementCfi:bookmark.spineItemCFI];
}

-(void)openContentUrl:(NSString *)contentRef fromSourceFileUrl:(NSString*) sourceRef
{
   [self.webViewController openContentUrl:contentRef fromSourceFileUrl:sourceRef];
}

@end
