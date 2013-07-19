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

    //Make sure that in nib file "Visible at launch" property set to false
    //otherwise sheet il not be attached to the window
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
