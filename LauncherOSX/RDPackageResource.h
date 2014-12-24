//
//  RDPackageResource.h
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


#import <Foundation/Foundation.h>
#import <ePub3/utilities/byte_stream.h>

// Same as HTTPConnection.m (to avoid unnecessary intermediary buffer iterations)
#define READ_CHUNKSIZE  (1024 * 512)

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
