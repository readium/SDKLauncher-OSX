//
// Created by boriss on 2013-03-15.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class LOXToc;


@interface LOXTocViewController : NSObject <NSOutlineViewDataSource> {

@private

    IBOutlet NSOutlineView * _outlineView;
}


- (void)setToc:(LOXToc *)toc;


@end