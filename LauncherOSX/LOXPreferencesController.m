//
//  LOXPreferencesController.m
//  LauncherOSX
//
//  Created by Boris Schneiderman on 2013-07-16.
//  Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//

#import "LOXPreferencesController.h"
#import "LOXPreferences.h"
#import "LOXSampleStylesProvider.h"
#import "LOXCSSStyle.h"
#import "LOXWebViewController.h"

@interface LOXPreferencesController ()
- (void)updateStylesUI;
@end

@implementation LOXPreferencesController {
    LOXPreferences *_preferences;
    LOXSampleStylesProvider *_stylesProvider;
}

- (IBAction)onClose:(id)sender
{
    [self closeSheet];
}

- (IBAction)onApplyStyle:(id)sender
{
    NSString *selector = [self.selectorsCtrl titleOfSelectedItem];

    if(selector) {
        LOXCSSStyle *style = [_stylesProvider styleForSelector:selector];
        [self.webViewController setStyle:style];
    }
}

- (IBAction)selectorSelected:(id)sender
{
    NSString *selector = [self.selectorsCtrl titleOfSelectedItem];

    if(selector) {
        LOXCSSStyle *style = [_stylesProvider styleForSelector:selector];
        [self.styleCtrl setString: style.content];

    }
}


- (void)showPreferences:(LOXPreferences *)preferences
{
    if(self.sheet) {
        return;
    }

    _preferences = preferences;
    [_preferences retain];


    //Make sure that in nib file "Visible at launch" property set to false
    //otherwise sheet il not be attached to the window
    [NSBundle loadNibNamed:@"PreferencesDlg" owner:self];

    [NSApp beginSheet:self.sheet
       modalForWindow:[[NSApp delegate] window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];

    [self updateStylesUI];

}

-(void)updateStylesUI
{
    [_stylesProvider release];
    _stylesProvider = [[LOXSampleStylesProvider alloc] init];
    [_stylesProvider retain];

    [self.selectorsCtrl removeAllItems];
    [self.selectorsCtrl addItemsWithTitles:[_stylesProvider selectors]];
    [self.selectorsCtrl selectItemAtIndex:0];

    [self selectorSelected: self];
}

- (void)closeSheet
{
    if(!self.sheet) {
        return;
    }

    [_preferences release];
    [NSApp endSheet:self.sheet];
    [self.sheet close];
    self.sheet = nil;
}


- (void)dealloc {
    [_preferences release];
    [_stylesProvider release];
    [super dealloc];
}


@end
