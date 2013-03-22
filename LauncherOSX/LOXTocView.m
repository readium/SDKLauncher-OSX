//
// Created by boriss on 2013-03-21.
//
// To change the template use AppCode | Preferences | File Templates.
//


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