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


#import <Foundation/Foundation.h>

@class LOXBook;
@class LOXePubApi;
@class LOXAppDelegate;
@class LOXBookmarkEditController;
@class LOXBookmark;


@interface LOXBookmarksController : NSObject

@property (assign) IBOutlet NSMenu *bookmarksMenu;
@property (assign) IBOutlet LOXAppDelegate *mainController;
@property (assign) IBOutlet NSMenuItem *addBookmarkMenuItem;
@property (assign) IBOutlet LOXBookmarkEditController *bookmarkEditController;

-(void) setBook:(LOXBook*) book;

-(void)updateUI;

- (IBAction)addBookmark:(id)sender;

- (void) finishEditingBookmark:(LOXBookmark *)bookmark;

@end