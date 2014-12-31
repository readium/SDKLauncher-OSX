//
//  LOXAppDelegate.h
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

#import <Cocoa/Cocoa.h>
#import "LOXSpineViewController.h"
#import "LOXWebViewController.h"

@class LOXUserData;
@class LOXBookmarksController;
@class LOXBookmark;
@class LOXBookmarkEditController;
@class LOXTocViewController;
@class LOXSpineItem;
@class LOXCurrentPagesInfo;
@class LOXPreferencesController;
@class LOXMediaOverlay;
@class LOXMediaOverlayController;

//events
NSString *const LOXPageChangedEvent = @"PageChangedEvent";
NSString *const LOXMediaOverlayStatusChangedEvent = @"LOXMediaOverlayStatusChangedEvent";
NSString *const LOXMediaOverlayTTSSpeakEvent = @"LOXMediaOverlayTTSSpeakEvent";
NSString *const LOXMediaOverlayTTSStopEvent = @"LOXMediaOverlayTTSStopEvent";


@interface LOXAppDelegate : NSObject <NSApplicationDelegate>


//ui
@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet NSMenuItem *preferencesMenu;

@property (assign) IBOutlet LOXSpineViewController *spineViewController;
@property (assign) IBOutlet LOXWebViewController *webViewController;
@property (assign) IBOutlet LOXBookmarksController *bookmarksController;
@property (assign) IBOutlet LOXTocViewController *tocViewController;
@property (assign) IBOutlet LOXPageNumberTextController *pageNumController;
@property (assign) IBOutlet LOXPreferencesController *preferencesController;
@property (assign) IBOutlet LOXMediaOverlayController *mediaOverlayController;

@property (nonatomic, readonly) LOXCurrentPagesInfo *currentPagesInfo;

- (IBAction)openDocument:(id)sender;
- (IBAction)showPreferences:(id)sender;

- (LOXPreferences *)getPreferences;

- (LOXBookmark*)createBookmark;

- (void)openBookmark:(LOXBookmark *)bookmark;

- (void)openContentUrl:(NSString *)contentRef fromSourceFileUrl:(NSString *)sourceRef;

- (void)onReaderInitialized;


@end
