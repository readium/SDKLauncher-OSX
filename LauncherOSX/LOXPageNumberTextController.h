//
// Created by boriss on 2013-02-04.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class LOXWebViewController;

@interface LOXPageNumberTextController : NSObject <NSTextFieldDelegate> {


@private
    int _pageIx;
    int _pageCount;

}

@property (assign) IBOutlet LOXWebViewController* webViewController;
@property (assign) IBOutlet NSTextField *pageNumberCtrl;
@property (assign) IBOutlet NSTextField *pageCountCtrl;
@property (nonatomic, readonly) int pageIx;
@property (nonatomic, readonly) int pageCount;

- (void)setPageIndex:(int)index ofPages:(int)count;


@end