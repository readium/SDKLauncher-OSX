//
// Created by Boris Schneiderman on 2013-08-20.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <ePub3/package.h>
#import "LOXMediaOverlay.h"
#import "LOXSmilModel.h"
#import "LOXSMILParser.h"


@implementation LOXMediaOverlay {

    NSMutableArray *_smilModels;
}

@synthesize smilModels = _smilModels;

- (id)initWithSdkPackage:(ePub3::PackagePtr)sdkPackage
{
    self = [super init];

    if(self) {

        _smilModels = [[NSMutableArray array] retain];

        [self parseSmilsFromSdkPackage:sdkPackage];

    }

    return self;
}

- (void)parseSmilsFromSdkPackage:(ePub3::PackagePtr)sdkPackage
{
    auto manifestTable =  sdkPackage->Manifest();

    for(auto iter = manifestTable.begin(); iter != manifestTable.end(); iter++) {

        auto item = iter->second;

        auto mediaType = item->MediaType();
        if(mediaType == "application/smil+xml") {
            LOXSmilModel * mediaOverlay = [self createMediaOverlayForItem:item fromSdkPackage:sdkPackage];
            if(mediaOverlay) {
                [_smilModels addObject:mediaOverlay];
            }
        }
    }

}

- (LOXSmilModel *)createMediaOverlayForItem:(ePub3::ManifestItemPtr) item fromSdkPackage:(ePub3::PackagePtr)sdkPackage
{
    NSData *data = [self dataFromItem:item fromSdkPackage:sdkPackage];

    LOXSMILParser *parser = [[LOXSMILParser alloc] initWithData:data];

    LOXSmilModel *mediaOverlay = [[[parser parse] retain] autorelease];
    mediaOverlay.id = [NSString stringWithUTF8String:item->Identifier().c_str()];
    mediaOverlay.href = [NSString stringWithUTF8String:item->Href().c_str()];

    [parser release];

    return mediaOverlay;

}

-(NSData *)dataFromItem:(ePub3::ManifestItemPtr) item fromSdkPackage:(ePub3::PackagePtr)sdkPackage
{

    auto reader = sdkPackage->ReaderForRelativePath(item->Href());

    char buffer[1024];

    NSMutableData * data = [NSMutableData data];

    ssize_t readBytes = reader->read(buffer, 1024);

    while (readBytes > 0) {
        [data appendBytes:buffer length:(NSUInteger) readBytes];
        readBytes = reader->read(buffer, 1024);
    }

    return data;
}



@end