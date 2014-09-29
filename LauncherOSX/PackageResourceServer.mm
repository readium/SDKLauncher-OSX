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

    path = [path stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

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

        NSString* ext = [[path pathExtension] lowercaseString];
        NSString* contentType = nil;
        
        if([ext isEqualToString:@"svg"]) {
            contentType = @"image/svg+xml";
        }
        
        
        if (resource == nil) {
            NSLog(@"No resource found! (%@)", path);
        }
        else if (resource.bytesCount < 1024 * 1024) { // 1MB

            // This resource is small enough that we can just fetch the entire thing in memory,
            // which simplifies access into the byte stream.  Adjust the threshold to taste.

            NSData *data = resource.data;

            if (data != nil) {
                return [[HTTPDataResponse alloc] initWithData:data contentType:contentType];
            }
        }
        else {
            return [[PackageResourceResponse alloc] initWithResource:resource];
        }
    }

    return nil;
}


+ (void)setPackage:(LOXPackage *)package {
    m_package = package;
}


@end

@implementation PackageResourceResponse

- (NSDictionary *)httpHeaders {
    
    if(m_resource.relativePath) {
    
        NSString* ext = [[m_resource.relativePath pathExtension] lowercaseString];
        
        if([ext isEqualToString:@"svg"]) {
            return [NSDictionary dictionaryWithObject:@"image/svg+xml" forKey:@"Content-Type"];
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
    }

    return self;
}


- (BOOL)isDone {
    return m_offset == m_resource.bytesCount;
}


- (UInt64)offset {
    return m_offset;
}


- (NSData *)readDataOfLength:(NSUInteger)length {
    NSData *data = nil;

    @synchronized ([PackageResourceServer resourceLock]) {
        data = [m_resource readDataOfLength:length];
    }

    if (data != nil) {
        m_offset += data.length;
    }

    return data;
}


- (void)setOffset:(UInt64)offset {
    m_offset = offset;

    @synchronized ([PackageResourceServer resourceLock]) {
        [m_resource setOffset:offset];
    }
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

- (id)initWithPackage:(LOXPackage *)package {

	if (self = [super init]) {

		m_package = package;

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
