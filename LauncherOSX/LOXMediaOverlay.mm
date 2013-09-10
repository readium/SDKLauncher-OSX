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
        self.durationMilliseconds = [self parseSmilClockValueToMilliseconds: self.duration fromSdkPackage: sdkPackage];
        self.narrator = [self getProperty:@"narrator" fromPropertyHolder: sdkPackage];


        [self parseSmilsFromSdkPackage:sdkPackage];

    }

    // TESTS
    // http://www.w3.org/TR/SMIL3/smil-timing.html#Timing-ClockValueSyntax
    
    NSInteger time = 0;
    NSString* str = @"";
    
    // --- Full clock values
    
    // 2 hours, 30 minutes and 3 seconds
    // =2*60*60*1000+30*60*1000+3*1000+0
    str = @"02:30:03";
    time = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    NSLog(@"ASSERT: %ld", (long) 9003000);
    
    // 50 hours, 10 seconds and 250 milliseconds
    // =50*60*60*1000+0*60*1000+10*1000+250
    str = @"50:00:10.25";
    time = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    NSLog(@"ASSERT: %ld", (long) 180010250);
    
    // --- Partial clock values
    
    // 2 minutes and 33 seconds
    // =0*60*60*1000+2*60*1000+33*1000+0
    str = @"02:33";
    time = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    NSLog(@"ASSERT: %ld", (long) 153000);
    
    // 10.5 seconds = 10 seconds and 500 milliseconds
    // =0*60*60*1000+0*60*1000+10*1000+500
    str = @"00:10.5";
    time = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    NSLog(@"ASSERT: %ld", (long) 10500);
    
    // --- Timecount values
    
    // 3.2 hours = 3 hours and 12 minutes
    // =3*60*60*1000+12*60*1000+0*1000+0
    str = @"3.2h";
    time = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    NSLog(@"ASSERT: %ld", (long) 11520000);
    
    // 45 minutes
    // =0*60*60*1000+45*60*1000+0*1000+0
    str = @"45min";
    time = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    NSLog(@"ASSERT: %ld", (long) 2700000);
    
    // 30 seconds
    // =0*60*60*1000+0*60*1000+30*1000+0
    str = @"30s";
    time = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    NSLog(@"ASSERT: %ld", (long) 30000);
    
    // 5 milliseconds
    str = @"5ms";
    time = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    NSLog(@"ASSERT: %ld", (long) 5);
    
    // 12 seconds and 467 milliseconds
    // =0*60*60*1000+0*60*1000+12*1000+467
    str = @"12.467";
    time = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    NSLog(@"ASSERT: %ld", (long) 12467);
    
    // 500 milliseconds
    str = @"00.5s";
    time = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    NSLog(@"ASSERT: %ld", (long) 500);
    
    // 5 milliseconds
    str = @"00:00.005";
    time = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    NSLog(@"ASSERT: %ld", (long) 5);
    

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
                smilModel.durationMilliseconds = [self parseSmilClockValueToMilliseconds: smilModel.duration fromSdkPackage: sdkPackage];

                [_smilModels addObject:smilModel];
            }
        }
    }
}

- (NSInteger) parseSmilClockValueToMilliseconds:(NSString *)smilTime fromSdkPackage: (ePub3::PackagePtr)sdkPackage
{
    //ePub3::PackagePtr
    //std::shared_ptr<ePub3::Package>
    @try
    {
        NSLog(@"SMIL Clock Value String: %@", smilTime);
        
        NSInteger milliseconds = sdkPackage->ParseSmilClockValueToMilliseconds([smilTime UTF8String]);
        
        NSLog(@"SMIL Clock Value Milliseconds: %ld", (long) milliseconds);
    }
    @catch(NSException *ex)
    {
        NSLog(@"Error: %@", ex);
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