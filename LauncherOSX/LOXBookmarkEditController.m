//
//  LOXBookmarkEditController.m
//  LauncherOSX
//
//  Created by Boris Schneiderman on 2013-02-27.
//  Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//

#import "LOXBookmarkEditController.h"
#import "LOXBookmark.h"
#import "LOXBookmarksController.h"

@interface LOXBookmarkEditController ()
- (void)updateControls;

- (void)updateUI;


@end

@implementation LOXBookmarkEditController {

    LOXBookmark *_bookmark;
}

- (IBAction)onOK:(id)sender
{
    [self updateData];
    [self.bookmarksController finishEditingBookmark:_bookmark];
    [self closeSheet];
}

- (IBAction)onCancel:(id)sender
{
    [self closeSheet];
}

-(void)closeSheet
{
    if(!self.sheet) {
        return;
    }

    [_bookmark release];
    [NSApp endSheet:self.sheet];
    [self.sheet close];
    self.sheet = nil;
}

- (void)editBookmark:(LOXBookmark *)bookmark
{
    if(self.sheet) {

        return;
    }

    _bookmark = bookmark;
    [_bookmark retain];

    [NSBundle loadNibNamed:@"BookmarkDlg" owner:self];

    [NSApp beginSheet:self.sheet
       modalForWindow:[[NSApp delegate] window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];

    [self updateControls];


}

- (void)dealloc
{
    [_bookmark release];
    [super dealloc];
}

- (void)controlTextDidChange:(NSNotification *)notification {

    [self updateUI];
}

-(void)updateControls
{
    [self.nameText setStringValue:_bookmark.title];
    [self.nameText selectText:self];
}

//we can do validation here and return NO if validation failed
-(bool)updateData
{
    _bookmark.title = [self.nameText stringValue];

    return YES;
}

-(void)updateUI
{
    [self.okButton setEnabled:[self.nameText stringValue].length > 0];
}

@end
