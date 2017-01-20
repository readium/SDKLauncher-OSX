//
//  Created by Mickaël Menu on 09/12/15.
//  Copyright © 2015 The Readium Foundation. All rights reserved.
//

#import "RDLCPService.h"

@implementation RDLCPService

+ (instancetype)sharedService {
    static dispatch_once_t onceToken;
    static RDLCPService *sharedService;
    dispatch_once(&onceToken, ^{
        NSError *error;
        sharedService = [self serviceWithRootCertificate:self.rootCertificate error:&error];
        if (!sharedService) {
            NSLog(@"Can't create the shared LCP service <%@>", error);
        }
    });
    
    return sharedService;
}

+ (NSString *)rootCertificate {
    NSString *rootCertificatePath = [[NSBundle mainBundle] pathForResource:@"LCP Root Certificate" ofType:@"crt"];
    NSString *rootCertificate = [NSString stringWithContentsOfFile:rootCertificatePath encoding:NSUTF8StringEncoding error:NULL];
    
    // the LCP library needs the raw "pure" certificate value
    rootCertificate = [rootCertificate stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    rootCertificate = [rootCertificate stringByReplacingOccurrencesOfString:@"-----BEGIN CERTIFICATE-----" withString:@""];
    rootCertificate = [rootCertificate stringByReplacingOccurrencesOfString:@"-----END CERTIFICATE-----" withString:@""];
    
    return rootCertificate;
}

- (void)registerContentModule:(lcp::ICredentialHandler *) credentialHandler statusDocumentHandler:(lcp::IStatusDocumentHandler *)statusDocumentHandler {
    lcp::LcpContentModule::Register(self.nativeService, credentialHandler, statusDocumentHandler);
}

@end
