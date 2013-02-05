//
// Created by boriss on 2013-02-04.
//
// To change the template use AppCode | Preferences | File Templates.
//


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