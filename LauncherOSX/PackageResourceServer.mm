//
//  PackageResourceServer.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
// Modified by Daniel Weck
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import "PackageResourceServer.h"
#import "HTTPServer.h"
#import "HTTPResponse.h"
#import "HTTPDataResponse.h"
#import "LOXPackage.h"
#import "RDPackageResource.h"

static id m_resourceLock = nil;

static LOXPackage *m_package = nil;
static NSString* m_baseUrlPath = nil;


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

    // See:
    // ConstManifestItemPtr PackageBase::ManifestItemAtRelativePath(const string& path) const
    // which compares with non-escaped source (OPF original manifest>item@src attribute value)
    //path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

//
//    if (path != nil && [path hasPrefix:@"/"]) {
//        path = [path substringFromIndex:1];
//    }
    path = [m_package resourceRelativePath: path];
    if (path == nil)
    {
        return nil;
    }

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
                NSData *data = [resource readDataFull];
                if (data != nil) {

			// Can be used to check / debug encoding issues
			// NSString * dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
			// NSLog(@"XHTML SOURCE: %@", dataStr);
			// data = [dataStr dataUsingEncoding:NSUTF8StringEncoding];
                    
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
                        //contentType = @"application/xhtml+xml";
                        contentType = @"text/html";

                        //TODO: resource.contentType = contentType;
                    }

                    NSString* source = [self htmlFromData:data];
                    if (source != nil) {
                        NSString *pattern = @"(<head.*>)";
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
                                   return [[HTTPDataResponse alloc] initWithData:newData contentType:contentType];
                               }
                            }
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
    
    if(m_resource.relativePath) {
    
        NSString* ext = [[m_resource.relativePath pathExtension] lowercaseString];

        if([ext isEqualToString:@"xhtml"] || [ext isEqualToString:@"html"]) {
            return [NSDictionary dictionaryWithObject:@"application/xhtml+xml" forKey:@"Content-Type"]; // FORCE
        }
        else if([ext isEqualToString:@"xml"]) {
            return [NSDictionary dictionaryWithObject:@"application/xml" forKey:@"Content-Type"]; // FORCE
        }
        else
        {
            ePub3::string s = ePub3::string(m_resource.relativePath.UTF8String);
            ePub3::ManifestTable manifest = [m_package sdkPackage]->Manifest();
            for (auto i = manifest.begin(); i != manifest.end(); i++) {
                std::shared_ptr<ePub3::ManifestItem> item = i->second;
                if (item->Href() == s) {
                    NSString * contentType = [NSString stringWithUTF8String: item->MediaType().c_str()];
                    return [NSDictionary dictionaryWithObject:contentType forKey:@"Content-Type"];
                }
            }
        }
    }
    
    return [NSDictionary new];
}

- (UInt64)contentLength {
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
    bool isDone = m_offset >= m_resource.bytesCount;
//printf("is DONE: %d\n", isDone);
    return isDone;
}


- (UInt64)offset {
    return m_offset;
}


- (NSData *)readDataOfLength:(NSUInteger)length {
    NSData *data = nil;

    @synchronized ([PackageResourceServer resourceLock]) {

        data = [m_resource readDataOfLength:length offset:m_offset isRangeRequest:m_isRangeRequest];
    }

    if (data != nil) {
        m_offset += data.length;
    }

    return data;
}


- (void)setOffset:(UInt64)offset {
    m_offset = offset;
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

//        NSString * port = [NSString stringWithFormat:@"%d", kSDKLauncherPackageResourceServerPort];
//        NSString * address = [@"localhost:" stringByAppendingString:port];
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
