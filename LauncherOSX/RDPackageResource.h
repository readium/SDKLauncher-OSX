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

#define kSDKLauncherPackageResourceBufferSize 4096

@class RDPackageResource;
@class LOXPackage;

@interface RDPackageResource : NSObject {
@private LOXPackage *m_package;
@private NSData *m_data;
}

//@property (nonatomic, readonly) ePub3::ByteStream* byteStream;
@property (nonatomic, readonly) std::size_t bytesCount;

@property (nonatomic, readonly) NSData *data;

@property (nonatomic, readonly) LOXPackage *package;


@property (nonatomic, readonly) NSString *relativePath;

@property (nonatomic, copy) NSString *mimeType;

- (NSData *)readDataOfLength:(NSUInteger)length;
- (void)setOffset:(UInt64)offset;

- (id)
	initWithByteStream:(ePub3::ByteStream*)byteStream
        relativePath:(NSString *)relativePath
        pack:(LOXPackage *)package;

@end
