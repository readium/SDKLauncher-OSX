//
//  RDPackageResource.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
// Modified by Daniel Weck
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>
#import <ePub3/utilities/byte_stream.h>

// Same as HTTPConnection.m (to avoid unnecessary intermediary buffer iterations)
#define READ_CHUNKSIZE  (1024 * 50)

@class RDPackageResource;
@class LOXPackage;

@interface RDPackageResource : NSObject {
@private LOXPackage *m_package;
@private NSData *m_data;

}

//@property (nonatomic, readonly) ePub3::ByteStream* byteStream;
@property (nonatomic, readonly) std::size_t bytesCount;
@property (nonatomic, readonly) std::size_t bytesCountCheck;

@property (nonatomic, readonly) LOXPackage *package;

@property (nonatomic, readonly) NSString *relativePath;

- (NSData *)readDataFull;
- (NSData *)readDataOfLength:(NSUInteger)length offset:(UInt64)offset isRangeRequest:(BOOL)isRangeRequest;;

- (id)
	initWithByteStream:(ePub3::ByteStream *)byteStream
        relativePath:(NSString *)relativePath
        pack:(LOXPackage *)package;

@end
