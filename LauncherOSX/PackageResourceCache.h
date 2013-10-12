//
//  PackageResourceCache.h
//  SDKLauncher-iOS
//
//  Created by Shane Meyer on 3/8/13.
// Modified by Daniel Weck
//  Copyright (c) 2012-2013 The Readium Foundation.
//

#import <Foundation/Foundation.h>

#import <SystemConfiguration/SCDynamicStore.h>
#import <IOKit/IOKitLib.h>

@class RDPackageResource;

// if set to true => no need to cache local file (+ encrypt them), just fetch byte ranges from ZIP ByteStream
// but...ByteStream currenty not seekable, so...
static const BOOL m_skipCrypt = false;


static NSString * hexStringFromData(NSData *data) {
    if (data == nil)
    {
        return nil;
    }

    UInt8 *bytes = (UInt8 *)data.bytes;
    NSMutableString *ms = [NSMutableString stringWithCapacity:2 * data.length];

    for (int i = 0; i < data.length; i++)
    {
        unichar chars[] = { (unichar)(bytes[i] >> 4), (unichar)(bytes[i] & 0xF) };
        chars[0] += (chars[0] < 10 ? '0' : ('A' - 10));
        chars[1] += (chars[1] < 10 ? '0' : ('A' - 10));
        NSString *s = [[NSString alloc] initWithCharacters:chars length:2];
        [ms appendString:s];
        [s release];
    }

    return ms;
}

//
//static NSString * serialNumber()
//{
//io_service_t platformExpert = IOServiceGetMatchingService(kIOMasterPortDefault, IOServiceMatching("IOPlatformExpertDevice"));
//CFStringRef serialNumberAsCFString = NULL;
//if (platformExpert)
//{
//serialNumberAsCFString = IORegistryEntryCreateCFProperty(platformExpert,
//        CFSTR(kIOPlatformSerialNumberKey),
//        kCFAllocatorDefault, 0);
//IOObjectRelease(platformExpert);
//}
//
//NSString *serialNumberAsNSString = nil;
//if (serialNumberAsCFString)
//{
//serialNumberAsNSString = [NSString stringWithString:(NSString *)serialNumberAsCFString];
//CFRelease(serialNumberAsCFString);
//}
//
//return serialNumberAsNSString;
//}

static NSData * GetMACAddress()
{
    kern_return_t           kr          = KERN_SUCCESS;
    CFMutableDictionaryRef  matching    = NULL;
    io_iterator_t           iterator    = IO_OBJECT_NULL;
    io_object_t             service     = IO_OBJECT_NULL;
    CFDataRef               result      = NULL;

    matching = IOBSDNameMatching( kIOMasterPortDefault, 0, "en0" );
    if ( matching == NULL )
    {
        fprintf( stderr, "IOBSDNameMatching() returned empty dictionary\n" );
        return ( NULL );
    }

    kr = IOServiceGetMatchingServices( kIOMasterPortDefault, matching, &iterator );
    if ( kr != KERN_SUCCESS )
    {
        fprintf( stderr, "IOServiceGetMatchingServices() returned %d\n", kr );
        return ( NULL );
    }

    while ( (service = IOIteratorNext(iterator)) != IO_OBJECT_NULL )
    {
        io_object_t parent = IO_OBJECT_NULL;

        kr = IORegistryEntryGetParentEntry( service, kIOServicePlane, &parent );
        if ( kr == KERN_SUCCESS )
        {
            if ( result != NULL )
                CFRelease( result );

            result = (CFDataRef)IORegistryEntryCreateCFProperty( parent, CFSTR("IOMACAddress"), kCFAllocatorDefault, 0 );
            IOObjectRelease( parent );
        }
        else
        {
            fprintf( stderr, "IORegistryGetParentEntry returned %d\n", kr );
        }

        IOObjectRelease( service );
    }

    return ( (NSData *)NSMakeCollectable(result) );
}

static NSString * GetMACAddressDisplayString()
{
    NSData * macData = GetMACAddress();
    if ( [macData length] == 0 )
        return ( nil );


    //UInt8
    const uint8_t *bytes = (const uint8_t*)[macData bytes];

    NSMutableString * result = [NSMutableString string];
    for ( NSUInteger i = 0; i < [macData length]; i++ )
    {
        if ( [result length] != 0 )
            [result appendFormat: @":%02hhx", bytes[i]];
        else
            [result appendFormat: @"%02hhx", bytes[i]];
    }

    return ( [[result copy] autorelease] );
}


@interface PackageResourceCache : NSObject {

}

- (void)addResource:(RDPackageResource *)resource;
- (int)contentLengthAtRelativePath:(NSString *)relativePath;
//- (NSData *)dataAtRelativePath:(NSString *)relativePath;
- (NSData *)dataAtRelativePath:(NSString *)relativePath range:(NSRange)range;
+ (PackageResourceCache *)shared;

@end
