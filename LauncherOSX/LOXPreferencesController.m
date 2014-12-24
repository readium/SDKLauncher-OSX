//
//  LOXPreferencesController.m
//  LauncherOSX
//
//  Created by Boris Schneiderman on 2013-07-16.
//
//  Copyright (c) 2014 Readium Foundation and/or its licensees. All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice, this 
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  3. Neither the name of the organization nor the names of its contributors may be 
//  used to endorse or promote products derived from this software without specific 
//  prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
//  OF THE POSSIBILITY OF SUCH DAMAGE.

#import "LOXPreferencesController.h"
#import "LOXPreferences.h"
#import "LOXSampleStylesProvider.h"
#import "LOXCSSStyle.h"
#import "LOXWebViewController.h"
#import "LOXCSSParser.h"
#import "LOXUtil.h"

#import "LOXMediaOverlay.h"

#import "LOXWebViewController.h"
#import "LOXAppDelegate.h"


@interface LOXPreferencesController ()
- (LOXCSSStyle *)selectedStyle;

- (void)updateStylesUI;
@end

@implementation LOXPreferencesController {
    LOXPreferences *_preferences;
    LOXSampleStylesProvider *_stylesProvider;

    BOOL _postponeSettingsUpdate;
}

- (IBAction)onClose:(id)sender
{
    [self closeSheet];
}

- (IBAction)applySkippables:(id)sender
{
    NSString* str = [self.moSkippablesCtrl string];
    //[self.webViewController setMediaOverlaySkippables:str];
    
    [_preferences updateMediaOverlaysSkippables: str];
}

- (IBAction)resetSkippables:(id)sender
{
    NSString* list = [LOXMediaOverlay defaultSkippables];
    [self.moSkippablesCtrl setString:list];
    
    NSString* str = [NSString stringWithUTF8String:""];
    //[self.webViewController setMediaOverlaySkippables:str];
    
    [_preferences updateMediaOverlaysSkippables: str];
}

- (IBAction)applyEscapables:(id)sender
{
    NSString* str = [self.moEscapablesCtrl string];
    //[self.webViewController setMediaOverlayEscapables:str];
    
    [_preferences updateMediaOverlaysEscapables: str];
}

- (IBAction)onViewModeChanged:(id)sender {
    
    _postponeSettingsUpdate = YES;
    NSButtonCell *selCell = [sender selectedCell];
    switch([selCell tag])
    {
        case 1:
            self.preferences.scroll = @"scroll-doc";
            break;
        case 2:
            self.preferences.scroll = @"scroll-continuous";
            break;
        default:
            self.preferences.scroll = @"auto";
    }
    _postponeSettingsUpdate = NO;
    
    [self.preferences setDoNotUpdateView:NO];
    [self.webViewController updateSettings: self.preferences];
}


- (IBAction)onViewSynthChanged:(id)sender {
    
    _postponeSettingsUpdate = YES;
    NSButtonCell *selCell = [sender selectedCell];
    switch([selCell tag])
    {
        case 1:
            self.preferences.syntheticSpread = @"single";
            break;
        case 2:
            self.preferences.syntheticSpread = @"double";
            break;
        default:
            self.preferences.syntheticSpread = @"auto";
    }
    _postponeSettingsUpdate = NO;
    
    [self.preferences setDoNotUpdateView:NO];
    [self.webViewController updateSettings: self.preferences];
}

- (IBAction)resetEscapables:(id)sender
{
    NSString* list = [LOXMediaOverlay defaultEscapables];
    [self.moEscapablesCtrl setString:list];
    
    NSString* str = [NSString stringWithUTF8String:""];
    //[self.webViewController setMediaOverlayEscapables:str];

    [_preferences updateMediaOverlaysEscapables: str];
}

- (IBAction)onApplyStyle:(id)sender
{
    LOXCSSStyle *style = [self selectedStyle];
    if(!style) {
        return;
    }

    NSString* block = [self.styleCtrl string];
    NSError *error = NULL;
    NSDictionary *declarations = [LOXCSSParser parseDeclarationsString:block error:&error];

    if(error) {

        NSString* msg = [NSString stringWithFormat:@"Parsing error: %@", error.localizedDescription];
        [LOXUtil reportError:msg];

        return;
    }

    style.declarationsBlock = block;
    style.declarations = declarations;

    [self.webViewController setStyles:[NSArray arrayWithObject:style]];
}

-(LOXCSSStyle *)selectedStyle
{
    int ix = [self.selectorsCtrl indexOfSelectedItem];
    if(ix == -1) {
        return nil;
    }

    return [_stylesProvider styleForIndex:ix];
}

- (IBAction)selectorSelected:(id)sender
{
    LOXCSSStyle *style = [self selectedStyle];

    if(style) {
        [self.styleCtrl setString: style.declarationsBlock];;
    }
}

- (IBAction)clearStyles:(id)sender
{
    [self.webViewController resetStyles];
}


- (void)showPreferences:(LOXPreferences *)preferences
{
    if(self.sheet) {
        return;
    }

    _postponeSettingsUpdate = NO;

    _preferences = preferences;

    [_preferences registerChangeObserver:self];

    //Make sure that in nib file "Visible at launch" property set to false
    //otherwise sheet il not be attached to the window
    [NSBundle loadNibNamed:@"PreferencesDlg" owner:self];
    
    if([_preferences.scroll  isEqual: @"scroll-doc"]) {
        [self.displayModeCtrl selectCellWithTag: 1];
    }
    else if([_preferences.scroll isEqual: @"scroll-continuous"]) {
        [self.displayModeCtrl selectCellWithTag: 2];
    }
    else {
        [self.displayModeCtrl selectCellWithTag: 0];
    }
    
    if([_preferences.syntheticSpread  isEqual: @"single"]) {
        [self.displaySynthCtrl selectCellWithTag: 1];
    }
    else if([_preferences.syntheticSpread isEqual: @"double"]) {
        [self.displaySynthCtrl selectCellWithTag: 2];
    }
    else {
        [self.displaySynthCtrl selectCellWithTag: 0];
    }

    LOXAppDelegate* del = [self.webViewController appDelegate];

    [NSApp beginSheet:self.sheet
       modalForWindow:[del window]
        modalDelegate:self
       didEndSelector:nil
          contextInfo:nil];

    [self updateStylesUI];
    
    if ([[[_preferences mediaOverlaysSkippables] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
    {
        NSString* list1 = [LOXMediaOverlay defaultSkippables];
        [self.moSkippablesCtrl setString:list1];
    }
    else
    {
        [self.moSkippablesCtrl setString:[_preferences mediaOverlaysSkippables]];
    }
    
    if ([[[_preferences mediaOverlaysEscapables] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] isEqualToString:@""])
    {
        NSString* list2 = [LOXMediaOverlay defaultEscapables];
        [self.moEscapablesCtrl setString:list2];
    }
    else
    {
        [self.moEscapablesCtrl setString:[_preferences mediaOverlaysEscapables]];
    }


}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(!_postponeSettingsUpdate) {
        [_preferences setDoNotUpdateView:[_preferences isMediaOverlayProperty:keyPath]];
        [self.webViewController updateSettings:_preferences];
    }
}

-(void)updateStylesUI
{
    _stylesProvider = [[LOXSampleStylesProvider alloc] init];

    [self.selectorsCtrl removeAllItems];

    for(LOXCSSStyle *style in [_stylesProvider styles]) {
        [self.selectorsCtrl addItemWithTitle:style.selector];
    }

    [self.selectorsCtrl selectItemAtIndex:0];

    [self selectorSelected: self];

}

- (void)closeSheet
{
    if(!self.sheet) {
        return;
    }

    [_preferences removeChangeObserver: self];

    [NSApp endSheet:self.sheet];
    [self.sheet close];
    self.sheet = nil;
}



@end
