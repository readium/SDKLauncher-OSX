//
//  PackageResourceServer.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
//  Modified by Daniel Weck
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


#import "PackageResourceServer.h"
#import "HTTPServer.h"
#import "HTTPResponse.h"
#import "HTTPDataResponse.h"
#import "LOXPackage.h"
#import "RDPackageResource.h"
#import "RDPackageResourceDataResponse.h"
#import "NSDate+RDDateAsString.h"

static id m_resourceLock = nil;

static LOXPackage *m_package = nil;
static NSString* m_baseUrlPath = nil;

NSString * const kCacheControlHTTPHeader = @"no-transform,public,max-age=3000,s-maxage=9000";


@implementation PackageResourceConnection


- (NSObject <HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path {
    if (m_package == nil ||
            method == nil ||
            ![method isEqualToString:@"GET"] ||
            path == nil ||
            path.length == 0)
    {
        return nil;
    }

//
//    if (path != nil && [path hasPrefix:@"/"]) {
//        path = [path substringFromIndex:1];
//    }
    path = [m_package resourceRelativePath: path];
    if (path == nil)
    {
        return nil;
    }
    
//    SEE LOX WEBVIEW CONTROLLER mm
//    if ([path hasSuffix:@".map"]) {
//    NSString* bundlePath = [[[NSBundle mainBundle] pathForResource:@"reader" ofType:@"html" inDirectory:@"Scripts"] stringByDeletingLastPathComponent];
//    NSString* slashPath = [NSString stringWithFormat:@"/%@", [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
//    if ([slashPath hasPrefix:bundlePath]) {
//        
//        NSData * newData = [NSData dataWithContentsOfFile:slashPath];
//        if (newData != nil) {
//            return [[HTTPDataResponse alloc] initWithData:newData contentType:@"application/json"];
//        }
//    }
//    }
    
    // Synchronize using a process-level lock to guard against multiple threads accessing a
    // resource byte stream, which may lead to instability.

    @synchronized ([PackageResourceServer resourceLock]) {
        RDPackageResource *resource = [m_package resourceAtRelativePath:path];

        if (resource == nil) {
            NSLog(@"No resource found! (%@)", path);
            return nil;
        }

        NSString* ext = [[path pathExtension] lowercaseString];
        NSString* contentType = nil;

        bool isHTML = [ext isEqualToString:@"xhtml"] || [ext isEqualToString:@"html"]; //[path hasSuffix:@".html"] || [path hasSuffix:@".xhtml"];

        if([ext isEqualToString:@"xml"]) {
            contentType = @"application/xml"; // FORCE
        }
        else if(isHTML) {
            contentType = @"application/xhtml+xml"; // FORCE
        }

        if (contentType == nil)
        {
            ePub3::string s = ePub3::string(path.UTF8String);
            ePub3::ManifestTable manifest = [m_package sdkPackage]->Manifest();
            for (auto i = manifest.begin(); i != manifest.end(); i++) {
                std::shared_ptr<ePub3::ManifestItem> item = i->second;
                if (item->Href() == s) {
                    contentType = [NSString stringWithUTF8String: item->MediaType().c_str()];
                    break;
                }
            }
        }

        if (contentType == nil)
        {
            NSLog(@"No contentType?! (%@)", path);
        }

        if (!isHTML) {
            if (contentType != nil && (contentType == @"application/xhtml+xml" || contentType == @"text/html")) {
                isHTML = true;
            }
        }

        if (isHTML) {
            NSString * FALLBACK_HTML = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><html xmlns=\"http://www.w3.org/1999/xhtml\"><head><title>HTML READ ERROR</title></head><body>ERROR READING HTML BYTES!</body></html>";
            NSData *data = [resource readDataFull];
            if (data == nil || data.length == 0)
            {
                data = [FALLBACK_HTML dataUsingEncoding:NSUTF8StringEncoding];
            }

            BOOL ok = YES;
            @try
            {
                NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithData:data];
                //[xmlparser setDelegate:self];
                [xmlparser setShouldResolveExternalEntities:NO];
                ok = [xmlparser parse];

                if (ok == NO)
                {
                    NSError * error = [xmlparser parserError];
                    NSLog(@"XHTML PARSE ERROR: %@", error);
                }
            }
            @catch (NSException *ex)
            {
                NSLog(@"XHTML parse exception: %@", ex);
                ok = NO;
            }

            if (ok == NO)
            {
                // Can be used to check / debug encoding issues
                NSString * dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"XHTML SOURCE: %@", dataStr);
                
                //contentType = @"application/xhtml+xml";
                contentType = @"text/html";

                //TODO: resource.contentType = contentType;
            }

            NSString* source = [self htmlFromData:data];
            if (source == nil || source.length == 0)
            {
                source = FALLBACK_HTML;
            }

            NSString *pattern = @"(<head[^>]*>)";
            NSError *error = nil;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&error];
            if(error != nil) {
                NSLog(@"RegEx error: %@", error);
            } else {
                //NSString *filePath = [[NSBundle mainBundle] pathForResource:@"epubReadingSystem_inject" ofType:@"js" inDirectory:@"Scripts"];
                //NSString *code = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
                //NSString *inject_epubReadingSystem = [NSString stringWithFormat:@"<script type=\"text/javascript\"></script>", code];

                //NSString *inject_epubReadingSystem1 = [NSString stringWithFormat:@"<script type=\"text/javascript\" src=\"%@/../epubReadingSystem_inject.js\"></script>", m_baseUrlPath];

                // Installs "hook" function so that top-level window (application) can later inject the window.navigator.epubReadingSystem into this HTML document's iframe
                NSString *inject_epubReadingSystem1 = [NSString stringWithFormat:@"<script id=\"readium_epubReadingSystem_inject1\" type=\"text/javascript\">\n//<![CDATA[\n%@\n//]]>\n</script>",
                @"window.readium_set_epubReadingSystem = function (obj) {\
                    \nwindow.navigator.epubReadingSystem = obj;\
                    \nwindow.readium_set_epubReadingSystem = undefined;\
                    \nvar el1 = document.getElementById(\"readium_epubReadingSystem_inject1\");\
                    \nif (el1 && el1.parentNode) { el1.parentNode.removeChild(el1); }\
                    \nvar el2 = document.getElementById(\"readium_epubReadingSystem_inject2\");\
                    \nif (el2 && el2.parentNode) { el2.parentNode.removeChild(el2); }\
                    \n};"];

                // Fake script, generates HTTP request => triggers the push of window.navigator.epubReadingSystem into this HTML document's iframe (see LOXWebViewController.mm where the "readium_epubReadingSystem_inject" UIWebView URI query is handled)
                NSString *inject_epubReadingSystem2 = @"<script id=\"readium_epubReadingSystem_inject2\" type=\"text/javascript\" src=\"/readium_epubReadingSystem_inject/xxx\"> </script>";

                NSString *inject_mathJax = @"";
                if ([source rangeOfString:@"<math"].location != NSNotFound || [source rangeOfString:@"<m:math"].location != NSNotFound) {

                    //inject_mathJax = [NSString stringWithFormat:@"<script type=\"text/javascript\" src=\"%@/../mathjax/MathJax.js\"> </script>", m_baseUrlPath];
                    inject_mathJax = @"<script type=\"text/javascript\" src=\"/readium_MathJax.js\"> </script>";

                    //NSString *filePath = [[NSBundle mainBundle] pathForResource:@"MathJax" ofType:@"js" inDirectory:@"Scripts/mathjax"];
                    //NSString *code = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
                    //inject_mathJax = [NSString stringWithFormat:@"<script type=\"text/javascript\">\n//<![CDATA[\n%@\n//]]>\n</script>", code];
                    //inject_mathJax = [NSString stringWithFormat:@"<script type=\"text/javascript\">\n\n%@\n\n</script>", code];
                    //inject_mathJax = [NSString stringWithFormat:@"<script type=\"text/javascript\">\n<![CDATA[\n%@\n]]>\n</script>", code];
                }

                NSString *newSource = [regex stringByReplacingMatchesInString:source options:0 range:NSMakeRange(0, [source length]) withTemplate:
                [NSString stringWithFormat:@"%@\n%@\n%@\n%@", @"$1", inject_epubReadingSystem1, inject_epubReadingSystem2, inject_mathJax]];
                if (newSource != nil && newSource.length > 0) {
                   NSData * newData = [newSource dataUsingEncoding:NSUTF8StringEncoding];
                   if (newData != nil) {
                       return [[RDPackageResourceDataResponse alloc] initWithData:newData contentType:contentType];
                   }
                }
            }
        }

        return [[PackageResourceResponse alloc] initWithResource:resource];
//
//                NSData *data = resource.data;
//                if (data != nil) {
//                    return [[HTTPDataResponse alloc] initWithData:data contentType:contentType];
//                }
    }

    return nil;
}

//
// Converts the given HTML data to a string.  The character set and encoding are assumed to be
// UTF-8, UTF-16BE, or UTF-16LE.
//
- (NSString *)htmlFromData:(NSData *)data {
    if (data == nil || data.length == 0) {
        return nil;
    }

    NSString *html = nil;
    UInt8 *bytes = (UInt8 *)data.bytes;

    if (data.length >= 3) {
        if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
            html = [[NSString alloc] initWithData:data
                                         encoding:NSUTF16BigEndianStringEncoding];
        }
        else if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
            html = [[NSString alloc] initWithData:data
                                         encoding:NSUTF16LittleEndianStringEncoding];
        }
        else if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
            html = [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];
        }
        else if (bytes[0] == 0x00) {
            // There's a very high liklihood of this being UTF-16BE, just without the BOM.
            html = [[NSString alloc] initWithData:data
                                         encoding:NSUTF16BigEndianStringEncoding];
        }
        else if (bytes[1] == 0x00) {
            // There's a very high liklihood of this being UTF-16LE, just without the BOM.
            html = [[NSString alloc] initWithData:data
                                         encoding:NSUTF16LittleEndianStringEncoding];
        }
        else {
            html = [[NSString alloc] initWithData:data
                                         encoding:NSUTF8StringEncoding];

            if (html == nil) {
                html = [[NSString alloc] initWithData:data
                                             encoding:NSUTF16BigEndianStringEncoding];

                if (html == nil) {
                    html = [[NSString alloc] initWithData:data
                                                 encoding:NSUTF16LittleEndianStringEncoding];
                }
            }
        }
    }

    return html;
}

+ (void)setPackage:(LOXPackage *)package {
    m_package = package;
}


@end


@implementation PackageResourceResponse

- (NSDictionary *)httpHeaders {
    
    NSDate *now = [NSDate date];
    NSString *nowStr = [now dateAsString];
    NSString *expStr = [[now dateByAddingTimeInterval:60*60*24*10] dateAsString];
    NSMutableDictionary *headers = [NSMutableDictionary
                                    dictionaryWithObjectsAndKeys:
                                    kCacheControlHTTPHeader, @"Cache-Control",
                                    nowStr, @"Last-Modified",
                                    expStr, @"Expires", nil];

    if(m_resource.relativePath) {
    
        NSString* ext = [[m_resource.relativePath pathExtension] lowercaseString];

        if([ext isEqualToString:@"xhtml"] || [ext isEqualToString:@"html"]) {
            [headers setObject:@"application/xhtml+xml" forKey:@"Content-Type"]; // FORCE
        }
        else if([ext isEqualToString:@"xml"]) {
            [headers setObject:@"application/xml" forKey:@"Content-Type"]; // FORCE
        }
        else
        {
            ePub3::string s = ePub3::string(m_resource.relativePath.UTF8String);
            ePub3::ManifestTable manifest = [m_package sdkPackage]->Manifest();
            for (auto i = manifest.begin(); i != manifest.end(); i++) {
                std::shared_ptr<ePub3::ManifestItem> item = i->second;
                if (item->Href() == s) {
                    NSString * contentType = [NSString stringWithUTF8String: item->MediaType().c_str()];
                    [headers setObject:contentType forKey:@"Content-Type"];
                    break;
                }
            }
        }
    }
    
    return headers;
}

//- (BOOL)isChunked
//{
//    return YES; // we do not know the content length in advance
//}

- (UInt64)contentLength {
// printf("contentLength: %d (%s)\n", m_resource.bytesCount, [m_resource.relativePath UTF8String]);

    return m_resource.bytesCount;
}


- (id)initWithResource:(RDPackageResource *)resource {
    if (resource == nil) {
        return nil;
    }

    if (self = [super init]) {
        m_resource = resource;
        m_isRangeRequest = NO;
    }

    return self;
}


- (BOOL)isDone {

    bool isDone = !m_isRangeRequest
            ? (m_offset >= m_resource.bytesCount)
            : (m_offset >= (m_offsetInitial + m_resource.bytesCountCheck));

//printf("is DONE: %d (%s)\n", isDone, [m_resource.relativePath UTF8String]);

    return isDone;
}


- (UInt64)offset {
    return m_offset;
}


- (NSData *)readDataOfLength:(NSUInteger)length {
    NSData *data = nil;

//printf("readDataOfLength 1 %s (%d)\n", [m_resource.relativePath UTF8String], length);
    @synchronized ([PackageResourceServer resourceLock]) {

//printf("readDataOfLength %s (%d)\n", [m_resource.relativePath UTF8String], length);
        data = [m_resource readDataOfLength:length offset:m_offset isRangeRequest:m_isRangeRequest];
    }

    if (data != nil)
    {
        m_offset += data.length;
    }

    if (data == nil || data.length == 0)
    {
        printf("readDataOfLength NO DATA  %s (%d)\n", [m_resource.relativePath UTF8String], length);
    }

    if (data == nil)
    {
        data = [NSData data];
    }

    return data;
}


- (void)setOffset:(UInt64)offset {
//printf("setOffset: %d (%s)\n", offset, [m_resource.relativePath UTF8String]);
    m_offset = offset;
    m_offsetInitial = offset;
    m_isRangeRequest = YES;
}


@end

@interface PackageResourceServer()

@end


@implementation PackageResourceServer {
    //LOXPackage * m_package; static
}

+ (id)resourceLock {
    return m_resourceLock;
}

- (int) serverPort
{
    return m_server.listeningPort;
}

- (void)dealloc {
    [m_server stop];
    [PackageResourceConnection setPackage:nil];
}

- (id)initWithPackage:(LOXPackage *)package baseUrlPath:(NSString*)baseUrlPath {

	if (self = [super init]) {

		m_package = package;
        m_baseUrlPath = baseUrlPath;

        m_resourceLock = [[NSObject alloc] init];

// NSString * port = [NSString stringWithFormat:@"%d", kSDKLauncherPackageResourceServerPort];
// NSString * address = [@"localhost:" stringByAppendingString:port];
        NSString * address = @"localhost";
        NSURL * url = [NSURL fileURLWithPath: [@"file:///" stringByAppendingString:[m_package packageUUID]]];

        m_server = [[HTTPServer alloc] init];
        m_server.documentRoot = @"";

        [m_server setConnectionClass:[PackageResourceConnection class]];

        NSError * error = nil;
        if ( [m_server start: &error] == NO )
        {
            NSLog(@"Error starting server: %@", error);
            return nil;
        }
	}

	return self;
}

@end
