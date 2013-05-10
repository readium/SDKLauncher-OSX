//
// Created by boriss on 2013-03-15.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class LOXToc;
@class LOXAppDelegate;
@class LOXTocEntry;
@class LOXePubSdkApi;
@class LOXPackage;


@interface LOXTocViewController : NSObject <NSOutlineViewDataSource, NSOutlineViewDelegate, NSTableViewDelegate> {

@private

    IBOutlet NSOutlineView * _outlineView;
    IBOutlet LOXAppDelegate* _appDelegate;
}


- (BOOL)isClickableItem:(LOXTocEntry *)item;
- (void)setPackage:(LOXPackage *)package;

@end