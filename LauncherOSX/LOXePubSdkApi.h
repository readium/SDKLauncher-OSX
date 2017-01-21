//
//  LOXePubSdkApi.h
//  LauncherOSX
//
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




@class LOXToc;
@class LOXSpineItem;
@class LOXSpine;
@class LOXPackage;

namespace ePub3 {
    class Container;
    class Package;
}

@interface LOXePubSdkApi : NSObject {

}

+(void)initialize;

- (LOXPackage *)openFile:(NSString *)file;

- (NSAlert *)presentAlertWithTitle:(NSString *)title message:(NSString *)message, ...;
- (NSString*)presentAlertWithInput:(NSString *)title inputDefaultText:(NSString *)inputDefaultText message:(NSString *)message, ...;

/**
 * File extensions supported by the launcher.
 */
@property (nonatomic, readonly) NSArray *supportedFileExtensions;

/**
 * Returns whether the given file path has a valid format extension.
 */
- (BOOL)isValidFile:(NSString *)path;

/**
 * Returns whether the given file can be opened by Readium.
 */
- (BOOL)canOpenFile:(NSString *)path;


/**
 * Returns whether the given file exists in the container's archive.
 */
- (BOOL)fileExistsAtPath:(NSString *)relativePath;


/**
 * Read the content of the file at the relative path in the container's archive.
 * If no file is found, returns nil.
 */
- (NSString *)contentsOfFileAtPath:(NSString *)relativePath encoding:(NSStringEncoding)encoding;


@end
