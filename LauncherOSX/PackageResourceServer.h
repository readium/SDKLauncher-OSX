//
//  PackageResourceServer.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
// Modified by Daniel Weck
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LOXPackage;
@class RDPackageResource;

#import "HTTPConnection.h"
#import "HTTPResponse.h"
#import "HTTPDataResponse.h"

@interface PackageResourceConnection : HTTPConnection

+ (void)setPackage:(LOXPackage *)package;

@end

@interface PackageDataResponse : HTTPDataResponse

@property (nonatomic, copy) NSString *contentType;

@end

@interface PackageResourceResponse : NSObject <HTTPResponse> {
@private UInt64 m_offset;
@private RDPackageResource *m_resource;
}

- (id)initWithResource:(RDPackageResource *)resource;

@end

@interface PackageResourceServer : NSObject {

    HTTPServer * m_server;
}

- (id)initWithPackage:(LOXPackage *)package;

- (int) serverPort;

+ (id)resourceLock;

@end
