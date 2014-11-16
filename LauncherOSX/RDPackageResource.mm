//
//  RDPackageResource.mm
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
// Modified by Daniel Weck
//  Copyright (c) 2012-2013 The Readium Foundation.
//

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
@private BOOL m_isRangeRequest;
@private BOOL m_hasProperStream;
@private UInt64 m_offset;
@private std::size_t m_bytesCount;
@private UInt8 m_buffer[kSDKLauncherPackageResourceBufferSize];
//@private NSData *m_data;
}

@end


@implementation RDPackageResource

//@synthesize byteStream = m_byteStream;
@synthesize bytesCount = m_bytesCount;
@synthesize relativePath = m_relativePath;
@synthesize package = m_package;
@synthesize isRangeRequest = m_isRangeRequest;

- (void *)byteStream {
    return m_byteStream.get();
}

- (NSData *)data {
    if (m_data == nil) {

        if (m_bytesCount == 0)
        {
            m_data = [NSData data];
        }
        else
        {
            NSMutableData *md = [[NSMutableData alloc] initWithCapacity: m_bytesCount];

                if (!m_hasProperStream)
                {
                    ePub3::ByteStream *byteStream = m_byteStream.release();
                    m_byteStream.reset((ePub3::ByteStream *)[m_package getProperByteStream:m_relativePath currentByteStream:byteStream isRangeRequest:m_isRangeRequest]);
                    m_bytesCount = [RDPackageResource bytesAvailable:m_byteStream.get() pack:m_package path:m_relativePath];
                    m_hasProperStream = YES;
                }

                while (YES) {
                    std::size_t count = m_byteStream->ReadBytes(m_buffer, sizeof(m_buffer));

                    if (count <= 0) {
                        break;
                    }

                    [md appendBytes:m_buffer length:count];
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
    else
    {
        return size;
    }

    //std::unique_ptr<ePub3::ArchiveReader> reader = _sdkPackage->ReaderForRelativePath(s);
    //reader->read(<#(void*)p#>, <#(size_t)len#>)

    std::shared_ptr<ePub3::Archive> archive = [package sdkPackage]->Archive();

    try
    {
        //ZipItemInfo
        ePub3::ArchiveItemInfo info = archive->InfoAtPath([package sdkPackage]->BasePath() + [relPath UTF8String]);
        size = info.UncompressedSize();
    }
    catch (std::exception& e)
    {
        auto msg = e.what();
        NSLog(@"!!! [ArchiveItemInfo] ZIP file not found (corrupted archive?): %@ (%@)", relPath, [NSString stringWithUTF8String:msg]);
    }
    catch (...) {
        throw;
    }

    archive = nullptr;



    std::string s = [relPath UTF8String];
    std::unique_ptr<ePub3::ArchiveReader> reader = [package sdkPackage]->ReaderForRelativePath(s);

    if (reader == nullptr)
    {
        NSLog(@"!!! [ArchiveReader] ZIP file not found (corrupted archive?): %@", relPath);
    }
    else
    {
        UInt8 buffer[kSDKLauncherPackageResourceBufferSize];
        std::size_t total = 0;
        std::size_t count = 0;
        while ((count = reader->read(buffer, sizeof(buffer))) > 0)
        {
            total += count;
        }

        if (total > 0)
        {
            // ByteStream bug??! zip_fread works with ArchiveReader, why not ByteStream?
            NSLog(@"WTF??!");

            if (total != size)
            {
                NSLog(@"Oh dear...");
            }
        }
    }

    reader = nullptr;

    return size;
}

- (NSData *)readDataOfLength:(NSUInteger)length {
    if (length == 0)
    {
        return [NSData data];
    }

    if (!m_hasProperStream)
    {
        ePub3::ByteStream *byteStream = m_byteStream.release();
        m_byteStream.reset((ePub3::ByteStream *)[m_package getProperByteStream:m_relativePath currentByteStream:byteStream isRangeRequest:m_isRangeRequest]);
        m_bytesCount = [RDPackageResource bytesAvailable:m_byteStream.get() pack:m_package path:m_relativePath];
        m_hasProperStream = YES;
    }

    if (!m_isRangeRequest)
    {
        NSMutableData *md = [[NSMutableData alloc] initWithCapacity:length];
        [md appendBytes:[self data].bytes length:length];
        return md;
    }

    ePub3::FilterChainByteStreamRange *filterStream = dynamic_cast<ePub3::FilterChainByteStreamRange *>(m_byteStream.get());

    if (filterStream != nullptr) {

        NSMutableData *md = [[NSMutableData alloc] initWithCapacity:length];

        ePub3::ByteRange range;
		range.Location(m_offset);
		NSUInteger totalRead = 0;

        //NSLog(@"+++++ readDataOfLength: %lu + %lu (%@)", m_offset, length, m_relativePath);
//printf("+++++ readDataOfLength: %d + %d (%s)\n", m_offset, length, [m_relativePath UTF8String]);

        while (totalRead < length) {

            range.Length(MIN(sizeof(m_buffer), length - totalRead));

    		std::size_t count = filterStream->ReadBytes(m_buffer, sizeof(m_buffer), range);

            if (count <= 0) break;

    		[md appendBytes:m_buffer length:count];

    		totalRead += count;
//printf("+++++ readDataOfLength SO FAR: %d / %d (%s)\n", totalRead, length, [m_relativePath UTF8String]);

            m_offset += count;
            range.Location(range.Location() + count);
        }

        if (totalRead != length) {
            //NSLog(@"1) Did not read the expected number of bytes! (%lu %lu / %lu %@)", totalRead, length, m_bytesCount, m_relativePath);
            printf("1) Did not read the expected number of bytes! (%d %d / %d %s)\n", totalRead, length, m_bytesCount, [m_relativePath UTF8String]);

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
            printf("1) Correct: (%d %d / %d %s)\n", totalRead, length, m_bytesCount, [m_relativePath UTF8String]);
        }


        return md;
    }

    NSLog(@"The byte stream is not a FilterChainByteStream!");
    return [NSData data];
}


- (void)setOffset:(UInt64)offset {
    m_offset = offset;
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

        m_isRangeRequest = NO;
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
