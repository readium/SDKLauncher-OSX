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

#import <ePub3/utilities/byte_stream.h>

#import "LOXTemporaryFileStorage.h"


@interface LOXWebViewController ()

-(void)onPageChanged:(NSNotification*) notification;

- (NSString *)loadHtmlTemplate;

- (void)updateSettings:(LOXPreferences *)preferences;

- (void)updateUI;

@end

@interface ReadiumNSURLProtocol : NSURLProtocol //<NSURLConnectionDataDelegate> //NSURLConnectionDelegate
{

}

+ (void) package:(LOXPackage *)package;

@end


@interface ReadiumNSURLProtocol ()
    //@property (nonatomic, strong) NSURLConnection *connexion;
    //@property (retain) NSURLConnection *connexion;
@end



@implementation ReadiumNSURLProtocol

static NSDictionary *_mimeExtensions;
+ (void) initialize;
{
    if (_mimeExtensions == nil)
    {
        NSLog(@"INIT MIMETYPES");
        _mimeExtensions=[[NSDictionary alloc] initWithObjectsAndKeys:
//            @"image/jpeg", @"jpeg",
//            @"image/jpeg", @"jpg",
//            @"image/tiff", @"tiff",
//            @"image/png", @"png",
//                    @"image/gif", @"gif",
                    @"video/ogg", @"ogv",
                    @"video/mov", @"mov",
                    @"video/webm", @"webm",
                    @"audio/mpeg", @"mp3",
                        @"audio/mp4", @"mp4",
//                    @"audio/wav", @"wav",
//            @"text/css", @"css",
//                    @"text/html", @"html",
//                    @"text/html", @"xhtml",
//                        @"text/xml", @"xml",
//                        @"text/svg", @"svg",
            nil];
    }
}

+ (NSDictionary *) mimeExtensions
{
    return _mimeExtensions;
}

LOXPackage * _package;

+ (void) package:(LOXPackage *)package
{
    _package = package;
}
//
//static NSMutableSet *requests = nil;
//
//+ (NSMutableSet *)requests
//{
//    return [[requests retain] autorelease];
//}
//
//+ (void)setRequests:(NSMutableSet *)newRequests
//{
//    if ( requests != newRequests ) {
//        [requests release];
//        requests = [newRequests retain];
//    }
//}
//
//+ (BOOL)hasRequest:(NSURLRequest *)request
//{
//    return [requests containsObject:request];
//}
//
//+ (void)addRequest:(NSURLRequest *)request
//{
//    //  lazily instantiate set
//    if ( requests == nil )
//        [[self class] setRequests:[NSMutableSet set]];
//
//    //  add request
//    [requests addObject:request];
//}
//
//+ (void)removeRequest:(NSURLRequest *)request
//{
//    //  remove request
//    [requests removeObject:request];
//
//    //  minimize memory footprint
//    if ( [requests count] == 0 )
//        [[self class] setRequests:nil];
//}
//
//-(id)initWithRequest:(NSURLRequest *)request
//      cachedResponse:(NSCachedURLResponse *)cachedResponse client:(id
//<NSURLProtocolClient>)client
//{
//    //  call super
//    self = [super initWithRequest:request
//                   cachedResponse:cachedResponse
//                           client:client];
//
//    if ( self ) {
//        //  register the request
//        [[self class] addRequest:request];
//    }
//    return self;
//}
//
//- (void)dealloc
//{
//    //  unregister the request
//    [[self class] removeRequest:[self request]];
//    [super dealloc];
//}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request
{
    //NSString *path = request.URL.path;
//
//    if ( [[self class] hasRequest:request] )
//    {
//        //NSLog(@"init NO %@", path);
//        return NO;
//    }

    auto yep = [NSURLProtocol propertyForKey:@"READIUM" inRequest:request];
    if (yep)
    {
        NSLog(@"init YES %@", request.URL);
        return YES;
    }

//
//    if ([request.URL.scheme caseInsensitiveCompare: @"readium"] == NSOrderedSame)
//    {
//        return YES;
//    }

    NSLog(@"init NO %@", request.URL);
    return NO;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request{
    return request;
}

- (void)startLoading
{
    //NSMutableURLRequest *newRequest = [self.request mutableCopy];
    //[newRequest setValue:@"Mozilla/5.0 (Windows NT 6.2; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.2 Safari/537.36 Kifi/1.0f" forHTTPHeaderField:@"User-Agent"];
    //[NSURLProtocol setProperty:@YES forKey:@"UserAgentSet" inRequest:newRequest];

//    NSURLConnectionDelegate *delegate = [[[NSURLConnectionDelegate alloc]
//            initWithSuccessHandler:^(NSData *response) {
//                // …
//            }] autorelease];


    NSLog(@"Main thread %@", ([NSThread isMainThread] ? @"Yes" : @" No"));
//
//    id connection = [[NSURLConnection alloc] initWithRequest:[self request]
//                                                    delegate:self startImmediately:NO];
//    //self.connexion = [connection autorelease];
//    self.connexion = connection;

//    NSURLConnection *conn = [[[NSURLConnection alloc] initWithRequest:self.request delegate:self] autorelease];
//
//    self.connexion = [NSURLConnection connectionWithRequest:self.request delegate:self];
//    [self.connexion start];


    NSString *path = self.request.URL.path;
    NSLog(@"startLoading %@", path);

//    NSURL *fileUrl = [NSURL fileURLWithPath:path];
//    NSURLRequest *theFileReq = [[[NSURLRequest alloc] initWithURL:fileUrl cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:0.01]autorelease];
//    NSURLResponse *response = nil;
//    NSError *error = nil;
//    NSData *data = [NSURLConnection sendSynchronousRequest:theFileReq returningResponse:&response error:&error];
//    if (error != nil)
//    {
//        NSLog(@"error %@", error);
//    }
//    if (response != nil)
//    {
//        NSString *mimeType = [response MIMEType];
//        NSLog(@"mimeType %@", mimeType);
//    }

//
//    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:self.request.URL
//                                                  cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:2.0];
//
////    NSURLConnection *conn = [NSURLConnection connectionWithRequest:request delegate:self];
//
//    NSURLConnection * con = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately: NO];
//
//    //[con scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
//    //[con scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//
//    [con start];
//
//    [request release];


    NSString * relativePath = [[_package storage] relativePathFromFullPath: path];
    std::string str([relativePath UTF8String]);

    std::unique_ptr<ePub3::ByteStream> byteStream = [_package sdkPackage]->ReadStreamForRelativePath([_package sdkPackage]->BasePath() + str);
    if(byteStream == NULL)
    {
        NSLog(@"No archive found for path %@", relativePath);
        [[self client] URLProtocolDidFinishLoading:self];
        [self stopLoading];
        return;
    }


    //NSInteger* length = [NSInteger numberWithInt: byteStream->BytesAvailable()];
    ssize_t length = byteStream->BytesAvailable();

    NSLog(@"BYTES: %d", length);

    auto ext = [[relativePath pathExtension] lowercaseString];

    auto mime = [_mimeExtensions objectForKey:ext];
    if (mime == nil)
    {
        mime = @"text/html";
    }

    NSURLResponse *response_ =[[NSURLResponse alloc] initWithURL:self.request.URL
                                                      MIMEType: mime
                                         expectedContentLength: length
                                              textEncodingName:nil];

    [[self client] URLProtocol:self didReceiveResponse:response_ cacheStoragePolicy:NSURLCacheStorageNotAllowed];

//    if ([ext caseInsensitiveCompare: @"mp3"] == NSOrderedSame
//            || [ext caseInsensitiveCompare: @"mp4"] == NSOrderedSame)
//    {
//        [[self client] URLProtocol:self didReceiveResponse:response_ cacheStoragePolicy:NSURLCacheStorageAllowed];
//    }
//    else
//    {
//        [[self client] URLProtocol:self didReceiveResponse:response_ cacheStoragePolicy:NSURLCacheStorageNotAllowed];
//    }


    uint8_t buffer[1024];
    ssize_t readBytes = 0;
    ssize_t sumBytes = 0;
    while ((readBytes  = byteStream->ReadBytes(buffer, 1024)) > 0)
    {
        sumBytes+=readBytes;
        [[self client] URLProtocol:self didLoadData: [NSData dataWithBytes: buffer length: readBytes]];
    }
    byteStream->Close();

    NSLog(@"BYTESUM: %d", sumBytes);

    [self.client URLProtocolDidFinishLoading:self];
}

- (void)stopLoading
{
    NSLog(@"STOP LOAD");

    //[self.connexion cancel];
    //self.connexion = nil;

//    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
//    [NSURLCache setSharedURLCache:sharedCache];
//    [sharedCache release];
}
//
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
//{
//    NSLog(@"didReceiveResponse");
//
//    //[self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
//
////    NSString *path = self.request.URL.path;
////    NSLog(@"didReceiveResponse %@", path);
//
//    //NSString *mime = [response MIMEType];
//    //int length_ = [response expectedContentLength];
//}
//
//
//- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
//{
//    //NSLog(@"FAIL");
//    NSLog(@"FAIL %@", error);
//
//    //[self.client URLProtocol:self didFailWithError:error];
//    //self.connection = nil;
//}
//
//
//- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
//{
//    return nil;
//}
//
///*
//-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
//{
//    [self.client URLProtocol:self didLoadData:data];
//}
//
//
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection
//{
//    [self.client URLProtocolDidFinishLoading:self];
//    self.connection = nil;
//}
//*/

@end


@implementation LOXWebViewController {

    LOXPackage *_package;
    NSString* _baseUrlPath;
    LOXPreferences *_preferences;
}

- (NSURLRequest *)webView:(WebView *)sender
                 resource:(id)identifier
          willSendRequest:(NSURLRequest *)request
         redirectResponse:(NSURLResponse *)redirectResponse
           fromDataSource:(WebDataSource *)dataSource
{

//    NSString *path_ = request.URL.path;
//    //NSString *path_ = [[request URL] path];
//    [_package prepareResourceWithPath: path_];
//    return request;








    for(NSString *s in [dataSource subresources])
    {
        NSLog(@"resource : %@",s);
    }

    if (_package == nil)
    {
        NSLog(@"PACK NULL %@", request.URL);
        return request;
    }
//
//    if ([request.URL.scheme caseInsensitiveCompare: @"readium"] == NSOrderedSame)
//    {
//        NSLog(@"READIUM %@", request.URL);
//        return request;
//    }
//

    bool isFileScheme = [request.URL.scheme caseInsensitiveCompare: @"file"] == NSOrderedSame;
    bool isReadiumScheme = [request.URL.scheme caseInsensitiveCompare: @"readium"] == NSOrderedSame;
    if (!isFileScheme
            && !isReadiumScheme)
    {
        NSLog(@"NOT FILE %@", request.URL);
        return request;
    }

    NSString *path = request.URL.path;
    //NSString *path = [[request URL] path];


    NSLog(@"willSendRequest? %@", request.URL);

    NSString * relativePath = [[_package storage] relativePathFromFullPath: path];
    std::string rel([relativePath UTF8String]);

    bool can = [_package sdkPackage]->CanReadStreamForRelativePath([_package sdkPackage]->BasePath() + rel);
    if (!can)
    {
        NSLog(@"NOT CAN %@", request.URL);

        NSString * str = [@"file://" stringByAppendingString:path];
        NSURL *url = [NSURL URLWithString:str];
        auto req = [NSURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval: 5];

        return req;
    }


    auto ext = [[relativePath pathExtension] lowercaseString];

    auto mime = [[ReadiumNSURLProtocol mimeExtensions] objectForKey:ext];

    if (mime == nil)
    {
        NSLog(@"-- TEMP RES %@", path);

        [_package prepareResourceWithPath: path];

        NSString * str = [@"file://" stringByAppendingString:path];
        NSURL *url = [NSURL URLWithString:str];
        auto req = [NSURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageAllowed timeoutInterval: 5];

        return req;
    }

    NSLog(@"ReadIum %@", request.URL);

    //NSURLRequest *theFileReq = [[[NSURLRequest alloc] initWithURL:fileUrl cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval:0.01]autorelease];


    NSString * str = [@"readium://" stringByAppendingString:path];

    NSLog(@"----- willSendRequest %@", str);

    NSURL *url = [NSURL URLWithString:str];
    auto req = [NSURLRequest requestWithURL:url cachePolicy:NSURLCacheStorageNotAllowed timeoutInterval: 5];

    [NSURLProtocol setProperty:@YES forKey:@"READIUM" inRequest: req];
    return req;
}

- (LOXPackage *) loxPackage
{
    return _package;
}

- (void)awakeFromNib
{
    [NSURLProtocol registerClass:[ReadiumNSURLProtocol class]];

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

    [ReadiumNSURLProtocol package:_package];

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setObject:[_package toDictionary] forKey:@"package"];

    if(bookmark) {
        NSDictionary *locationDict = [[[NSDictionary alloc] initWithObjectsAndKeys:bookmark.idref, @"idref", bookmark.contentCFI, @"elementCfi", nil] autorelease];
        [dict setObject:locationDict forKey:@"openPageRequest"];
    }

    NSString *json = [LOXUtil toJson:dict];
    //NSLog(@"%@", json);

    NSString* callString = [NSString stringWithFormat:@"ReadiumSDK.reader.openBook(%@)", json];

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


//this allows JavaScript to call the -logJavaScriptString: method
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
    if(        sel == @selector(onOpenPage:)
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
    if(sel == @selector(onOpenPage:)) {
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

- (void)onOpenPage:(NSString*) currentPaginationInfo
{

    NSData* data = [currentPaginationInfo dataUsingEncoding:NSUTF8StringEncoding];

    NSError *e = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &e];

    if (e) {
        NSLog(@"Error parsing JSON: %@", e);
        return;
    }

    [self.currentPagesInfo fromDictionary:dict];
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
    [self updateSettings:_preferences];
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if(object == _preferences) {
        [_preferences doNotUpdateView: keyPath];
        [self updateSettings:_preferences];
    }
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
