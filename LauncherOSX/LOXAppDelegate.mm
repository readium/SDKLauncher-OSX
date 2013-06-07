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
#import "LOXCurrentPagesInfo.h"
#import "LOXPageNumberTextController.h"

using namespace ePub3;

@interface LOXAppDelegate ()


- (NSString *)selectFile;

- (LOXBook *)findOrCreateBookForCurrentPackageWithPath:(NSString *)path;

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

@synthesize currentPagesInfo = _currentPagesInfo;

- (id)init
{
    self = [super init];
    if (self) {

        _currentPagesInfo = [[LOXCurrentPagesInfo alloc] init];
        _userData = [[LOXUserData alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [_package release];
    [_epubApi release];
    [_userData release];
    [_currentPagesInfo release];
    [super dealloc];
}


-(void) awakeFromNib
{
    _epubApi = [[LOXePubSdkApi alloc] init];

    self.spineViewController.currentPagesInfo = _currentPagesInfo;
    self.webViewController.currentPagesInfo = _currentPagesInfo;
    self.pageNumController.currentPagesInfo = _currentPagesInfo;
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

        _currentBook = [self findOrCreateBookForCurrentPackageWithPath:path];
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

- (LOXBook *)findOrCreateBookForCurrentPackageWithPath:(NSString *)path
{
    LOXBook * book = [_userData findBookWithId:_package.packageId];

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
    NSInteger n = _currentBook.bookmarks.count + 1;

    LOXBookmark *bookmark = [self.webViewController createBookmark];
    if(!bookmark) {
        return nil;
    }

    LOXSpineItem *spineItem = [_package.spine getSpineItemWithId:bookmark.idref];
    if(!spineItem) {
        return nil;
    }

    bookmark.title = [NSString stringWithFormat:@"Bookmark #%li", n];
    bookmark.basePath = spineItem.href;
    bookmark.spineItemCFI = [_package getCfiForSpineItem: spineItem];

    return bookmark;
}


- (void)openBookmark:(LOXBookmark *)bookmark
{
    [self.webViewController openSpineItem:bookmark.idref elementCfi:bookmark.contentCFI];
}

-(void)openContentUrl:(NSString *)contentRef fromSourceFileUrl:(NSString*) sourceRef
{
   [self.webViewController openContentUrl:contentRef fromSourceFileUrl:sourceRef];
}

@end
