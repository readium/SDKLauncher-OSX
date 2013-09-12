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



@interface LOXMediaOverlay ()
//- (NSString *)getProperty:(NSString *)name fromPropertyHolder:(std::shared_ptr<ePub3::PropertyHolder>)sdkPropertyHolder;
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

        //auto duration = [self getProperty:@"duration" fromPropertyHolder: sdkPackage];

        auto metadata = ePub3::MediaOverlaysMetadata::GetDuration(sdkPackage);
        NSString* duration = metadata == nullptr ? @"" : [NSString stringWithUTF8String: metadata->c_str()];

        self.duration = [NSNumber numberWithDouble: ePub3::SmilClockValuesParser::ToSeconds([duration UTF8String])];
        NSLog(@"=== TOTAL MO DURATION: %s => %ldms", [duration UTF8String], (long) floor([self.duration doubleValue] * 1000.0));



        //self.narrator = [self getProperty:@"narrator" fromPropertyHolder: sdkPackage];

        auto narrator = ePub3::MediaOverlaysMetadata::GetNarrator(sdkPackage);
        self.narrator = narrator == nullptr ? @"" : [NSString stringWithUTF8String: narrator->c_str()];


        [self parseSmilsFromSdkPackage:sdkPackage];

    }

    return self;
}

- (void)parseSmilsFromSdkPackage:(ePub3::PackagePtr)sdkPackage
{
    double accumulatedDuration = 0.0;

    auto manifestTable =  sdkPackage->Manifest();

    for(auto iter = manifestTable.begin(); iter != manifestTable.end(); iter++) {

        auto item = iter->second;

        auto mediaType = item->MediaType();
        if(mediaType == "application/smil+xml") {

            LOXSmilModel * smilModel = [self createMediaOverlayForItem:item fromSdkPackage:sdkPackage];
            if(smilModel) {
                //auto duration = [self getProperty:@"duration" fromPropertyHolder:item];

                auto metadata = ePub3::MediaOverlaysMetadata::GetDuration(item);
                NSString* duration = metadata == nullptr ? @"" : [NSString stringWithUTF8String: metadata->c_str()];

                smilModel.duration = [NSNumber numberWithDouble: ePub3::SmilClockValuesParser::ToSeconds([duration UTF8String])];
                NSLog(@"=== [%s] DURATION: %s => %ldms", item->Href().c_str(), [duration UTF8String], (long) floor([smilModel.duration doubleValue] * 1000.0));

                accumulatedDuration += [smilModel.duration doubleValue];

                [_smilModels addObject:smilModel];
            }
        }
    }

    if (accumulatedDuration != [self.duration doubleValue])
    {
        NSLog(@"=== DURATION SUMMED != TOTAL (%ldms != %ldms)", (long)(accumulatedDuration * 1000.0), (long) floor([self.duration doubleValue] * 1000.0));
    }
    else
    {
        NSLog(@"=== DURATION SUM CHECK OKAY.");
    }
}

/*
- (NSString *)getProperty:(NSString *)name fromPropertyHolder:(std::shared_ptr<ePub3::PropertyHolder>)sdkPropertyHolder
{
    auto prop = sdkPropertyHolder->PropertyMatching([name UTF8String], "media");
    if(prop != nullptr) {
        return [NSString stringWithUTF8String: prop->Value().c_str()];
    }

    return @"";
}
*/

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