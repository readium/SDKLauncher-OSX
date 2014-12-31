//
//  LOXAppDelegate.m
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
#import "LOXPreferencesController.h"
#import "LOXUtil.h"
#import "LOXMediaOverlay.h"
#import "LOXMediaOverlayController.h"

using namespace ePub3;

//FOUNDATION_EXPORT
extern NSString *const LOXPageChangedEvent;

@interface LOXAppDelegate ()


- (NSString *)selectFile;

- (LOXBook *)findOrCreateBookForCurrentPackageWithPath:(NSString *)path;

- (void)onPageChanged:(id)onPageChanged;

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

- (LOXPreferences *)getPreferences
{
    return _userData.preferences;
}

- (id)init
{
    self = [super init];
    if (self) {

        _currentPagesInfo = [[LOXCurrentPagesInfo alloc] init];
        _userData = [[LOXUserData alloc] init];
    }

    return self;
}

-(void) awakeFromNib
{
    _epubApi = [[LOXePubSdkApi alloc] init];

    self.spineViewController.currentPagesInfo = _currentPagesInfo;
    self.webViewController.currentPagesInfo = _currentPagesInfo;
    self.pageNumController.currentPagesInfo = _currentPagesInfo;
    self.spineViewController.selectionChangedLiscener = self.webViewController;

    self.preferencesController.webViewController = self.webViewController;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPageChanged:)
                                                 name:LOXPageChangedEvent
                                               object:nil];

}

- (void)onPageChanged:(id)onPageChanged
{
    LOXBookmark *bookmark = [self createBookmark];

    if(bookmark) {

        bookmark.title = @"lastOpenPage";
        _currentBook.lastOpenPage = bookmark;
    }
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

        _package = [_epubApi openFile:path];

        if(!_package) {
            return NO;
        }

        [self.tocViewController setPackage: _package];
        [self.spineViewController setPackage:_package];

        _currentBook = [self findOrCreateBookForCurrentPackageWithPath:path];
        _currentBook.dateOpened = [NSDate date];
        [self.bookmarksController setBook:_currentBook];

        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:[NSURL fileURLWithPath:path]];

        [self.window setTitle:[path lastPathComponent]];

        [self.webViewController openPackage:_package onPage:_currentBook.lastOpenPage];

        return YES;
    }
    catch (NSException *e) {
        [LOXUtil reportError:[e reason]];
    }
    catch (std::exception& e) {
        auto msg = e.what();
        [LOXUtil reportError:[NSString stringWithUTF8String:msg]];
    }
    catch (...) {
        [LOXUtil reportError:@"unknown exceprion"];
    }

    return NO;

}

- (LOXBook *)findOrCreateBookForCurrentPackageWithPath:(NSString *)path
{
    LOXBook * book = [_userData findBookWithId:_package.packageId fileName:[path lastPathComponent]];

    if(!book) {
        book = [[LOXBook alloc] init];
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

    LOXBookmark *bookmark = [self.webViewController createBookmark];
    if(!bookmark) {
        return nil;
    }

    LOXSpineItem *spineItem = [_package.spine getSpineItemWithId:bookmark.idref];
    if(!spineItem) {
        return nil;
    }

     bookmark.basePath = spineItem.href;
    bookmark.spineItemCFI = [_package getCfiForSpineItem: spineItem];

    return bookmark;
}


- (void)openBookmark:(LOXBookmark *)bookmark
{
    [self.webViewController openSpineItem:bookmark.idref elementCfi:bookmark.contentCFI];
}

- (void)openContentUrl:(NSString *)contentRef fromSourceFileUrl:(NSString*) sourceRef
{
   [self.webViewController openContentUrl:contentRef fromSourceFileUrl:sourceRef];
}

- (void)onReaderInitialized
{
   [self.webViewController updateSettings:_userData.preferences];
}


- (IBAction)showPreferences:(id)sender
{
    [self.preferencesController showPreferences:_userData.preferences];
}

@end
