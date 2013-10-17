//
//  PackageResourceServer.m
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
// Modified by Daniel Weck
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#ifdef USE_SIMPLE_HTTP_SERVER

#import "AQHTTPServer.h"
#else
#import "AsyncSocket.h"
#endif

#import "PackageResourceServer.h"
#import "PackageResourceCache.h"
#import "LOXPackage.h"
#import "RDPackageResource.h"


#ifdef USE_SIMPLE_HTTP_SERVER

static LOXPackage * m_LOXHTTPConnection_package;

//@synchronized(self) {
//
//}

////from STACK to HEAP
//void (^ myBlock)(void) = ^ {
//    // your block code is here.
//};
//[IRQ addObject:[[myBlock copy] autorelease]];

//@autoreleasepool {
//while ( !done )
//{
//[[NSRunLoop currentRunLoop] runMode: @"AQHTTPRequestWritingDataRunLoopMode" beforeDate: [NSDate dateWithTimeIntervalSinceNow: 0.05]];
//}
//}

//static dispatch_semaphore_t m_byteStreamResourceLock;
//
//#define LOCKED(block) do {\
//        dispatch_semaphore_wait(m_byteStreamResourceLock, DISPATCH_TIME_FOREVER);\
//        @try {\
//            block();\
//        } @finally {\
//            dispatch_semaphore_signal(m_byteStreamResourceLock);\
//        }\
//    } while (0);


//[NSThread isMainThread]  ------  dispatch_get_current_queue() == dispatch_get_main_queue()
//#define MAINQ(block) if ([NSThread isMainThread]) {\
//NSLog(@"MAINQ - main thread");\
//block();\
//} else {\
//NSLog(@"MAINQ - other thread");\
//dispatch_sync(dispatch_get_main_queue(), block);\
//}

//
//dispatch_sync(self.queue, ^{});
//
//dispatch_async(dispatch_get_main_queue(), ^{
//
//});

@implementation LOXHTTPResponseOperation {
    LOXPackage * m_package;
    RDPackageResource * m_resource;
}

//dispatch_semaphore_t    _lock;
//@synthesize lock=_lock;


//- (id) init
//{
//    self = [super init];
//    if ( self == nil )
//        return ( nil );
//
//    // create a critical section lock
//    //_lock = dispatch_semaphore_create(1);
//
//    m_package = nil;
//    m_resource = nil;
//
//    return ( self );
//}

- (void)initialiseData:(LOXPackage *)package resource:(RDPackageResource *)resource
{
    if (m_package != nil)
    {
        [m_package release];
        m_package = nil;
    }
    m_package = package;
    [m_package retain];

    if (m_resource != nil)
    {
        [m_resource release];
        m_resource = nil;
    }
    m_resource = resource;
    [m_resource retain];

    if (DEBUGLOG)
    {
        NSLog(@"LOXHTTPResponseOperation: %@", m_resource.relativePath);
        NSLog(@"LOXHTTPResponseOperation: %ld", m_resource.bytesCount);
        NSLog(@"LOXHTTPResponseOperation: %@", self);
    }

    // critical section
    //_lock = dispatch_semaphore_create(1);
}

- (void)dealloc {
    if (DEBUGLOG)
    {
        NSLog(@"DEALLOC LOXHTTPResponseOperation");
        NSLog(@"DEALLOC LOXHTTPResponseOperation: %@", m_resource.relativePath);
        NSLog(@"DEALLOC LOXHTTPResponseOperation: %@", self);
    }
//
//#if DISPATCH_USES_ARC == 0
//    if ( _lock != NULL )
//    {
//        dispatch_release(_lock);
//        _lock = NULL;
//    }
//#endif
    if (m_package != nil)
    {
        [m_package release];
    }

    if (m_resource != nil)
    {
        [m_resource release];
    }

    [super dealloc];
}

- (NSUInteger) statusCodeForItemAtPath: (NSString *) rootRelativePath
{
    NSString * method = CFBridgingRelease(CFHTTPMessageCopyRequestMethod(_request));

    if (m_resource == nil)
    {
        return ( 404 );
    }
    else if (method != nil && [method caseInsensitiveCompare: @"DELETE"] == NSOrderedSame )
    {
        // Not Permitted
        return ( 403 );
    }
    else if ( _ranges != nil )
    {
        return ( 206 );
    }

    return ( 200 );
}

- (UInt64) sizeOfItemAtPath: (NSString *) rootRelativePath
{
    return m_resource.bytesCount;
}

- (NSString *) etagForItemAtPath: (NSString *) path
{
    return nil;
}

- (NSInputStream *) inputStreamForItemAtPath: (NSString *) rootRelativePath
{
    return nil;
}

- (id<AQRandomAccessFile>) randomAccessFileForItemAtPath: (NSString *) rootRelativePath
{
    //return [self autorelease];
    return self;
}

-(UInt64)length
{
    return m_resource.bytesCount;
}

- (NSData *) readDataFromByteRange: (DDRange) range
{
//    if (DEBUGLOG)
//    {
//        NSLog(@"LOCK readDataFromByteRange: %@", self);
//    }

    //__block
    NSData * result = nil;
//    LOCKED(^{
        if (m_skipCache)
        {
            result = [m_resource createChunkByReadingRange:NSRangeFromDDRange(range) package:m_package];
        }
        else
        {
            result = [[PackageResourceCache shared] dataAtRelativePath: m_resource.relativePath range:NSRangeFromDDRange(range) resource:m_resource];
        }
//    });

//    if (DEBUGLOG)
//    {
//        NSLog(@"un-LOCK readDataFromByteRange: %@", self);
//    }

    //result = [NSData data];

    //[result autorelease];
    return result;
}

@end

@implementation LOXHTTPConnection

//- (id) init
//{
//    self = [super init];
//    if ( self == nil )
//        return ( nil );
//
//    return ( self );
//}

- (void)dealloc {
    if (DEBUGLOG)
    {
        NSLog(@"DEALLOC LOXHTTPConnection");
        NSLog(@"DEALLOC LOXHTTPConnection: %@", self);
    }
    [super dealloc];
}

- (BOOL) supportsPipelinedRequests
{
    return YES;
}

- (AQHTTPResponseOperation *) responseOperationForRequest: (CFHTTPMessageRef) request
{
    NSURL * url = (NSURL *)CFBridgingRelease(CFHTTPMessageCopyRequestURL(request));
    if (url == nil)
    {
        return [super responseOperationForRequest: request];
    }

    if (DEBUGLOG)
    {
        NSLog(@"responseOperationForRequest: %@", url);
    }

    NSString * scheme = [url scheme];
    if (scheme == nil || [scheme caseInsensitiveCompare: @"fake"] == NSOrderedSame)
    {
        return [super responseOperationForRequest: request];
    }

    NSString * path = [url path];
    if (path == nil)
    {
        return [super responseOperationForRequest: request];
    }


    NSString * relPath = [m_LOXHTTPConnection_package resourceRelativePath: path];
    if (relPath == nil)
    {
        return [super responseOperationForRequest: request];
    }

    RDPackageResource *resource = [m_LOXHTTPConnection_package resourceAtRelativePath:relPath];
    if (resource == nil)
    {
        return [super responseOperationForRequest: request];
    }

	int contentLength = 0;

    if (m_skipCache)
    {
        contentLength = resource.bytesCount;
    }
    else
    {
        contentLength = [[PackageResourceCache shared] contentLengthAtRelativePath: resource.relativePath resource:resource];

        if (contentLength == 0) {
            [[PackageResourceCache shared] addResource:resource];

            contentLength = [[PackageResourceCache shared] contentLengthAtRelativePath: resource.relativePath resource:resource];
        }
    }

    NSString * rangeHeader = CFBridgingRelease(CFHTTPMessageCopyHeaderFieldValue(request, CFSTR("Range")));
    NSArray * ranges = nil;
    if ( rangeHeader != nil )
    {
        ranges = [self parseRangeRequest: rangeHeader withContentLength: contentLength];
    }

    LOXHTTPResponseOperation * op = [[LOXHTTPResponseOperation alloc] initWithRequest: request socket: self.socket ranges: ranges forConnection: self];
    [op initialiseData:m_LOXHTTPConnection_package resource:resource];

    [resource release]; //was alloc'ed

#if USING_MRR
//#error "THIS SHOULD FAIL AT COMPILE TIME"
    [op autorelease];
#endif
    return ( op );
}
@end
#else
const static int m_socketTimeout = 60;

@interface PackageRequest : NSObject {
	@private int m_byteCountWrittenSoFar;
	@private NSDictionary *m_headers;
	@private NSRange m_range;
	@private RDPackageResource *m_resource;
	@private AsyncSocket *m_socket;
}

@property (nonatomic, assign) int byteCountWrittenSoFar;
@property (nonatomic, retain) NSDictionary *headers;
@property (nonatomic, assign) NSRange range;
@property (nonatomic, retain) RDPackageResource *resource;
@property (nonatomic, retain) AsyncSocket *socket;

@end

@implementation PackageRequest

@synthesize byteCountWrittenSoFar = m_byteCountWrittenSoFar;
@synthesize headers = m_headers;
@synthesize range = m_range;
@synthesize resource = m_resource;
@synthesize socket = m_socket;

- (void)dealloc {
	[m_headers release];
	[m_resource release];
	[m_socket release];
	[super dealloc];
}

@end

#endif



@interface PackageResourceServer()


#ifdef USE_SIMPLE_HTTP_SERVER

#else
@property (nonatomic, readonly) NSString *dateString;

- (void)writeNextResponseChunkForRequest:(PackageRequest *)request;
#endif

@end


@implementation PackageResourceServer {
    LOXPackage * m_package;
}
//
//- (id) init
//{
//    self = [super init];
//    if ( self == nil )
//        return ( nil );
//
//    m_package = nil;
//
//    return ( self );
//}

- (int) serverPort
{
    return m_kSDKLauncherPackageResourceServerPort;
}

- (void)dealloc {

    if (DEBUGLOG)
    {
        NSLog(@"DEALLOC Pack Res Server ");
    }

#ifdef USE_SIMPLE_HTTP_SERVER

//#if DISPATCH_USES_ARC == 0
//    if ( m_byteStreamResourceLock != NULL )
//    {
//        //dispatch_semaphore_signal(m_byteStreamResourceLock);
//        dispatch_release(m_byteStreamResourceLock);
//        m_byteStreamResourceLock = NULL;
//    }
//#endif

    if ([m_server isListening])
    {
        [m_server stop];
    }
    [m_server release];
#else
	NSArray *requests = [[NSArray alloc] initWithArray:m_requests];
	for (PackageRequest *request in requests) {
		// Disconnecting causes onSocketDidDisconnect to be called, which removes the request
		// from the array, which is why we iterate a copy of that array.
		[request.socket disconnect];
	}
	[requests release];
	[m_mainSocket release];
    [m_requests release];
#endif

	[m_package release];

	[super dealloc];
}

- (id)initWithPackage:(LOXPackage *)package {
	if (package == nil) {
		[self release];
		return nil;
	}

	if (self = [super init]) {

		m_package = [package retain];

#ifdef USE_SIMPLE_HTTP_SERVER

        // create a critical section lock
//        m_byteStreamResourceLock = dispatch_semaphore_create(1);


//        NSString * port = [NSString stringWithFormat:@"%d", kSDKLauncherPackageResourceServerPort];
//        NSString * address = [@"localhost:" stringByAppendingString:port];
        NSString * address = @"localhost";
        NSURL * url = [NSURL fileURLWithPath: [@"file:///" stringByAppendingString:[m_package packageUUID]]];

        m_server = [[AQHTTPServer alloc] initWithAddress: address root: url]; //retained

//        [LOXHTTPConnection setPackage: m_package];
//        if (m_LOXHTTPConnection_package != nil)
//        {
//            [m_LOXHTTPConnection_package release];
//        }
        m_LOXHTTPConnection_package = m_package;
//        [m_LOXHTTPConnection_package retain];

        [m_server setConnectionClass:[LOXHTTPConnection class]];

        NSError * error = nil;
        if ( [m_server start: &error] == NO )
        {
            NSLog(@"Error starting server: %@", error);
            [self release];
            return nil;
        }
        m_kSDKLauncherPackageResourceServerPort = [m_server serverPort];
        NSLog(@"%@", [m_server serverAddress]);
#else
		m_requests = [[NSMutableArray alloc] init];
		m_mainSocket = [[AsyncSocket alloc] initWithDelegate:self];
		[m_mainSocket setRunLoopModes:@[ NSRunLoopCommonModes ]];

		NSError *error = nil;

        m_kSDKLauncherPackageResourceServerPort = 8080;
		if (![m_mainSocket acceptOnPort:m_kSDKLauncherPackageResourceServerPort error:&error]) {
			NSLog(@"The main socket could not be created! %@", error);
			[self release];
			return nil;
		}
#endif
	}

	return self;
}


#ifdef USE_SIMPLE_HTTP_SERVER
#else
- (NSString *)dateString {
	NSDateFormatter *fmt = [[[NSDateFormatter alloc] init] autorelease];
	[fmt setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss"];
	[fmt setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	return [[fmt stringFromDate:[NSDate date]] stringByAppendingString:@" GMT"];
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket {

    if (DEBUGLOG)
    {
        NSLog(@"SOCK %@", newSocket);
    }

	PackageRequest *request = [[[PackageRequest alloc] init] autorelease];
	request.socket = newSocket;
	[m_requests addObject:request];
}


- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port {
	[sock readDataWithTimeout:m_socketTimeout tag:0];
}


- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
	if (data == nil || data.length == 0) {
		NSLog(@"The HTTP request data is missing!");
		[sock disconnect];
		return;
	}

	if (data.length >= 8192) {
		NSLog(@"The HTTP request data is unexpectedly large!");
		[sock disconnect];
		return;
	}

	NSString *s = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
		autorelease];

	if (s == nil || s.length == 0) {
		NSLog(@"Could not read the HTTP request as a string!");
		[sock disconnect];
		return;
	}

	// Parse the HTTP method, path, and headers.

	NSMutableDictionary *headers = [NSMutableDictionary dictionary];
	PackageRequest *request = nil;
	BOOL firstLine = YES;

	for (NSString *line in [s componentsSeparatedByString:@"\r\n"]) {
		if (firstLine) {
			firstLine = NO;
			NSArray *tokens = [line componentsSeparatedByString:@" "];

			if (tokens.count != 3) {
				NSLog(@"The first line of the HTTP request does not have 3 tokens!");
				[sock disconnect];
				return;
			}

			NSString *method = [tokens objectAtIndex:0];

			if (![method isEqualToString:@"GET"]) {
				NSLog(@"The HTTP method is not GET!");
				[sock disconnect];
				return;
			}

			NSString *path = [tokens objectAtIndex:1];

			if (path.length == 0) {
				NSLog(@"The HTTP request path is missing!");
				[sock disconnect];
				return;
			}

			NSRange range = [path rangeOfString:@"/"];

			if (range.location != 0) {
				NSLog(@"The HTTP request path doesn't begin with a forward slash!");
				[sock disconnect];
				return;
			}

			range = [path rangeOfString:@"/" options:0 range:NSMakeRange(1, path.length - 1)];

			if (range.location == NSNotFound) {
				NSLog(@"The HTTP request path is incomplete!");
				[sock disconnect];
				return;
			}

			NSString *packageUUID = [path substringWithRange:NSMakeRange(1, range.location - 1)];

			if (![packageUUID isEqualToString:m_package.packageUUID]) {
				NSLog(@"The HTTP request has the wrong package UUID!");
				[sock disconnect];
				return;
			}

			path = [path substringFromIndex:NSMaxRange(range)];
			RDPackageResource *resource = [m_package resourceAtRelativePath:path];

			if (resource == nil) {
				NSLog(@"The package resource is missing!");
				[sock disconnect];
				return;
			}

			for (PackageRequest *currRequest in m_requests) {
				if (currRequest.socket == sock) {
					currRequest.headers = headers;
					currRequest.resource = resource;
					request = currRequest;
					break;
				}
			}

			if (request == nil) {
				NSLog(@"Could not find our request!");
				[sock disconnect];
				return;
			}
		}
		else {
			NSRange range = [line rangeOfString:@":"];

			if (range.location != NSNotFound) {
				NSString *key = [line substringToIndex:range.location];
				key = [key stringByTrimmingCharactersInSet:
					[NSCharacterSet whitespaceAndNewlineCharacterSet]];

				NSString *val = [line substringFromIndex:range.location + 1];
				val = [val stringByTrimmingCharactersInSet:
					[NSCharacterSet whitespaceAndNewlineCharacterSet]];

				[headers setObject:val forKey:key.lowercaseString];
			}
		}
	}

	int contentLength = 0;

    if (m_skipCache)
    {
        contentLength = request.resource.bytesCount;
    }
    else
    {
        contentLength = [[PackageResourceCache shared] contentLengthAtRelativePath:
		request.resource.relativePath resource:request.resource];

        if (contentLength == 0) {
            [[PackageResourceCache shared] addResource:request.resource];

            contentLength = [[PackageResourceCache shared] contentLengthAtRelativePath:
                request.resource.relativePath resource:request.resource];
        }
    }

	NSString *commonResponseHeaders = [NSString stringWithFormat:
		@"Date: %@\r\n"
		@"Server: PackageResourceServer\r\n"
		@"Accept-Ranges: bytes\r\n"
		@"Connection: close\r\n",
		self.dateString];

	// Handle requests that specify a 'Range' header, which iOS makes use of.  See:
	// http://developer.apple.com/library/ios/#documentation/AppleApplications/Reference/SafariWebContent/CreatingVideoforSafarioniPhone/CreatingVideoforSafarioniPhone.html#//apple_ref/doc/uid/TP40006514-SW6

	NSString *rangeToken = [headers objectForKey:@"range"];

	if (rangeToken != nil) {
		rangeToken = rangeToken.lowercaseString;

		if (![rangeToken hasPrefix:@"bytes="]) {
			NSLog(@"The requests's range doesn't begin with 'bytes='!");
			[sock disconnect];
			return;
		}

		rangeToken = [rangeToken substringFromIndex:6];

		NSArray *rangeValues = [rangeToken componentsSeparatedByString:@"-"];

		if (rangeValues == nil || rangeValues.count != 2) {
			NSLog(@"The requests's range doesn't have two values!");
			[sock disconnect];
			return;
		}

		NSString *s0 = [rangeValues objectAtIndex:0];
		NSString *s1 = [rangeValues objectAtIndex:1];

		s0 = [s0 stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		s1 = [s1 stringByTrimmingCharactersInSet:
			[NSCharacterSet whitespaceAndNewlineCharacterSet]];

		if (s0.length == 0 || s1.length == 0) {
			NSLog(@"The requests's range has a blank value!");
			[sock disconnect];
			return;
		}

		int p0 = s0.intValue;
		int p1 = s1.intValue;

        int length = p1 + 1 - p0;
        request.range = NSMakeRange(p0, length);

        if (DEBUGLOG)
        {
            NSLog(@"[%@] [%d , %d] (%d) / %d", request.resource.relativePath, p0, p1, request.range.length, contentLength);
        }

		NSMutableString *ms = [NSMutableString stringWithCapacity:512];
		[ms appendString:@"HTTP/1.1 206 Partial Content\r\n"];
		[ms appendString:commonResponseHeaders];
		[ms appendFormat:@"Content-Length: %d\r\n", request.range.length];
		[ms appendFormat:@"Content-Range: bytes %d-%d/%d\r\n", p0, p1, contentLength];
		[ms appendString:@"\r\n"];

		[sock writeData:[ms dataUsingEncoding:NSUTF8StringEncoding] withTimeout:m_socketTimeout tag:0];
	}
	else {
        if (DEBUGLOG)
        {
            NSLog(@"Entire HTTP file");
        }

		request.range = NSMakeRange(0, contentLength);

		NSMutableString *ms = [NSMutableString stringWithCapacity:512];
		[ms appendString:@"HTTP/1.1 200 OK\r\n"];
		[ms appendString:commonResponseHeaders];
		[ms appendFormat:@"Content-Length: %d\r\n", request.range.length];
		[ms appendString:@"\r\n"];

		[sock writeData:[ms dataUsingEncoding:NSUTF8StringEncoding] withTimeout:m_socketTimeout tag:0];
	}

	[self writeNextResponseChunkForRequest:request];
}


- (void)onSocket:(AsyncSocket *)sock didWriteDataWithTag:(long)tag {
	PackageRequest *request = nil;

	for (PackageRequest *currRequest in m_requests) {
		if (currRequest.socket == sock) {
			request = currRequest;
			break;
		}
	}

	if (request == nil) {
		NSLog(@"Could not find our request!");
		[sock disconnect];
	}
	else {
		[self writeNextResponseChunkForRequest:request];
	}
}


- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err {
    if (DEBUGLOG)
    {
        NSLog(@"SOCK-ERR %@", sock);
    }
	NSLog(@"The socket disconnected with an error! %@", err);
}


- (void)onSocketDidDisconnect:(AsyncSocket *)sock {

    if (DEBUGLOG)
    {
        NSLog(@"~SOCK %@", sock);
    }
	for (PackageRequest *request in m_requests) {
		if (request.socket == sock) {
			[[sock retain] autorelease];
			[m_requests removeObject:request];
			return;
		}
	}
}


- (void)writeNextResponseChunkForRequest:(PackageRequest *)request {
	int p0 = request.range.location + request.byteCountWrittenSoFar;
	int p1 = MIN((int)NSMaxRange(request.range), p0 + 1024 * 1024);

	if (p0 == p1) {
		// Done.
		return;
	}

	BOOL lastChunk = (p1 == NSMaxRange(request.range));

    auto range = NSMakeRange(p0, p1 - p0);

    if (DEBUGLOG)
    {
        NSLog(@">> [%@] [%d , %d] (%d) ... %d", request.resource.relativePath, p0, p1, range.length, request.byteCountWrittenSoFar);
    }

    NSData *data = nil;
    if (m_skipCache)
    {
        data = [request.resource createChunkByReadingRange:range package:m_package];
    }
    else
    {
        data = [[PackageResourceCache shared] dataAtRelativePath:
                request.resource.relativePath range:range resource:request.resource];
    }

	if (data == nil || data.length != p1 - p0) {
		NSLog(@"The data is empty or has the wrong length!");
		[request.socket disconnect];
	}
	else {
		request.byteCountWrittenSoFar += (p1 - p0);
		[request.socket writeData:data withTimeout:m_socketTimeout tag:0];

		if (lastChunk) {
			[request.socket disconnectAfterWriting];
		}
	}
}
#endif


@end
