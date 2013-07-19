//
//  LOXPreferencesController.h
//  LauncherOSX
//
//  Created by Boris Schneiderman on 2013-07-16.
//  Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LOXPreferences;

@interface LOXPreferencesController : NSObject

- (IBAction)onClose:(id)sender;

@property (assign) IBOutlet NSWindow *sheet;

@property(nonatomic, retain) LOXPreferences *preferences;

-(void) showPreferences:(LOXPreferences*)preferences;
-(void) closeSheet;

@end
