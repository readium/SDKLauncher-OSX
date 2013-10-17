//
//  RDPackageResource.mm
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 2/28/13.
// Modified by Daniel Weck
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import "RDPackageResource.h"
#include "byte_stream.h"
#import <ePub3/archive.h>
#import <ePub3/utilities/byte_stream.h>
#import "LOXPackage.h"

@interface RDPackageResource() {
@private ePub3::ByteStream* m_byteStream;
@private NSString *m_relativePath;
@private UInt32 m_bytesRead;
@private std::size_t m_bytesCount;
@private UInt8 m_buffer[kSDKLauncherPackageResourceBufferSize];
//@private NSData *m_data;
}

@end


@implementation RDPackageResource


//@synthesize byteStream = m_byteStream;
@synthesize bytesCount = m_bytesCount;
@synthesize relativePath = m_relativePath;


- (NSData *)createChunkByReadingRange:(NSRange)range package:(LOXPackage *)package {

    if (DEBUGLOG)
    {
        NSLog(@"BYTESTREAM READ %ld", m_byteStream);
    }

    if (range.length == 0) {
        return [NSData data];
    }

    if (DEBUGLOG)
    {
        NSLog(@"ByteStream Range %@", m_relativePath);
        NSLog(@"%ld - %ld", range.location, range.length);

        if (m_bytesRead > 0)
        {
            NSLog(@"=== ByteStream READALREADY %ld", m_bytesRead);
        }
    }

    if (m_byteStream == nullptr || range.location < m_bytesRead)
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
        m_byteStream = package.sdkPackage->ReadStreamForRelativePath(package.sdkPackage->BasePath() + s).release();
        m_bytesCount = m_byteStream->BytesAvailable();
        m_bytesRead = 0;
    }

    if (DEBUGLOG)
    {
        NSLog(@"ByteStream COUNT: %ld", m_bytesCount);
    }

    if (NSMaxRange(range) > m_bytesCount) {
        NSLog(@"The requested data range is out of bounds!");
        return nil;
    }

    UInt32 bytesToSkip = range.location - m_bytesRead;

    if (DEBUGLOG)
    {
        NSLog(@"TOTAL %ld", m_byteStream->BytesAvailable());
        NSLog(@"ByteStream TO SKIP: %ld", bytesToSkip);
    }

    int bufSize = sizeof(m_buffer);

    std::size_t count = 0;

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

    if (DEBUGLOG)
    {
        NSLog(@"count %ld == bytesToSkip %ld ?", count, bytesToSkip);
    }
    NSAssert(count == bytesToSkip, @"bytes skip mismatch??");

    UInt32 bytesToRead = range.length;

    if (DEBUGLOG)
    {
        NSLog(@"TOTAL %ld", m_byteStream->BytesAvailable());
        NSLog(@"ByteStream TO READ: %ld", bytesToRead);
    }

    NSMutableData *md = [NSMutableData dataWithCapacity:bytesToRead];

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

    if (DEBUGLOG)
    {
        NSLog(@"count %ld == bytesToRead %ld ?", count, bytesToRead);
    }
    NSAssert(count == bytesToRead, @"bytes read mismatch??");

    return md;
}

- (NSData *)createNextChunkByReading {
    std::size_t count = m_byteStream->ReadBytes(m_buffer, sizeof(m_buffer));
    m_bytesRead += count;

	return (count == 0) ? nil : [[NSData alloc] initWithBytes:m_buffer length:count];
}


- (NSData *)readAllDataChunks {
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
            NSLog(@"BYTESTREAM DEALLOC %ld", m_byteStream);
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
{
	if (byteStream == nil
            || relativePath == nil || relativePath.length == 0) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
        m_byteStream = byteStream;
        m_bytesCount = m_byteStream->BytesAvailable();
        m_bytesRead = 0;

		m_relativePath = relativePath;
        [m_relativePath retain];

        if (DEBUGLOG)
        {
            NSLog(@"INIT ByteStream: %@ (%ld)", m_relativePath, m_bytesCount);
            NSLog(@"BYTESTREAM INIT %ld", m_byteStream);
        }
	}

	return self;
}


@end
