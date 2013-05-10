//
//  LOXWebViewController.m
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

#import "LOXWebViewController.h"
#import "LOXePubSdkApi.h"
#import "LOXPageNumberTextController.h"
#import "LOXBookmarksController.h"
#import "LOXAppDelegate.h"
#import "LOXPackage.h"
#import "LOXSpine.h"
#import "LOXSpineItem.h"
#import "LOXCurrentPageData.h"


@interface LOXWebViewController ()

- (NSString *)loadHtmlTemplate;

- (void)updateUI;

@end

@implementation LOXWebViewController {

    LOXPackage *_package;
    NSString* _baseUrlPath;

}


- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPageChanged:)
                                                 name:LOXPageChangedEvent
                                               object:nil];

    NSString* html = [self loadHtmlTemplate];
    NSURL *baseUrl = [NSURL fileURLWithPath:_baseUrlPath];
    [[_webView mainFrame] loadHTMLString:html baseURL:baseUrl];
}

- (IBAction)onPrevPageClick:(id)sender
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript:@"ReadiumSDK.reader.movePrevPage()"];
}


- (IBAction)onNextPageClick:(id)sender
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript:@"ReadiumSDK.reader.moveNextPage()"];
}

-(NSString*) getCurrentPageCfi
{
    WebScriptObject* script = [_webView windowScriptObject];
    NSString* cfi = [script evaluateWebScript: @"ReadiumSDK.reader.getFirstVisibleElementCfi()"];
    return cfi;
}


- (NSString*) loadHtmlTemplate
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"reader" ofType:@"html" inDirectory:@"Scripts"];

    [_baseUrlPath release];
    _baseUrlPath = [path stringByDeletingLastPathComponent];
    [_baseUrlPath retain];

    NSString* htmlTemplate = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    if (!htmlTemplate){
        @throw [NSException exceptionWithName:@"Resource Exception" reason:@"Resourse reader.html not found" userInfo:nil];
    }

    return htmlTemplate;
}


-(void)openPackage:(LOXPackage *)package
{
    [_package release];
    _package = package;
    [_package retain];

    NSString* packageJSON = [_package toJSON];
    NSString* callString = [NSString stringWithFormat:@"ReadiumSDK.reader.setPackageData(%@)", packageJSON];
    [_webView stringByEvaluatingJavaScriptFromString:callString];
}

//-(int) getPageForElementCfi:(NSString*) cfi
//{
//    WebScriptObject* script = [_webView windowScriptObject];
//    NSString *callString = [NSString stringWithFormat:@"ReadiumSDK.reader.getPageForElementCfi(\"%@\")", cfi];
//    NSString* ret = [script evaluateWebScript:callString];
//
//    if ([ret isMemberOfClass:[WebUndefined class]]){
//        NSLog(@"cfi %@ not found", cfi);
//        return -1;
//    }
//
//    return [ret intValue];
//}


- (void)clear
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript: @"ReadiumSDK.reader.reset()"];
}


- (NSURLRequest *)webView:(WebView *)sender
                 resource:(id)identifier
          willSendRequest:(NSURLRequest *)request
         redirectResponse:(NSURLResponse *)redirectResponse
           fromDataSource:(WebDataSource *)dataSource
{

    NSString *path = request.URL.path;

    [_package prepareResourceWithPath: path];

    return request;
}

//this allows JavaScript to call the -logJavaScriptString: method
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if(    sel == @selector(onOpenPage:ofPages:spineItem:)
        || sel ==  @selector(onPaginationScriptingReady)) {

        return NO;
    }

    return YES;
}

//this returns a nice name for the method in the JavaScript environment
+(NSString*)webScriptNameForSelector:(SEL)sel
{
    if(sel == @selector(onOpenPage:ofPages:spineItem:)) {

        return @"onOpenPage";
    }
    else if (sel == @selector(onPaginationScriptingReady)) {

        return @"onPaginationScriptingReady";
    }

    return nil;
}


//this is called as soon as the script environment is ready in the webview
- (void)webView:(WebView *)sender didClearWindowObject:(WebScriptObject *)windowScriptObject forFrame:(WebFrame *)frame
{
    //add the controller to the script environment
    //the "Cocoa" object will now be available to JavaScript
    [windowScriptObject setValue:self forKey:@"LauncherUI"];
}

- (void)onOpenPage:(int)index ofPages:(int)count spineItem:(NSString*)idref
{
    [self.currentPageData setCurrentPage:index pageCount:count spineIdRef:idref];
    [self updateUI];
}


- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    NSLog(@"controlTextDidChange: stringValue == %@", [textField stringValue]);
}

- (void)updateUI
{
    [self.prevPageButton setEnabled:self.currentPageData.pageCount > 0 && self.currentPageData.pageIndex > 0];
    [self.nextPageButton setEnabled:self.currentPageData.pageCount > 0 && self.currentPageData.pageIndex < self.currentPageData.pageCount - 1];
}


//- (int)getPageForElementId:(NSString *)elementId
//{
//    WebScriptObject* script = [_webView windowScriptObject];
//    NSString *callString = [NSString stringWithFormat:@"ReadiumSDK.reader.getPageForElementId(\"%@\")", elementId];
//    NSString* ret = [script evaluateWebScript:callString];
//
//    if ([ret isMemberOfClass:[WebUndefined class]]){
//        NSLog(@"element id %@ not found", elementId);
//        return -1;
//    }
//
//    return [ret intValue];
//}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [_package release];
    [_baseUrlPath release];
    [super dealloc];

}

- (void)spineView:(LOXSpineViewController *)spineViewController selectionChangedTo:(LOXSpineItem *)spineItem
{
    [self openSpineItem:spineItem.idref elementCfi:@""];
}

- (void)openSpineItem:idref elementCfi:(NSString *)cfi
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript:[NSString stringWithFormat:@"ReadiumSDK.reader.openSpineItemElementCfi(\"%@\", \"%@\")", idref, cfi]];
}

- (void)openSpineItem:(NSString*)idref pageIndex:(int)pageIx
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript:[NSString stringWithFormat:@"ReadiumSDK.reader.openSpineItemPage(\"%@\", %d)", idref, pageIx]];
}

-(void)openContentUrl:(NSString *)contentRef fromSourceFileUrl:(NSString*) sourceRef
{
    WebScriptObject* script = [_webView windowScriptObject];

    NSString* sourceRefParam = sourceRef ? sourceRef : @"";

    [script evaluateWebScript:[NSString stringWithFormat:@"ReadiumSDK.reader.openContentUrl(\"%@\", \"%@\")", contentRef, sourceRefParam]];
}


@end
