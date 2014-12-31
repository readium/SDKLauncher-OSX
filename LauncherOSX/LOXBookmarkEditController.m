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
#import "LOXBookmarkEditController.h"
#import "LOXBookmark.h"
#import "LOXBookmarksController.h"

#import "LOXBookmarksController.h"
#import "LOXAppDelegate.h"


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

    //Make sure that in nib file "Visible at launch" property set to false
    //otherwise sheet il not be attached to the window
    [NSBundle loadNibNamed:@"BookmarkDlg" owner:self];

    //LOXAppDelegate* del = [NSApp delegate];
    LOXAppDelegate* del = [self.bookmarksController mainController];

    [NSApp beginSheet:self.sheet
       modalForWindow:[del window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];

    [self updateControls];

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
