//
//  LOXAppDelegate.h
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


#include <string>
#import <Cocoa/Cocoa.h>
#import "LOXSpineViewController.h"
#import "LOXWebViewController.h"

@class LOXePubApi;
@protocol LOXSpineItem;
@class LOXScriptInjector;
@class LOXUserData;
@class LOXBookmarksController;
@class LOXBookmark;
@class LOXBookmarkEditController;


@interface LOXAppDelegate : NSObject <NSApplicationDelegate, LOXSpineViewControllerDelegate>


//ui
@property (assign) IBOutlet NSWindow *window;

@property (assign) IBOutlet LOXSpineViewController *spineViewController;
@property (assign) IBOutlet LOXWebViewController *webViewController;
@property (assign) IBOutlet LOXBookmarksController *bookmarksController;


@property (assign) id<LOXSpineItem> currentSpineItem;


- (IBAction)openDocumentWithCocoaApi:(id)sender;
- (IBAction)openDocumentWithSdkApi:(id)sender;


- (LOXBookmark*)createBookmark;

@end
