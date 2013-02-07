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


@interface LOXPageNumberTextController ()
- (void)updatePageNumberControls;

@end

@implementation LOXPageNumberTextController {


}

@synthesize pageIx = _pageIx;
@synthesize pageCount = _pageCount;

-(void)setPageIndex:(int)index ofPages:(int)count
{
    _pageIx = index;
    _pageCount = count;

    [self updatePageNumberControls];
}

- (void)updatePageNumberControls
{
    if (_pageCount <= 0) {

        [self.pageNumberCtrl setEditable:NO];
        [self.pageNumberCtrl setStringValue:@""];
        [self.pageCountCtrl setStringValue:@"/"];

    }
    else {

        [self.pageNumberCtrl setEditable:YES];
        [self.pageNumberCtrl setStringValue:[NSString stringWithFormat:@"%d", _pageIx + 1]];
        [self.pageCountCtrl setStringValue:[NSString stringWithFormat:@"/ %d", _pageCount]];

    }
}


- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    int page =  [self.pageNumberCtrl integerValue];

    if(page > 0 && page <= _pageCount) {

        [self.webViewController openPageIndex:page - 1];
    }
    else {
        NSBeep();
    }

}


@end