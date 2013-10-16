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

static const BOOL m_skipCache = false;

#ifdef USE_SIMPLE_HTTP_SERVER

#import "AQHTTPConnection.h"
#import "AQHTTPResponseOperation.h"

@class AQHTTPServer;

@interface LOXHTTPResponseOperation : AQHTTPResponseOperation<AQRandomAccessFile>
{
}
//@property (nonatomic, readonly) dispatch_semaphore_t lock;
- (void)initialiseData:(LOXPackage *)package resource:(RDPackageResource *)resource;
@end

@interface LOXHTTPConnection : AQHTTPConnection
{

}
@end
#else
@class AsyncSocket;
#endif

@interface PackageResourceServer : NSObject {
@private LOXPackage *m_package;
@private int m_kSDKLauncherPackageResourceServerPort;

#ifdef USE_SIMPLE_HTTP_SERVER
    AQHTTPServer * m_server;
#else
	@private AsyncSocket *m_mainSocket;
	@private NSMutableArray *m_requests;
#endif
}

- (id)initWithPackage:(LOXPackage *)package;

- (int) serverPort;

@end
