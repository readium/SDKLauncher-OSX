//
//  LOXWebViewController.h
//  LauncherOSX
//
//  Created by Boris Schneiderman.
//  Copyright (c) 2012-2013 The Readium Foundation.
//
//  The Readium SDK is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import <WebKit/WebResourceLoadDelegate.h>

@class LOXePubApi;
@class LOXPageNumberTextController;
@class LOXBookmarksController;


@interface LOXWebViewController : NSObject {

@private
    IBOutlet WebView *_webView;
}

- (void)displayUrlPath:(NSString *)urlPath;

- (void) clear;

@property(nonatomic, retain) LOXePubApi *epubApi;

@property (assign) IBOutlet NSButton *prevPageButton;
@property (assign) IBOutlet NSButton *nextPageButton;

@property (assign) IBOutlet LOXPageNumberTextController *pageNumController;


- (void)displayHtml:(NSString *)html withBaseUrlPath:(NSString *)baseUrlPath;

- (IBAction)onPrevPageClick:(id)sender;
- (IBAction)onNextPageClick:(id)sender;

- (void)openPageIndex:(int)pageIx;


- (void)onOpenPageIndex:(int)index ofPages:(int)count;

@end
