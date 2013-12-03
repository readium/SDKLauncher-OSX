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

@interface RDPackageResource() {
@private ePub3::ByteStream* m_byteStream;
@private NSString *m_relativePath;

#ifndef USE_NATIVE_ZIP_SEEK
@private UInt32 m_bytesRead;
#endif

@private std::size_t m_bytesCount;
@private UInt8 m_buffer[kSDKLauncherPackageResourceBufferSize];
//@private NSData *m_data;
}

@end


@implementation RDPackageResource

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

//@synthesize byteStream = m_byteStream;
@synthesize bytesCount = m_bytesCount;
@synthesize relativePath = m_relativePath;


- (NSData *)createChunkByReadingRange:(NSRange)range package:(LOXPackage *)package {

    if (m_bytesCount == 0)
    {
        return [NSData data];
    }

    if (DEBUGLOG)
    {
        NSLog(@"BYTESTREAM READ %p", m_byteStream);
    }

    if (range.length == 0) {
        return [NSData data];
    }

    if (DEBUGLOG)
    {
        NSLog(@"ByteStream Range %@", m_relativePath);
        NSLog(@"%ld - %ld", range.location, range.length);

#ifndef USE_NATIVE_ZIP_SEEK
        if (m_bytesRead > 0)
        {
            NSLog(@"=== ByteStream READALREADY %ld", m_bytesRead);
        }
#endif
    }

    if (m_byteStream == nullptr
#ifndef USE_NATIVE_ZIP_SEEK
            || range.location < m_bytesRead
#endif
            )
    {
        if (m_byteStream != nullptr)
        {
            delete m_byteStream;
            m_byteStream = nullptr;
        }

        if (DEBUGLOG)
        {
            NSLog(@"=== ByteStream RESET");
        }

        ePub3::string s = ePub3::string(m_relativePath.UTF8String);
        m_byteStream = package.sdkPackage->ReadStreamForRelativePath(s).release(); //package.sdkPackage->BasePath() API changed
        m_bytesCount = [RDPackageResource bytesAvailable:m_byteStream pack:package path:m_relativePath];
#ifndef USE_NATIVE_ZIP_SEEK
        m_bytesRead = 0;
#endif
    }

    if (DEBUGLOG)
    {
        NSLog(@"ByteStream COUNT: %ld", m_bytesCount);
    }

    if (NSMaxRange(range) > m_bytesCount) {
        NSLog(@"The requested data range is out of bounds!");
        return nil;
    }

    UInt32 bytesToRead = range.length;

    if (DEBUGLOG)
    {
        NSLog(@"TOTAL %ld", m_bytesCount);
        NSLog(@"ByteStream TO READ: %ld", bytesToRead);
    }

    NSMutableData *md = [NSMutableData dataWithCapacity:bytesToRead];

    int bufSize = sizeof(m_buffer);
    std::size_t count = 0;

#ifdef USE_NATIVE_ZIP_SEEK

    //ePub3::SeekableByteStream* seekStream = std::dynamic_pointer_cast<ePub3::SeekableByteStream>(m_byteStream);
    ePub3::SeekableByteStream* seekStream = dynamic_cast<ePub3::SeekableByteStream*>(m_byteStream);

    ePub3::ByteStream::size_type pos = seekStream->Seek(range.location, std::ios::beg);
    if (pos != range.location)
    {
        NSLog(@"Unable to ZIP seek! %ld vs. %ld", pos, range.location);
        return nil;
    }

    int remainderToRead = bytesToRead;
    int toRead = 0;
    while ((toRead = remainderToRead < bufSize ? remainderToRead : bufSize) > 0 && (count = m_byteStream->ReadBytes(m_buffer, toRead)) > 0)
    {
        [md appendBytes:m_buffer length:count];
        remainderToRead -= count;
    }
    if (remainderToRead != 0)
    {
        NSLog(@"Did not seek-read all ZIP range? %ld vs. %ld", remainderToRead, bytesToRead);
        return nil;
    }

#else
    UInt32 bytesToSkip = range.location - m_bytesRead;

    if (DEBUGLOG)
    {
        NSLog(@"TOTAL %ld", m_bytesCount);
        NSLog(@"ByteStream TO SKIP: %ld", bytesToSkip);
    }

    if (bytesToSkip > 0)
    {
        if (bytesToSkip <= bufSize)
        {
            count = m_byteStream->ReadBytes(m_buffer, bytesToSkip);
        }
        else
        {
            count = 0;

            int nFullBuffers = floor(bytesToSkip / (double)bufSize);
            for (int i = 0; i < nFullBuffers; i++)
            {
                count += m_byteStream->ReadBytes(m_buffer, bufSize);
            }

            int remainder = bytesToSkip - (nFullBuffers * bufSize);
            if (remainder > 0)
            {
                count += m_byteStream->ReadBytes(m_buffer, remainder);
            }
        }
    }
    m_bytesRead += count;

    if (DEBUGLOG || count != bytesToSkip)
    {
        NSLog(@"count %ld == bytesToSkip %ld ?", count, bytesToSkip);
    }
    if (count != bytesToSkip)
    {
        NSLog(@"MISMATCH!!");
        return [NSData data];
    }

//    if (DEBUGLOG)
//    {
//        NSAssert(count == bytesToSkip, @"bytes skip mismatch??");
//    }

    count = 0;
    if (bytesToRead <= bufSize)
    {
        count = m_byteStream->ReadBytes(m_buffer, bytesToRead);
        [md appendBytes:m_buffer length:count];
    }
    else
    {
        count = 0;
        int nFullBuffers = floor(bytesToRead / (double)bufSize);
        for (int i = 0; i < nFullBuffers; i++)
        {
            std::size_t read = m_byteStream->ReadBytes(m_buffer, bufSize);
            count += read;
            [md appendBytes:m_buffer length:read];
        }

        int remainder = bytesToRead - (nFullBuffers * bufSize);
        if (remainder > 0)
        {
            std::size_t read = m_byteStream->ReadBytes(m_buffer, remainder);
            count += read;
            [md appendBytes:m_buffer length:read];
        }
    }
    m_bytesRead += count;

    if (DEBUGLOG || count != bytesToRead)
    {
        NSLog(@"count %ld == bytesToRead %ld ?", count, bytesToRead);
    }
    if (count != bytesToRead)
    {
        NSLog(@"MISMATCH!!");
        return [NSData data];
    }

//    if (DEBUGLOG)
//    {
//        NSAssert(count == bytesToRead, @"bytes read mismatch??");
//    }

#endif

    return md;
}

- (NSData *)createNextChunkByReading {

    if (m_bytesCount == 0)
    {
        return [NSData data];
    }

    std::size_t count = m_byteStream->ReadBytes(m_buffer, sizeof(m_buffer));

#ifndef USE_NATIVE_ZIP_SEEK
    if (m_bytesRead == 0 && count == 0)
    {
        NSLog(@"ZIP file empty?? (or problem with byte stream?)");
        // oh oh... :(
    }

    m_bytesRead += count;
#endif

	return (count == 0) ? nil : [[NSData alloc] initWithBytes:m_buffer length:count];
}


- (NSData *)readAllDataChunks {

    if (m_bytesCount == 0)
    {
        return [NSData data];
    }

	//if (m_data == nil) {
		NSMutableData *md = [NSMutableData data];

		while (YES) {
			NSData *chunk = [self createNextChunkByReading];

			if (chunk != nil) {
				[md appendData:chunk];
				[chunk release];
			}
			else {
				break;
			}
		}

        if (DEBUGLOG)
        {
            NSLog(@"ByteStream WHOLE read: %@", m_relativePath);
        }

	//	m_data = [md retain];
	//}

    if (DEBUGLOG)
    {
        NSLog(@"ByteStream WHOLE: %ld (%@)", m_bytesCount, m_relativePath);
    }

    return md;
	//return m_data;
}


- (void)dealloc {

    // calls Close() on ByteStream destruction
    if (m_byteStream != nullptr)
    {
        if (DEBUGLOG)
        {
            NSLog(@"DEALLOC BYTESTREAM");
            NSLog(@"BYTESTREAM DEALLOC %p", m_byteStream);
        }
        delete m_byteStream;
        m_byteStream = nullptr;
    }
//
//    if (m_data != nil)
//    {
//        [m_data release];
//    }
	[m_relativePath release];

	[super dealloc];
}


- (id)
	initWithByteStream:(ePub3::ByteStream*)byteStream
	relativePath:(NSString *)relativePath
    pack:(LOXPackage *)package
{
	if (byteStream == nil
            || relativePath == nil || relativePath.length == 0) {
		[self release];
		return nil;
	}

	if (self = [super init]) {

        m_relativePath = relativePath;
        [m_relativePath retain];

        m_byteStream = byteStream;
        m_bytesCount = [RDPackageResource bytesAvailable:m_byteStream pack:package path:m_relativePath];

        if (m_bytesCount == 0)
        {
            NSLog(@"m_bytesCount == 0 ???? %@", m_relativePath);
        }

#ifndef USE_NATIVE_ZIP_SEEK
        m_bytesRead = 0;
#endif

        if (DEBUGLOG)
        {
            NSLog(@"INIT ByteStream: %@ (%ld)", m_relativePath, m_bytesCount);
            NSLog(@"BYTESTREAM INIT %p", m_byteStream);
        }
	}

	return self;
}


@end
