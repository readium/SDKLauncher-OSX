//
//  PackageResourceServer.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
// Modified by Daniel Weck
//  Copyright (c) 2013 The Readium Foundation. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kSDKLauncherPackageResourceServerPort 8080

@class AsyncSocket;
@class LOXPackage;

static const BOOL m_skipCache = true;

@interface PackageResourceServer : NSObject {
	@private AsyncSocket *m_mainSocket;
	@private LOXPackage *m_package;
	@private NSMutableArray *m_requests;
}

- (id)initWithPackage:(LOXPackage *)package;

@end
