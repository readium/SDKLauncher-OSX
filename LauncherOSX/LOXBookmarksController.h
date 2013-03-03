//
// Created by boriss on 2013-02-26.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class LOXBook;
@class LOXePubApi;
@class LOXAppDelegate;
@class LOXBookmarkEditController;
@class LOXBookmark;


@interface LOXBookmarksController : NSObject

@property (assign) IBOutlet NSMenu *bookmarksMenu;
@property (assign) IBOutlet LOXAppDelegate *mainController;
@property (assign) IBOutlet NSMenuItem *addBookmarkMenuItem;
@property (assign) IBOutlet LOXBookmarkEditController *bookmarkEditController;

-(void) setBook:(LOXBook*) book;

-(void)updateUI;

- (IBAction)addBookmark:(id)sender;

- (void) finishEditingBookmark:(LOXBookmark *)bookmark;

@end