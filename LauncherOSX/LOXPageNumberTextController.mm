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