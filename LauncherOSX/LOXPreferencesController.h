//
//  LOXPreferencesController.h
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

#import <Foundation/Foundation.h>

@class LOXPreferences;
@class LOXWebViewController;

@interface LOXPreferencesController : NSObject

- (IBAction)onClose:(id)sender;
- (IBAction)onApplyStyle:(id)sender;
- (IBAction)selectorSelected:(id)sender;
- (IBAction)clearStyles:(id)sender;
- (IBAction)resetSkippables:(id)sender;
- (IBAction)resetEscapables:(id)sender;
- (IBAction)applySkippables:(id)sender;
- (IBAction)applyEscapables:(id)sender;
- (IBAction)onViewModeChanged: (id)sender;
- (IBAction)onViewSynthChanged: (id)sender;

@property (assign) IBOutlet NSButton *thiteticSpread;
@property (assign) IBOutlet NSWindow *sheet;

@property (assign) IBOutlet NSPopUpButton *selectorsCtrl;
@property (assign) IBOutlet NSTextView *styleCtrl;
@property (assign) IBOutlet NSTextView *moSkippablesCtrl;
@property (assign) IBOutlet NSTextView *moEscapablesCtrl;

@property (assign) IBOutlet NSMatrix *displayModeCtrl;
@property (assign) IBOutlet NSMatrix *displaySynthCtrl;

@property(nonatomic, strong) LOXPreferences *preferences;
@property(nonatomic, strong) LOXWebViewController *webViewController;

-(void) showPreferences:(LOXPreferences*)preferences;
-(void) closeSheet;

@end
