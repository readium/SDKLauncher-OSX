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


#import "LOXTocView.h"
#import "LOXTocViewController.h"
#import "LOXTocEntry.h"


@implementation LOXTocView {

}

- (void)resetCursorRects
{
    LOXTocViewController* controller = (LOXTocViewController *)[self delegate];

    NSInteger rows = [self numberOfRows];
    NSInteger cols = [self numberOfColumns];

    for (NSInteger row = 0; row < rows; row++) {
        for (NSInteger col = 0; col < cols; col ++) {

            LOXTocEntry *item = (LOXTocEntry *) [self itemAtRow:row];
            if([controller isClickableItem:item]) {
                NSRect rect = [self frameOfCellAtColumn:col row:row];
                [self addCursorRect:rect cursor:[NSCursor pointingHandCursor]];
            }
        }
    }

}

@end