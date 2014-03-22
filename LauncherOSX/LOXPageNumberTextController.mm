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

#import "LOXPageNumberTextController.h"
#import "LOXWebViewController.h"
#import "LOXCurrentPagesInfo.h"
#import "LOXOpenPageInfo.h"
#import "LOXAppDelegate.h"


@interface LOXPageNumberTextController ()

- (void)onPageChanged:(NSNotification*) notification;
- (void)updatePageNumberControls;

@end

@implementation LOXPageNumberTextController {


}

-(void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPageChanged:)
                                                 name:LOXPageChangedEvent
                                               object:nil];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)onPageChanged:(NSNotification*) notification
{
    [self updatePageNumberControls];
}

- (void)updatePageNumberControls
{
    LOXOpenPageInfo *openPage = [self.currentPagesInfo firstOpenPage];

    if (openPage) {

        [self.pageNumberCtrl setEditable:YES];
        [self.pageNumberCtrl setStringValue:[NSString stringWithFormat:@"%@", [[self.currentPagesInfo getPageNumbers] componentsJoinedByString:@" | "]]];
        [self.pageCountCtrl setStringValue:[NSString stringWithFormat:@" / %d", [self.currentPagesInfo getPageCount]]];
    }
    else {

        [self.pageNumberCtrl setEditable:NO];
        [self.pageNumberCtrl setStringValue:@""];
        [self.pageCountCtrl setStringValue:@""];

    }
}


- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    int page =  (int)[self.pageNumberCtrl integerValue];

    if(page > 0 && page <= [self.currentPagesInfo getPageCount]) {

        [self.webViewController openPage: page - 1];
    }
    else {
        NSBeep();
    }

}


@end