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
#import "LOXScriptInjector.h"
#import "LOXUserData.h"
#import "LOXBook.h"
#import "LOXBookmarksController.h"
#import "LOXBookmark.h"
#import "LOXSpineItem.h"
#import "LOXToc.h"
#import "LOXTocViewController.h"


using namespace ePub3;

@interface LOXAppDelegate ()


- (NSString *)selectFile;

- (void)updateWebView;

- (void)openCurrentSpineItemContentCfi:(NSString *)cfi;

- (void)openCurrentSpineItemElementId:(NSString *)elementId;

- (void)reportError:(NSString *)error;

- (bool)openDocumentWithPath:(NSString *)path;

@end


@implementation LOXAppDelegate {
@private
    LOXePubSdkApi *_epubApi;
    LOXScriptInjector *_scriptInjector;
    LOXUserData *_userData;
    LOXBook*_currentBook;

    NSString *_contentCfiWaitingForWebViewRendering;
    NSString *_elementIdWaitingForWebViewRendering;
}


- (id)init
{
    self = [super init];
    if (self) {

        _scriptInjector = [[LOXScriptInjector alloc] init];
        _userData = [[LOXUserData alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [_scriptInjector release];
    [_epubApi release];
    [_userData release];
    [_contentCfiWaitingForWebViewRendering release];
    [_elementIdWaitingForWebViewRendering release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.spineViewController.selectionChangedLiscener = self;
}

-(void) awakeFromNib
{
    _epubApi = [[LOXePubSdkApi alloc] init];
    self.webViewController.epubApi = _epubApi;
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

        [self.spineViewController clear];

        [_epubApi openFile:path];

        //spine items
        NSArray *items = [_epubApi getSpineItems];

        for (id item in items) {
            [self.spineViewController addSpineItem:item];
        }

        if (items.count > 0) {
            [self.spineViewController selectSpineIndex:0];
        }

        LOXToc *toc = [_epubApi getToc];
        [self.tocViewController setToc:toc];

        _currentBook = [self getBookForPath:path];
        _currentBook.dateOpened = [NSDate date];
        [self.bookmarksController setBook:_currentBook];

        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];

        [self.window setTitle:[path lastPathComponent]];

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
        book.packageId = [_epubApi getPackageID];
        book.name = [_epubApi getPackageTitle];
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


- (void)spineView:(LOXSpineViewController *)spineViewController selectionChangedTo:(LOXSpineItem *)spineItem
{
    self.currentSpineItem = spineItem;
    [self updateWebView];
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

- (void)updateWebView
{
    if (self.currentSpineItem) {

        NSString *path = [_epubApi getPathToSpineItem:self.currentSpineItem];

        NSString *html = [_scriptInjector injectHtmlFile:path];

        [self.webViewController displayHtml:html withBaseUrlPath:_scriptInjector.baseUrlPath];
    }
    else {
        [self.webViewController clear];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [_userData save];

    return NSTerminateNow;
}


- (LOXBookmark *)createBookmark
{
    if(!self.currentSpineItem) {
        return nil;
    }

    NSInteger n = _currentBook.bookmarks.count + 1;

    LOXBookmark *bookmark = [[[LOXBookmark alloc] init] autorelease];

    bookmark.title = [NSString stringWithFormat:@"Bookmark #%li", n];
    bookmark.idref = _currentSpineItem.idref;
    bookmark.basePath = _currentSpineItem.basePath;
    bookmark.spineItemCFI = [_epubApi getCfiForSpineItem:_currentSpineItem];
    bookmark.contentCFI = [self.webViewController getCurrentPageCfi];

    return bookmark;
}


- (void)openBookmark:(LOXBookmark *)bookmark
{

    LOXSpineItem *spineItem = [_epubApi findSpineItemWithIdref: bookmark.idref];

    if(spineItem == nil) {
        return;
    }

    if (_currentSpineItem == spineItem) {
        [self openCurrentSpineItemContentCfi:bookmark.contentCFI];
    }
    else {
        _contentCfiWaitingForWebViewRendering = bookmark.contentCFI;
        [_contentCfiWaitingForWebViewRendering retain];
        [self.spineViewController selectSpieItem:spineItem];
    }
}

-(void)openCurrentSpineItemContentCfi:(NSString *) cfi
{
    int pageIx = [self.webViewController getPageForElementCfi:cfi];
    if(pageIx >= 0) {
        [self.webViewController openPageIndex:pageIx];
    }

}

-(void)openCurrentSpineItemElementId:(NSString*) elementId
{
    int pageIx = [self.webViewController getPageForElementId:elementId];
    if(pageIx >= 0) {
        [self.webViewController openPageIndex:pageIx];
    }
}

- (void)onPaginationScriptingReady
{
    if (_contentCfiWaitingForWebViewRendering != nil ){

        [self openCurrentSpineItemContentCfi: _contentCfiWaitingForWebViewRendering];

        [_contentCfiWaitingForWebViewRendering release];
        _contentCfiWaitingForWebViewRendering = nil;
    }

    if (_elementIdWaitingForWebViewRendering != nil) {

        [self openCurrentSpineItemElementId:_elementIdWaitingForWebViewRendering];

        [_elementIdWaitingForWebViewRendering release];
        _elementIdWaitingForWebViewRendering = nil;
    }
}

-(void)openContentDocRef:(NSString *)contentRef
{
    NSRange range =[contentRef rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"#"]];

    NSString *contentDocUrl = range.location != NSNotFound ? [contentRef substringWithRange: NSMakeRange(0, range.location)] : contentRef;

    NSString *elementId = nil;
    if(range.location != NSNotFound && range.location + 1 < contentRef.length) {
        elementId = [contentRef substringFromIndex:range.location + 1];
    }

    LOXSpineItem *spineItem = [_epubApi findSpineItemWithBasePath: contentDocUrl];

    if(spineItem == nil) {
        return;
    }

    if (_currentSpineItem == spineItem) {
        if(elementId != nil) {
            [self openCurrentSpineItemElementId:elementId];
        }
    }
    else {
        if(elementId != nil) {
            [_elementIdWaitingForWebViewRendering release];
            _elementIdWaitingForWebViewRendering = elementId;
            [_elementIdWaitingForWebViewRendering retain];

        }

        [self.spineViewController selectSpieItem:spineItem];
    }

}

@end
