//
//  LOXWebViewController.m
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

#import <WebKit/WebKit.h>
#import "LOXWebViewController.h"
#import "LOXPackage.h"
#import "LOXSpineItem.h"
#import "LOXCurrentPagesInfo.h"
#import "LOXBookmark.h"
#import "LOXPreferences.h"
#import "LOXAppDelegate.h"
#import "LOXCSSStyle.h"
#import "LOXUtil.h"
#import "LOXMediaOverlayController.h"
#import "PackageResourceServer.h"
#import "RDPackageResource.h"
#import <ePub3/utilities/byte_stream.h>


@interface LOXWebViewController ()

-(void)onPageChanged:(NSNotification*) notification;

// Now load file URL directly (no need for reader.html pre-processing)
//- (NSString *)loadHtmlTemplate;

- (void)updateUI;
- (void)updateWebView;

@end


@implementation LOXWebViewController {

    LOXPackage *_package;
    NSString* _baseUrlPath;
}


- (NSURLRequest *)webView:(WebView *)sender
                 resource:(id)identifier
          willSendRequest:(NSURLRequest *)request
         redirectResponse:(NSURLResponse *)redirectResponse
           fromDataSource:(WebDataSource *)dataSource
{
    if (request.URL == nil)
    {
        return request;
    }

    NSString *scheme = request.URL.scheme;

    if (scheme == nil)
    {
        return request;
    }

    NSString *path = request.URL.path;
    if (path == nil)
    {
        return request;
    }
    
    if ([path hasSuffix:@".map"]) {
    NSString* bundlePath = [[[NSBundle mainBundle] pathForResource:@"host_app_feedback" ofType:@"js" inDirectory:@"Scripts"] stringByDeletingLastPathComponent];
    NSString* slashPath = [NSString stringWithFormat:@"%@", [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    if ([slashPath hasPrefix:bundlePath]) {
        
        NSString * str = [[NSString stringWithFormat:@"file://%@", slashPath] stringByAddingPercentEscapesUsingEncoding : NSUTF8StringEncoding];
        NSURL *url = [NSURL URLWithString:str];
        
        NSMutableURLRequest *newRequest = [request mutableCopy];
        [newRequest setURL: url];
        
        return newRequest;
    }
    }

    // Fake script request, immediately invoked after epubReadingSystem hook is in place,
    // => push the global window.navigator.epubReadingSystem into the iframe(s)
    NSString * eprs = @"/readium_epubReadingSystem_inject";
    if ([path hasPrefix:eprs]) {

        // Previous method was fetching JS code directly from the "inject" script, but was I/O costly, and separation of concerns was not clear.
        // NSString *filePath = [[NSBundle mainBundle] pathForResource:@"epubReadingSystem_inject" ofType:@"js" inDirectory:@"Scripts"];
        // NSString *code = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];

        // Iterate top-level iframes, inject global window.navigator.epubReadingSystem if the expected hook function exists ( readium_set_epubReadingSystem() ).
        NSString* cmd = @"var epubRSInject = function(win) { if (win.frames) { for (var i = 0; i < win.frames.length; i++) { var iframe = win.frames[i]; try { if (iframe.readium_set_epubReadingSystem) { iframe.readium_set_epubReadingSystem(window.navigator.epubReadingSystem); } epubRSInject(iframe); } catch(err) { console.log(err); } } } }; epubRSInject(window);";

        // does not work as expected:
        // WebScriptObject* script = [sender windowScriptObject];
        // [script evaluateWebScript:cmd];

        [_webView stringByEvaluatingJavaScriptFromString:cmd];

        return nil;
    }

    NSString * math = @"/readium_MathJax.js";
    if ([path hasPrefix:math]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"MathJax" ofType:@"js" inDirectory:@"Scripts/mathjax"];
        NSString * str = [[NSString stringWithFormat:@"file://%@", filePath] stringByAddingPercentEscapesUsingEncoding : NSUTF8StringEncoding];
        NSURL *url = [NSURL URLWithString:str];

        NSMutableURLRequest *newRequest = [request mutableCopy];
        [newRequest setURL: url];

        return newRequest;
    }

    NSString * annotationsCSS = @"/readium_Annotations.css";
    if ([path hasPrefix:annotationsCSS]) {
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"annotations" ofType:@"css" inDirectory:@"Scripts"];
        NSString * str = [[NSString stringWithFormat:@"file://%@", filePath] stringByAddingPercentEscapesUsingEncoding : NSUTF8StringEncoding];
        NSURL *url = [NSURL URLWithString:str];

        NSMutableURLRequest *newRequest = [request mutableCopy];
        [newRequest setURL: url];

        return newRequest;
    }
    
    NSComparisonResult schemeFile = [scheme caseInsensitiveCompare: @"file"];

    NSString * folder = [_baseUrlPath stringByDeletingLastPathComponent];

    NSString * prefix1 = [NSString stringWithFormat:@"http://127.0.0.1:%d", [m_resourceServer serverPort]];

    //NSString * prefix2 = [NSString stringWithFormat:@"%@%@", prefix1, folder];
    //[path substringFromIndex: [path rangeOfString:prefix1].location]


    if (schemeFile != NSOrderedSame && [path hasPrefix:folder]) {
        NSString * str = [[NSString stringWithFormat:@"file://%@", path] stringByAddingPercentEscapesUsingEncoding : NSUTF8StringEncoding];
        NSURL *url = [NSURL URLWithString:str];

        NSMutableURLRequest *newRequest = [request mutableCopy];
        [newRequest setURL: url];

        return newRequest;
    }

    if (schemeFile != NSOrderedSame)
    {
        return request;
    }

    if (_package == nil)
    {
        return request;
    }

    if ([path hasPrefix:@"/"]) {
        path = [path substringFromIndex:1];
    }

    NSString *query = request.URL.query;
    if (query != nil)
    {
        path = [NSString stringWithFormat:@"%@?%@", path, query];
    }
    NSString *fragment = request.URL.fragment;
    if (fragment != nil)
    {
        path = [NSString stringWithFormat:@"%@#%@", path, fragment];
    }

    NSString * str = [[NSString stringWithFormat:@"%@/%@/%@", prefix1, _package.packageUUID, path] stringByAddingPercentEscapesUsingEncoding : NSUTF8StringEncoding];
    NSURL *url = [NSURL URLWithString:str];

    NSMutableURLRequest *newRequest = [request mutableCopy];
    [newRequest setURL: url];

    return newRequest;
}

- (LOXPackage *) loxPackage
{
    return _package;
}

- (void)awakeFromNib
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

    [nc addObserver:self
                                             selector:@selector(onPageChanged:)
                                                 name:LOXPageChangedEvent
                                               object:nil];

    // Now load file URL directly (no need for reader.html pre-processing)
    //NSString* html = [self loadHtmlTemplate];
    //NSURL *baseUrl = [NSURL fileURLWithPath:_baseUrlPath];
    //[[_webView mainFrame] loadHTMLString:html baseURL:baseUrl];


    //NSURL *url = [[NSBundle mainBundle] URLForResource:@"reader.html" withExtension:nil];

    NSString* readerFileName = @"reader_RequireJS-multiple-bundles";
    //NSString* readerFileName = @"reader_RequireJS-single-bundle";
    
    
    // The "no optimize" RequireJS option means that the entire "readium-shared-js" folder must be copied in to the OSX app bundle's "scripts" folder! (including "node_modules" subfolder, which is populated when invoking the "npm run prepare" build command) There is therefore some significant filesystem / size overhead, but the benefits are significant too: no need for the WebView to fetch sourcemaps, and to attempt to un-mangle the obfuscated Javascript during debugging.
    // However, the recommended development-time pattern is to invoke "npm run build" in order to refresh the "build-output" folder, with the RJS_UGLY environment variable set to "false" or "no". This way, the RequireJS single/multiple bundle(s) will be in readable uncompressed form.
    //NSString* readerFileName = @"reader_RequireJS-no-optimize";
    
    NSString* path = [[NSBundle mainBundle] pathForResource:readerFileName ofType:@"html" inDirectory:@"Scripts"];

    //_baseUrlPath = [path stringByDeletingLastPathComponent];
    _baseUrlPath = path;

    NSURL *url = [NSURL fileURLWithPath:_baseUrlPath];

    // See enableGPUHardwareAccelerationCSS3D in LOXPreferences@toDictionary(), and updateWebView() below

    [[_webView mainFrame] loadRequest:[NSURLRequest requestWithURL:url]];
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

// Now load file URL directly (no need for reader.html pre-processing)
/*
- (NSString*) loadHtmlTemplate
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"reader" ofType:@"html" inDirectory:@"Scripts"];

    //_baseUrlPath = [path stringByDeletingLastPathComponent];
    _baseUrlPath = path;

    NSString* htmlTemplate = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    if (!htmlTemplate){
        @throw [NSException exceptionWithName:@"Resource Exception" reason:@"Resourse reader.html not found" userInfo:nil];
    }

    return htmlTemplate;
}
*/

-(void)openPackage:(LOXPackage *)package onPage:(LOXBookmark*) bookmark
{
    _package = package;

    m_resourceServer = nil;
    m_resourceServer = [[PackageResourceServer alloc] initWithPackage:package baseUrlPath:_baseUrlPath];

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setObject:[_package toDictionary] forKey:@"package"];

    if(bookmark) {
        NSDictionary *locationDict = [[NSDictionary alloc] initWithObjectsAndKeys:bookmark.idref, @"idref", bookmark.contentCFI, @"elementCfi", nil];
        [dict setObject:locationDict forKey:@"openPageRequest"];
    }

    NSString *json = [LOXUtil toJson:dict];
    //NSLog(@"%@", json);

    NSString* callString = [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@)", json];

    [_webView stringByEvaluatingJavaScriptFromString:callString];
}

- (void)clear
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript: @"ReadiumSDK.reader.reset()"];
}


//this allows JavaScript to call the -logJavaScriptString: method
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if(        sel == @selector(onOpenPage:canGoLeftRight:)
            || sel == @selector(onReaderInitialized)
            || sel == @selector(onSettingsApplied)
            || sel == @selector(onMediaOverlayStatusChanged:)
            || sel == @selector(onMediaOverlayTTSSpeak:)
            || sel == @selector(onMediaOverlayTTSStop)
            ){

        return NO;
    }

    return YES;
}

//this returns a nice name for the method in the JavaScript environment
+(NSString*)webScriptNameForSelector:(SEL)sel
{
    if(sel == @selector(onOpenPage:canGoLeftRight:)) {
        return @"onOpenPage";
    }
    else if(sel == @selector(onReaderInitialized)) {
        return @"onReaderInitialized";
    }
    else if(sel == @selector(onSettingsApplied)) {
        return @"onSettingsApplied";
    }
    else if(sel == @selector(onMediaOverlayStatusChanged:)) {
        return @"onMediaOverlayStatusChanged";
    }
    else if(sel == @selector(onMediaOverlayTTSSpeak:)) {
        return @"onMediaOverlayTTSSpeak";
    }
    else if(sel == @selector(onMediaOverlayTTSStop)) {
        return @"onMediaOverlayTTSStop";
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

- (void)onOpenPage:(NSString*) currentPaginationInfo canGoLeftRight:(NSString*) canGoLeftRight
{

    NSData* data = [currentPaginationInfo dataUsingEncoding:NSUTF8StringEncoding];

    NSError *e = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];

    if (e) {
        NSLog(@"Error parsing JSON: %@", e);
        return;
    }

    data = nil;
    data = [canGoLeftRight dataUsingEncoding:NSUTF8StringEncoding];

    e = nil;
    NSDictionary *dictCanGoLeftRight = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];

    if (e) {
        NSLog(@"Error parsing JSON: %@", e);
        return;
    }

    BOOL canGoLeft = ([[dictCanGoLeftRight valueForKey:@"canGoLeft"] isEqual:[NSNumber numberWithBool:YES]] ? YES : NO);
    BOOL canGoRight = ([[dictCanGoLeftRight valueForKey:@"canGoRight"] isEqual:[NSNumber numberWithBool:YES]] ? YES : NO);

    [self.currentPagesInfo fromDictionary:dict canGoLeft:canGoLeft canGoRight:canGoRight];
    [[NSNotificationCenter defaultCenter] postNotificationName:LOXPageChangedEvent object:self];
}

- (void)onMediaOverlayTTSStop
{
    [[NSNotificationCenter defaultCenter] postNotificationName:LOXMediaOverlayTTSStopEvent object:self userInfo:nil];
}

- (void)onMediaOverlayTTSSpeak:(NSString*) tts
{
    NSData* data = [tts dataUsingEncoding:NSUTF8StringEncoding];

    NSError *e = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];

    if (e) {
        NSLog(@"Error parsing JSON: %@", e);
        return;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:LOXMediaOverlayTTSSpeakEvent object:self userInfo:dict];
}

- (void)onMediaOverlayStatusChanged:(NSString*) status
{
    NSData* data = [status dataUsingEncoding:NSUTF8StringEncoding];

    NSError *e = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];

    if (e) {
        NSLog(@"Error parsing JSON: %@", e);
        return;
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:LOXMediaOverlayStatusChangedEvent object:self userInfo:dict];
}

-(bool)isMediaOverlayAvailable
{
    NSString* callString = @"ReadiumSDK.reader.isMediaOverlayAvailable()";

    NSString *result = [_webView stringByEvaluatingJavaScriptFromString:callString];

    return [result boolValue];
}

-(void)setStyles:(NSArray *)styles
{
    NSMutableArray *arr = [NSMutableArray array];

    for(LOXCSSStyle *style in styles) {
        [arr addObject:[style toDictionary]];
    }

    NSString* jsonDecl = [LOXUtil toJson: arr];
    //NSLog(@"%@", jsonDecl);

    NSString* callString = [NSString stringWithFormat:@"ReadiumSDK.reader.setStyles(%@)", jsonDecl];
    [_webView stringByEvaluatingJavaScriptFromString:callString];
}

- (void)onReaderInitialized
{
    [self.appDelegate onReaderInitialized];
}


-(void)updateSettings:(LOXPreferences *)preferences
{
    [[self.appDelegate mediaOverlayController] updateSettings: preferences];

    NSString *jsonString = [LOXUtil toJson:[preferences toDictionary]];
    //NSLog(@"%@", jsonString);

    NSString* callString = [NSString stringWithFormat:@"ReadiumSDK.reader.updateSettings(%@)", jsonString];
    [_webView stringByEvaluatingJavaScriptFromString:callString];
}


- (void)controlTextDidChange:(NSNotification *)notification {
    NSTextField *textField = [notification object];
    NSLog(@"controlTextDidChange: stringValue == %@", [textField stringValue]);
}

/*
This was used to attempt to debunk the CSS 3D rendering issues (clipping, non-interactive text and video/audio controls)

- (void)updateWebView
{
    NSLog(@"========");

    WebFrame *mainFrame = [_webView mainFrame];
    WebFrameView *mainFrameView = [mainFrame frameView];
    NSView<WebDocumentView> *const mainFrameDocView = [mainFrameView documentView]; //WebHTMLView
    NSScrollView *mainFrameScrollView = [mainFrameDocView enclosingScrollView]; //WebDynamicScrollBarsView
    NSClipView *mainFrameClipView = [mainFrameScrollView contentView]; //WebClipView

    //setContentMode:NSViewContentModeRedraw
    //[mainFrameView setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawNever];

    NSLog(@"%d", [mainFrameView layerContentsRedrawPolicy]); //2 => NSViewLayerContentsRedrawDuringViewResize

    CALayer* mainFrameView_layer = [mainFrameView layer];
    CALayer* mainFrameDocView_layer = [mainFrameDocView layer];
    CALayer* mainFrameScrollView_layer = [mainFrameScrollView layer];
    CALayer* mainFrameClipView_layer = [mainFrameClipView layer];

    NSLog(@"%@", mainFrameView_layer);
    NSLog(@"%@", mainFrameDocView_layer);
    NSLog(@"%@", mainFrameScrollView_layer);
    NSLog(@"%@", mainFrameClipView_layer);

    for (WebFrame * childFrame in [[_webView mainFrame] childFrames])
    {
        WebFrameView *childFrameView = [childFrame frameView];
        NSView<WebDocumentView> *const childFrameDocView = [childFrameView documentView]; //WebHTMLView
        NSScrollView *childFrameScrollView = [childFrameDocView enclosingScrollView]; //WebDynamicScrollBarsView
        NSClipView *childFrameClipView = [childFrameScrollView contentView]; //WebClipView

        //[childFrameView setWantsLayer:YES];
        //[childFrameView scaleUnitSquareToSize: NSMakeSize(0.999, 0.999)];

        NSLog(@"----");

        NSLog(@"%d", [childFrameView layerContentsRedrawPolicy]); //2 => NSViewLayerContentsRedrawDuringViewResize

        CALayer* childFrameView_layer = [childFrameView layer];
        CALayer* childFrameDocView_layer = [childFrameDocView layer];
        CALayer* childFrameScrollView_layer = [childFrameScrollView layer];
        CALayer* childFrameClipView_layer = [childFrameClipView layer];

        NSLog(@"%@", childFrameView_layer);
        NSLog(@"%@", childFrameDocView_layer);
        NSLog(@"%@", childFrameScrollView_layer);
        NSLog(@"%@", childFrameClipView_layer);

        //[view setWantsLayer:YES];

        //[view setNeedsLayout:YES];

        //[view setNeedsDisplay:YES];
    }
}
*/

- (void)updateUI
{
    [self.leftPageButton setEnabled:[self.currentPagesInfo canGoLeft]];
    [self.rightPageButton setEnabled:[self.currentPagesInfo canGoRight]];

//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self updateWebView];
//    });
    //[self.appDelegate performSelectorOnMainThread:@selector(updateWebView) withObject:nil waitUntilDone:YES];
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

    LOXBookmark *bookmark = [[LOXBookmark alloc] init];

    bookmark.idref = dict[@"idref"];
    bookmark.contentCFI = dict[@"contentCFI"];

    return bookmark;
}


-(void)onSettingsApplied
{
    NSLog(@"Settings has been applied to the reader");
}

- (void)resetStyles
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript: @"ReadiumSDK.reader.clearStyles()"];
}


- (void)mediaOverlaysOpenContentUrl:(NSString *)contentRef fromSourceFileUrl:(NSString*) sourceRef forward:(double) offset
{
    WebScriptObject* script = [_webView windowScriptObject];

    NSString* sourceRefParam = sourceRef ? sourceRef : @"";

    [script evaluateWebScript:[NSString stringWithFormat:@"ReadiumSDK.reader.mediaOverlaysOpenContentUrl(\"%@\", \"%@\", %f)", contentRef, sourceRefParam, offset]];
}

- (void)toggleMediaOverlay
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript: @"ReadiumSDK.reader.toggleMediaOverlay()"];
}

- (void)nextMediaOverlay
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript: @"ReadiumSDK.reader.nextMediaOverlay()"];
}
- (void)previousMediaOverlay
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript: @"ReadiumSDK.reader.previousMediaOverlay()"];
}
- (void)escapeMediaOverlay
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript: @"ReadiumSDK.reader.escapeMediaOverlay()"];
}
- (void)ttsEndedMediaOverlay
{
    WebScriptObject* script = [_webView windowScriptObject];
    [script evaluateWebScript: @"ReadiumSDK.reader.ttsEndedMediaOverlay()"];
}

@end
