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
#import "LOXPackage.h"
#import "LOXSpineItem.h"
#import "LOXCurrentPagesInfo.h"
#import "LOXBookmark.h"
#import "LOXPreferences.h"
#import "LOXAppDelegate.h"
#import "LOXCSSStyle.h"


@interface LOXWebViewController ()

-(void)onPageChanged:(NSNotification*) notification;

- (NSString *)loadHtmlTemplate;

- (void)updateSettings:(LOXPreferences *)preferences;

- (void)updateUI;

- (NSString *)toJson:(NSDictionary *)dict;
@end

@implementation LOXWebViewController {

    LOXPackage *_package;
    NSString* _baseUrlPath;
    LOXPreferences *_preferences;
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

-(void)onPageChanged:(NSNotification*) notification
{
    [self updateUI];
}

- (IBAction)onLeftPageClick:(id)sender
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript:@"ReadiumSDK.reader.openPageLeft()"];
}


- (IBAction)onRightPageClick:(id)sender
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript:@"ReadiumSDK.reader.openPageRight()"];
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


-(void)openPackage:(LOXPackage *)package onPage:(LOXBookmark*) bookmark
{
    [_package release];
    _package = package;
    [_package retain];

    NSString *packageJson = [self toJson:[_package toDictionary]];

    NSString* callString;

    if(bookmark) {
        NSDictionary *locationDict = [[[NSDictionary alloc] initWithObjectsAndKeys:bookmark.idref, @"idref", bookmark.contentCFI, @"elementCfi", nil] autorelease];
        NSString* jsonLocation = [self toJson:locationDict];
        callString = [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@,%@)", packageJson, jsonLocation];
    }
    else {
        callString = [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@)", packageJson];
    }

    [_webView stringByEvaluatingJavaScriptFromString:callString];
}

- (void)observePreferences:(LOXPreferences *)preferences
{
   [_preferences removeChangeObserver:self];
   [_preferences release];

    _preferences = preferences;
    [_preferences retain];
    [_preferences registerChangeObserver:self];

    [self updateSettings:_preferences];
}

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
    if( sel == @selector(onOpenPage:) || sel == @selector(onReaderInitialized) || sel == @selector(onSettingsApplied)) {

        return NO;
    }

    return YES;
}

//this returns a nice name for the method in the JavaScript environment
+(NSString*)webScriptNameForSelector:(SEL)sel
{
    if(sel == @selector(onOpenPage:)) {
        return @"onOpenPage";
    }
    else if(sel == @selector(onReaderInitialized)) {
        return @"onReaderInitialized";
    }
    else if(sel == @selector(onSettingsApplied)) {
        return @"onSettingsApplied";
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

- (void)onOpenPage:(NSString*) currentPaginationInfo
{

        NSData* data = [currentPaginationInfo dataUsingEncoding:NSUTF8StringEncoding];

        NSError *e = nil;
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];

        if (!dict) {
            NSLog(@"Error parsing JSON: %@", e);
        }
        else {

            [self.currentPagesInfo fromDictionary:dict];
            [[NSNotificationCenter defaultCenter] postNotificationName:LOXPageChangedEvent object:self];
        }
}

-(void)setStyle:(LOXCSSStyle *)style
{
    NSString* declarations = [self toJson:style.declarations];

    NSString* callString = [NSString stringWithFormat:@"ReadiumSDK.reader.setStyle(\"%@\",\"%@\")", style.selector, declarations];
    [_webView stringByEvaluatingJavaScriptFromString:callString];
}

- (void)onReaderInitialized
{
    [self updateSettings:_preferences];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == _preferences) {
        [self updateSettings:_preferences];
    }

}

-(void)updateSettings:(LOXPreferences *)preferences
{
    NSDictionary * dict = [preferences toDictionary];
    NSData* encodedData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
    NSString* jsonString = [[[NSString alloc] initWithData:encodedData encoding:NSUTF8StringEncoding] autorelease];

    NSString* callString = [NSString stringWithFormat:@"ReadiumSDK.reader.updateSettings(%@)", jsonString];
    [_webView stringByEvaluatingJavaScriptFromString:callString];
}


- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    NSLog(@"controlTextDidChange: stringValue == %@", [textField stringValue]);
}

- (void)updateUI
{
    [self.leftPageButton setEnabled:[self.currentPagesInfo canGoLeft]];
    [self.rightPageButton setEnabled:[self.currentPagesInfo canGoRight]];
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
    [_preferences removeChangeObserver:self];
    [_preferences release];

    [super dealloc];
}

- (void)spineView:(LOXSpineViewController *)spineViewController selectionChangedTo:(LOXSpineItem *)spineItem
{
    [self openSpineItem:spineItem.idref pageIndex:0];
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

- (void)openPage:(int)pageIndex
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript:[NSString stringWithFormat:@"ReadiumSDK.reader.openPageIndex(%d)", pageIndex]];
}

- (void)openContentUrl:(NSString *)contentRef fromSourceFileUrl:(NSString*) sourceRef
{
    WebScriptObject* script = [_webView windowScriptObject];

    NSString* sourceRefParam = sourceRef ? sourceRef : @"";

    [script evaluateWebScript:[NSString stringWithFormat:@"ReadiumSDK.reader.openContentUrl(\"%@\", \"%@\")", contentRef, sourceRefParam]];
}

-(LOXBookmark*) createBookmark
{

    WebScriptObject* script = [_webView windowScriptObject];
    NSString *callString = @"ReadiumSDK.reader.bookmarkCurrentPage()";
    NSString * bookmarkData = [script evaluateWebScript:callString];

    NSData* data = [bookmarkData dataUsingEncoding:NSUTF8StringEncoding];

    NSError *e = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];

    if (!dict) {
        NSLog(@"Error parsing JSON: %@", e);
        return nil;
    }

    LOXBookmark *bookmark = [[[LOXBookmark alloc] init] autorelease];

    bookmark.idref = dict[@"idref"];
    bookmark.contentCFI = dict[@"contentCFI"];

    return bookmark;
}

-(NSString *)toJson:(NSDictionary *)dict
{
    NSData* encodedData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];
    return [[[NSString alloc] initWithData:encodedData encoding:NSUTF8StringEncoding] autorelease];
}


-(void)onSettingsApplied
{
    NSLog(@"Settings has been applied to the reader");
}

@end
