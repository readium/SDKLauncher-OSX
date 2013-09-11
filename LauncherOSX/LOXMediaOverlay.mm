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

#import <ePub3/media-overlays_smil_utils.h>
//#import "media-overlays_smil_utils.h"


@interface LOXMediaOverlay ()
- (NSString *)getProperty:(NSString *)name fromPropertyHolder:(std::shared_ptr<ePub3::PropertyHolder>)sdkPropertyHolder;
@end

@implementation LOXMediaOverlay {

    NSMutableArray *_smilModels;
}

@synthesize smilModels = _smilModels;

- (id)initWithSdkPackage:(ePub3::PackagePtr)sdkPackage
{
    self = [super init];

    if(self) {

        _smilModels = [[NSMutableArray array] retain];
        self.duration = [self getProperty:@"duration" fromPropertyHolder: sdkPackage];
        self.durationMilliseconds = ePub3::ParseSmilClockValueToMilliseconds([self.duration UTF8String]);
        self.narrator = [self getProperty:@"narrator" fromPropertyHolder: sdkPackage];


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

            LOXSmilModel * smilModel = [self createMediaOverlayForItem:item fromSdkPackage:sdkPackage];
            if(smilModel) {

                smilModel.duration = [self getProperty:@"duration" fromPropertyHolder:item];
                smilModel.durationMilliseconds = ePub3::ParseSmilClockValueToMilliseconds([smilModel.duration UTF8String]);
                [_smilModels addObject:smilModel];
            }
        }
    }
}

- (NSString *)getProperty:(NSString *)name fromPropertyHolder:(std::shared_ptr<ePub3::PropertyHolder>)sdkPropertyHolder
{
    auto prop = sdkPropertyHolder->PropertyMatching([name UTF8String], "media");
    if(prop != nullptr) {
        return [NSString stringWithUTF8String: prop->Value().c_str()];
    }

    return @"";
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


- (NSDictionary *)toDictionary {

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    NSMutableArray *smilDictionaries = [NSMutableArray array];
    for(LOXSmilModel *mo in _smilModels) {
        [smilDictionaries addObject:[mo toDictionary]];
    }

    [dict setObject:smilDictionaries forKey:@"smil_models"];
    [dict setObject:self.duration forKey:@"duration"];
    //[dict setObject:self.durationMilliseconds forKey:@"durationMilliseconds"];
    [dict setObject:self.narrator forKey:@"narrator"];

    return dict;
}

- (void)dealloc {
    [_smilModels release];
    [super dealloc];
}
@end