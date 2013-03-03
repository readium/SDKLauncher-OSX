//
//  LOXBookmarkEditController.h
//  LauncherOSX
//
//  Created by Boris Schneiderman on 2013-02-27.
//  Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class LOXBookmark;
@class LOXBookmarksController;

@interface LOXBookmarkEditController : NSObject

@property (assign) IBOutlet NSWindow *sheet;

@property (assign) IBOutlet NSButton *okButton;
@property (assign) IBOutlet NSButton *cancelButton;
@property (assign) IBOutlet LOXBookmarksController *bookmarksController;
@property (assign) IBOutlet NSTextField *nameText;

- (IBAction)onOK:(id)sender;
- (IBAction)onCancel:(id)sender;

- (void)closeSheet;


- (void)editBookmark:(LOXBookmark *)bookmark;


@end
