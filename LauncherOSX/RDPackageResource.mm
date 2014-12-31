//
//  RDPackageResource.mm
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
// Modified by Daniel Weck
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

#import "RDPackageResource.h"
#import "LOXPackage.h"

#import <ePub3/archive.h>
#import <ePub3/utilities/byte_stream.h>

#import <ePub3/filter_chain.h>
#import <ePub3/filter.h>
#import <ePub3/filter_chain_byte_stream.h>
#import <ePub3/filter_chain_byte_stream_range.h>

@interface RDPackageResource() {
@private std::unique_ptr<ePub3::ByteStream> m_byteStream;
@private NSString *m_relativePath;
@private BOOL m_hasProperStream;
@private std::size_t m_bytesCount;
@private std::size_t m_bytesCountCheck;
@private UInt8 m_buffer[READ_CHUNKSIZE];
//@private NSData *m_data;
}

@end


@implementation RDPackageResource

//@synthesize byteStream = m_byteStream;
@synthesize bytesCount = m_bytesCount;
@synthesize bytesCountCheck = m_bytesCountCheck;
@synthesize relativePath = m_relativePath;
@synthesize package = m_package;

- (void *)byteStream {
    return m_byteStream.get();
}

- (NSData *)readDataFull {
    if (m_data == nil) {

        if (m_bytesCount == 0)
        {
            m_data = [NSData data];
        }
        else
        {
            if (!m_hasProperStream)
            {
                ePub3::ByteStream *byteStream = m_byteStream.release();
                m_byteStream.reset((ePub3::ByteStream *)[m_package getProperByteStream:m_relativePath currentByteStream:byteStream isRangeRequest:NO]);
                m_bytesCount = [RDPackageResource bytesAvailable:m_byteStream.get() pack:m_package path:m_relativePath];
                m_hasProperStream = YES;
            }

            m_bytesCountCheck = 0;

            NSMutableData *md = [[NSMutableData alloc] initWithCapacity: m_bytesCount];

            while (YES) {
                std::size_t count = m_byteStream->ReadBytes(m_buffer, sizeof(m_buffer));

                if (count == 0) {
                    break;
                }

                m_bytesCountCheck += count;
                [md appendBytes:m_buffer length:count];
                }


            if (m_bytesCount != m_bytesCountCheck)
            {
// printf("BYTE COUNT UPDATE (readDataFull): %d -> %d (%s)\n", m_bytesCount, m_bytesCountCheck, [m_relativePath UTF8String]);
                m_bytesCount = m_bytesCountCheck;
            }

            m_data = md;
        }
    }

    return m_data;
}


+ (std::size_t)bytesAvailable:(ePub3::ByteStream*)byteStream pack:(LOXPackage *)package path:(NSString *)relPath {
    std::size_t size = byteStream->BytesAvailable();
    if (size == 0)
    {
        NSLog(@"BYTESTREAM zero BytesAvailable!");
    }

    return size;

//    //std::unique_ptr<ePub3::ArchiveReader> reader = _sdkPackage->ReaderForRelativePath(s);
//    //reader->read(<#(void*)p#>, <#(size_t)len#>)
//
//    std::shared_ptr<ePub3::Archive> archive = [package sdkPackage]->Archive();
//
//    try
//    {
//        //ZipItemInfo
//        ePub3::ArchiveItemInfo info = archive->InfoAtPath([package sdkPackage]->BasePath() + [relPath UTF8String]);
//        size = info.UncompressedSize();
//    }
//    catch (std::exception& e)
//    {
//        auto msg = e.what();
//        NSLog(@"!!! [ArchiveItemInfo] ZIP file not found (corrupted archive?): %@ (%@)", relPath, [NSString stringWithUTF8String:msg]);
//    }
//    catch (...) {
//        throw;
//    }
//
//    archive = nullptr;
//
//
//
//    std::string s = [relPath UTF8String];
//    std::unique_ptr<ePub3::ArchiveReader> reader = [package sdkPackage]->ReaderForRelativePath(s);
//
//    if (reader == nullptr)
//    {
//        NSLog(@"!!! [ArchiveReader] ZIP file not found (corrupted archive?): %@", relPath);
//    }
//    else
//    {
//        UInt8 buffer[READ_CHUNKSIZE];
//        std::size_t total = 0;
//        std::size_t count = 0;
//        while ((count = reader->read(buffer, sizeof(buffer))) > 0)
//        {
//            total += count;
//        }
//
//        if (total > 0)
//        {
//            // ByteStream bug??! zip_fread works with ArchiveReader, why not ByteStream?
//            NSLog(@"WTF??!");
//
//            if (total != size)
//            {
//                NSLog(@"Oh dear...");
//            }
//        }
//    }
//
//    reader = nullptr;
//
//    return size;
}

- (NSData *)readDataOfLength:(NSUInteger)length offset:(UInt64)offset isRangeRequest:(BOOL)isRangeRequest {
    if (length == 0)
    {
        return [NSData data];
    }

    if (!m_hasProperStream)
    {
        ePub3::ByteStream *byteStream = m_byteStream.release();
        m_byteStream.reset((ePub3::ByteStream *)[m_package getProperByteStream:m_relativePath currentByteStream:byteStream isRangeRequest:isRangeRequest]);
        m_bytesCount = [RDPackageResource bytesAvailable:m_byteStream.get() pack:m_package path:m_relativePath];
        m_hasProperStream = YES;
    }

    ePub3::FilterChainByteStreamRange *filterStream = dynamic_cast<ePub3::FilterChainByteStreamRange *>(m_byteStream.get());
    if (filterStream != nullptr) {

        NSMutableData *md = [[NSMutableData alloc] initWithCapacity:length];

        ePub3::ByteRange range;
		range.Location(offset);
		NSUInteger totalRead = 0;

        //NSLog(@"+++++ readDataOfLength: %lu + %lu (%@)", m_offset, length, m_relativePath);
//printf("+++++ readDataOfLength: %d + %d (%s)\n", m_offset, length, [m_relativePath UTF8String]);

        while (totalRead < length) {

            range.Length(MIN(sizeof(m_buffer), length - totalRead));

    		std::size_t count = filterStream->ReadBytes(m_buffer, sizeof(m_buffer), range);

            if (count <= 0)  {
                break;
            }

    		[md appendBytes:m_buffer length:count];

            m_bytesCountCheck += count;
    		totalRead += count;
//printf("+++++ readDataOfLength SO FAR: %d / %d (%s)\n", totalRead, length, [m_relativePath UTF8String]);

            range.Location(range.Location() + count);
        }

//
//        if (m_bytesCount != m_bytesCountCheck)
//        {
//            printf("BYTE COUNT UPDATE (FilterChainByteStreamRange): %d -> %d (%s) %d\n", m_bytesCount, m_bytesCountCheck, [m_relativePath UTF8String], offset);
//            m_bytesCount = m_bytesCountCheck;
//        }

        if (totalRead != length) {
            //NSLog(@"1) Did not read the expected number of bytes! (%lu %lu / %lu %@)", totalRead, length, m_bytesCount, m_relativePath);
            //printf("1) Did not read the expected number of bytes! (%d %d / %d %s)\n", totalRead, length, m_bytesCount, [m_relativePath UTF8String]);

            if (totalRead == 0){

//                //CRLF
//                m_buffer[0] = 0x0D;
//                m_buffer[1] = 0x0A;
//                [md appendBytes:m_buffer length:2];
//                printf("CR LF socket close... \n");

                //return [NSData data];
            }
        }
        else {
            //NSLog(@"1) Correct: (%lu %lu / %lu %@)", totalRead, length, m_bytesCount, m_relativePath);
// printf("2) Korrect: (%d %d / %d %s %d)\n", totalRead, length, m_bytesCount, [m_relativePath UTF8String], offset);
        }


        return md;
    }

    ePub3::SeekableByteStream *seekableByteStream = dynamic_cast<ePub3::SeekableByteStream *>(m_byteStream.get());
    if (seekableByteStream != nullptr
        || true)
    {
        //ASSERT (m_bytesCount - m_byteStream->BytesAvailable()) == offset
        // (does not work because underlying raw byte stream may not map 1-1 to output ranges)
        // ... we assume that this is part of a series of contiguous subsequent buffer requests from the HTTP chunking.

        NSMutableData *md = [[NSMutableData alloc] initWithCapacity:length];

        if (seekableByteStream != nullptr)
        {
            seekableByteStream->Seek(offset, std::ios::seekdir::beg);
        }

        NSUInteger totalRead = 0;

        //NSLog(@"+++++ readDataOfLength: %lu + %lu (%@)", m_offset, length, m_relativePath);
//printf("+++++ readDataOfLength: %d + %d (%s)\n", m_offset, length, [m_relativePath UTF8String]);

        while (totalRead < length) {

            std::size_t toRead = MIN(sizeof(m_buffer), length - totalRead);

            std::size_t count = m_byteStream->ReadBytes(m_buffer, toRead);

            if (count <= 0) {


                if (m_bytesCount != m_bytesCountCheck)
                {
// printf("BYTE COUNT UPDATE: %d -> %d (%s) %d\n", m_bytesCount, m_bytesCountCheck, [m_relativePath UTF8String], offset);
                    m_bytesCount = m_bytesCountCheck;
                }

                break;
            }

            [md appendBytes:m_buffer length:count];

            m_bytesCountCheck += count;
            totalRead += count;
//printf("+++++ readDataOfLength SO FAR: %d / %d (%s)\n", totalRead, length, [m_relativePath UTF8String]);

        }

        if (totalRead != length) {
            //NSLog(@"1) Did not read the expected number of bytes! (%lu %lu / %lu %@)", totalRead, length, m_bytesCount, m_relativePath);
// printf("BYTE Partial: (%d %d / %d %s %d)\n", totalRead, length, m_bytesCount, [m_relativePath UTF8String], offset);

            if (totalRead == 0){

//                //CRLF
//                m_buffer[0] = 0x0D;
//                m_buffer[1] = 0x0A;
//                [md appendBytes:m_buffer length:2];
//                printf("CR LF socket close... \n");

                //return [NSData data];
            }
        }
        else {
            //NSLog(@"1) Correct: (%lu %lu / %lu %@)", totalRead, length, m_bytesCount, m_relativePath);
// printf("BYTE Correct: (%d %d / %d %s %d)\n", totalRead, length, m_bytesCount, [m_relativePath UTF8String], offset);
        }


        return md;
    }

    NSLog(@"readDataOfLength prefetchedData should never happen! %@", m_relativePath);

    NSData *prefetchedData = [self readDataFull]; // Note: ensureProperByteStream was already called above.
    NSUInteger prefetchedDataLength = [prefetchedData length];
    NSUInteger adjustedLength = prefetchedDataLength < length ? prefetchedDataLength : length;
    NSMutableData *md = [[NSMutableData alloc] initWithCapacity:adjustedLength];
    [md appendBytes:prefetchedData.bytes length:adjustedLength];
    return md;
}

- (void)dealloc {

    // calls Close() on ByteStream destruction
    if (m_byteStream != nullptr)
    {
        //delete m_byteStream;
        m_byteStream = nullptr;
    }
}


- (id)
	initWithByteStream:(ePub3::ByteStream *)byteStream
	relativePath:(NSString *)relativePath
    pack:(LOXPackage *)package
{
	if (byteStream == nullptr
            || relativePath == nil || relativePath.length == 0) {
		return nil;
	}

	if (self = [super init]) {

        m_package = package;
        m_relativePath = relativePath;

        m_byteStream.reset(byteStream);
        m_bytesCount = [RDPackageResource bytesAvailable:m_byteStream.get() pack:package path:m_relativePath];
        m_bytesCountCheck = 0;

        m_hasProperStream = NO;



/*


        NSData * data = [self data];



//        NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], m_relativePath];
//        NSURL *fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];

        NSError *error = nil;
        NSURL *directoryURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:[[NSProcessInfo processInfo] globallyUniqueString]] isDirectory:YES];
        [[NSFileManager defaultManager] createDirectoryAtURL:directoryURL withIntermediateDirectories:YES attributes:nil error:&error];

        NSURL *fileURL = [directoryURL URLByAppendingPathComponent:m_relativePath];

        error = nil;
        [[NSFileManager defaultManager] removeItemAtURL:fileURL error:&error];

        NSString* path = [fileURL path];
NSLog(@"PATH: %@", path);

        path = [path stringByDeletingLastPathComponent];
        error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error];

        error = nil;
        BOOL res = [data writeToURL:fileURL options:NSDataWritingAtomic error:&error];
        if (res == NO && error != nil)
            NSLog(@"Write returned error: %@", [error localizedDescription]);


*/



        if (m_bytesCount == 0)
        {
            NSLog(@"m_bytesCount == 0 ???? %@", m_relativePath);
        }

	}

	return self;
}


@end
