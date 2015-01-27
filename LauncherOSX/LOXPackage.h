//  Created by Boris Schneiderman.
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
#import <ePub3/package.h>
#import "RDPackageResource.h"

@class LOXSpine;
@class LOXSpineItem;
@class LOXToc;
@class LOXMediaOverlay;


@interface LOXPackage : NSObject { //<RDPackageResourceDelegate>
    @private NSString *m_packageUUID;
//    @private NSMutableSet *m_relativePathsThatAreHTML;
//    @private NSMutableSet *m_relativePathsThatAreNotHTML;
}

-(id)initWithSdkPackage:(ePub3::PackagePtr) sdkPackage;

//- (void)prepareResourceWithPath:(NSString *)path;

- (NSString *)getCfiForSpineItem:(LOXSpineItem *)spineItem;


- (NSDictionary *)toDictionary;
- (ePub3::PackagePtr) sdkPackage;

@property (nonatomic, readonly) NSString *packageUUID;
@property(nonatomic, readonly) LOXSpine *spine;
@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) NSString *packageId;
@property(nonatomic, readonly) LOXToc *toc;
@property(nonatomic, readonly) NSString *rendition_layout;
@property(nonatomic, readonly) NSString *rendition_orientation;
@property(nonatomic, readonly) NSString *rendition_spread;
@property(nonatomic, readonly) NSString *rendition_flow;
//@property(nonatomic, readonly) NSString *rootDirectory;

@property(nonatomic, readonly) LOXMediaOverlay *mediaOverlay;

// Gets the current Byte Stream and returns the proper Byte Stream for the case.
// There can be three possible byte streams:
// - A simple ZipFileByteStream when no ContentFilter objects apply for this resource.
// - A FilterChainByteStreamRange when a Byte Range request has been made, and only one ContentFilter object applies.
// - A FilterChainByteStream when it is not a Byte Range request or more than one ContentFilter applies.
- (void *)getProperByteStream:(NSString *)relativePath currentByteStream:(ePub3::ByteStream *)currentByteStream isRangeRequest:(BOOL)isRangeRequest;


- (RDPackageResource *)resourceAtRelativePath:(NSString *)relativePath; // isHTML:(BOOL *)isHTML;

- (NSString *) resourceRelativePath:(NSString *)urlAbsolutePath;

@end