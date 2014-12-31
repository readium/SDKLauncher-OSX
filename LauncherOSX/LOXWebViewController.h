//
//  LOXWebViewController.h
//  LauncherOSX
//
//  Created by Boris Schneiderman.
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

#import <WebKit/WebKit.h>

#import "LOXSpineViewController.h"

#import <WebKit/WebResourceLoadDelegate.h>

@class LOXePubSdkApi;
@class LOXPageNumberTextController;
@class LOXBookmarksController;
@class LOXAppDelegate;
@class LOXPackage;
@class LOXCurrentPagesInfo;
@class LOXBookmark;
@class LOXPreferences;
@class LOXCSSStyle;
@class WebView;
@class PackageResourceServer;

@interface LOXWebViewController : NSObject<LOXSpineViewControllerDelegate> {

@private
    IBOutlet WebView *_webView;
    @private PackageResourceServer *m_resourceServer;
}
- (LOXPackage *) loxPackage;

- (void) clear;

- (void)onOpenPage:(NSString *)currentPaginationInfo canGoLeftRight:(NSString*) canGoLeftRight;

- (void)onMediaOverlayStatusChanged:(NSString*) status;

- (void)onMediaOverlayTTSSpeak:(NSString*) tts;
- (void)onMediaOverlayTTSStop;

- (bool)isMediaOverlayAvailable;

-(void)setStyles:(NSArray *)styles;

- (void)onReaderInitialized;

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;


@property (assign) IBOutlet NSButton *leftPageButton;
@property (assign) IBOutlet NSButton *rightPageButton;

@property (assign) IBOutlet LOXAppDelegate *appDelegate;

@property (nonatomic, strong) LOXCurrentPagesInfo *currentPagesInfo;


- (IBAction)onLeftPageClick:(id)sender;
- (IBAction)onRightPageClick:(id)sender;

- (void)openSpineItem:(id)idref elementCfi:(NSString *)cfi;

- (void)openSpineItem:(NSString *)idref pageIndex:(int)pageIx;

- (void)openPage:(int)pageIndex;

- (void)openContentUrl:(NSString *)contentRef fromSourceFileUrl:(NSString *)sourceRef;

- (LOXBookmark *)createBookmark;

- (NSString *)getCurrentPageCfi;

- (void)openPackage:(LOXPackage *)package onPage:(LOXBookmark*) bookmark;

- (void)resetStyles;

- (void)mediaOverlaysOpenContentUrl:(NSString *)contentRef fromSourceFileUrl:(NSString*) sourceRef forward:(double) offset;
- (void)toggleMediaOverlay;
- (void)nextMediaOverlay;
- (void)previousMediaOverlay;
- (void)escapeMediaOverlay;
- (void)ttsEndedMediaOverlay;

- (void)updateSettings:(LOXPreferences *)preferences;

@end
