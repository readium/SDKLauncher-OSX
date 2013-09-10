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

    [self UnitTestSmilClockValueParser:sdkPackage];

    return self;
}

- (void) UnitTestSmilClockValueParser:(ePub3::PackagePtr)sdkPackage
{
    // BASIC UNIT TESTS
    // http://www.w3.org/TR/SMIL3/smil-timing.html#Timing-ClockValueSyntax
    // http://www.idpf.org/epub/30/spec/epub30-mediaoverlays.html#app-clock-examples
    // See also:
    // http://www.w3.org/TR/smil-animation/#TimingAttrValGrammars
    // http://dxr.mozilla.org/mozilla-central/source/content/smil/test/test_smilTiming.xhtml

    NSInteger timeObtained = 0;
    NSInteger timeExpected = 0;
    NSString* str = @"";

    // --- Full clock values

    // 2 hours, 30 minutes and 3 seconds
    // =2*60*60*1000+30*60*1000+3*1000+0
    str = @"02:30:03";
    timeExpected = 9003000;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 50 hours, 10 seconds and 250 milliseconds
    // =50*60*60*1000+0*60*1000+10*1000+250
    str = @"50:00:10.25";
    timeExpected = 180010250;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // --- Partial clock values

    // 2 minutes and 33 seconds
    // =0*60*60*1000+2*60*1000+33*1000+0
    str = @"02:33";
    timeExpected = 153000;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 10.5 seconds = 10 seconds and 500 milliseconds
    // =0*60*60*1000+0*60*1000+10*1000+500
    str = @"00:10.5";
    timeExpected = 10500;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // --- Timecount values

    // 3.2 hours = 3 hours and 12 minutes
    // =3*60*60*1000+12*60*1000+0*1000+0
    str = @"3.2h";
    timeExpected = 11520000;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 45 minutes
    // =0*60*60*1000+45*60*1000+0*1000+0
    str = @"45min";
    timeExpected = 2700000;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 30 seconds
    // =0*60*60*1000+0*60*1000+30*1000+0
    str = @"30s";
    timeExpected = 30000;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 5 milliseconds
    str = @"5ms";
    timeExpected = 5;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 12 seconds and 467 milliseconds
    // =0*60*60*1000+0*60*1000+12*1000+467
    str = @"12.467";
    timeExpected = 12467;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 500 milliseconds
    str = @"00.5s";
    timeExpected = 500;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 5 milliseconds
    str = @"00:00.005";
    timeExpected = 5;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 5 hours, 34 minutes, 31 seconds and 396 milliseconds
    // =5*60*60*1000+34*60*1000+31*1000+396
    str = @"5:34:31.396";
    timeExpected = 20071396;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 124 hours, 59 minutes and 36 seconds
    // =124*60*60*1000+59*60*1000+36*1000+0
    str = @"124:59:36";
    timeExpected = 449976000;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 5 minutes, 1 second and 200 milliseconds
    // =0*60*60*1000+5*60*1000+1*1000+200
    str = @"0:05:01.2";
    timeExpected = 301200;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 4 seconds
    // =0*60*60*1000+0*60*1000+4*1000+0
    str = @"0:00:04";
    timeExpected = 4000;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 9 minutes and 58 seconds
    // =0*60*60*1000+9*60*1000+58*1000+0
    str = @"09:58";
    timeExpected = 598000;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 56 seconds and 780 milliseconds
    // =0*60*60*1000+0*60*1000+56*1000+780
    str = @"00:56.78";
    timeExpected = 56780;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 76.2 seconds = 76 seconds and 200 milliseconds
    // =0*60*60*1000+0*60*1000+76*1000+200
    str = @"76.2s";
    timeExpected = 76200;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 7.75 hours = 7 hours and 45 minutes
    // =7*60*60*1000+45*60*1000+0*1000+0
    str = @"7.75h";
    timeExpected = 27900000;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 13 minutes
    // =0*60*60*1000+13*60*1000+0*1000+0
    str = @"13min";
    timeExpected = 780000;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 2345 milliseconds
    // =0*60*60*1000+0*60*1000+0*1000+2345
    str = @"2345ms";
    timeExpected = 2345;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];

    // 12 seconds and 345 milliseconds
    // =0*60*60*1000+0*60*1000+12*1000+345
    str = @"12.345";
    timeExpected = 12345;
    timeObtained = [self parseSmilClockValueToMilliseconds: str fromSdkPackage: sdkPackage];
    [self AssertSmilClockValueParsedToMilliseconds:str withTimeExpected:timeExpected withTimeObtained:timeObtained];
}

- (void) AssertSmilClockValueParsedToMilliseconds:(NSString*) str withTimeExpected:(NSInteger)timeExpected withTimeObtained:(NSInteger)timeObtained
{
    NSLog(@"=== timeExpected: %ld", (long) timeExpected);
    NSLog(@"=== timeObtained: %ld", (long) timeObtained);
    if (timeExpected != timeObtained)
    {
        NSLog(@"!!! ERROR");
        //@throw [NSException exceptionWithName:@"SMIL Clock Value Parsing Error" reason:@"timeExpected != timeObtained" userInfo:nil];
    }


    NSInteger timeBoris = [self checkBorisParser: str];
    NSLog(@"=== timeBoris: %ld", (long) timeBoris);
    if (timeExpected != timeBoris)
    {
        NSLog(@"!!! BORIS_ERROR");
        //@throw [NSException exceptionWithName:@"SMIL Clock Value Boris-Parsing Error" reason:@"timeExpected != timeBoris" userInfo:nil];
    }
}

- (NSInteger)checkBorisParser:(NSString *) str
{
    NSNumber* checkBorisParser = [self parseTimestamp: str];
    NSInteger time = (int)(checkBorisParser.doubleValue * 1000.0);
    //NSLog(@"~~~ checkBorisParser: %ld", (long)time);
    return time;

}

- (NSNumber *)parseTimestamp:(NSString *)timestamp
{
    double hours = 0;
    double minutes = 0;
    double seconds = 0;

    NSString *valString;
    if((valString = [self substringFromString:timestamp withSuffix:@"min"]) ) {
        minutes = [valString doubleValue];
    }
    else if((valString = [self substringFromString:timestamp withSuffix:@"ms"])) {
        seconds = [valString doubleValue] * 1000;
    }
    else if((valString = [self substringFromString:timestamp withSuffix:@"s"])) {
        seconds = [valString doubleValue];
    }
    else if((valString = [self substringFromString:timestamp withSuffix:@"h"])) {
        hours = [valString doubleValue];
    }
    else {

        NSArray* tokens = [timestamp componentsSeparatedByString:@":"];
        if(tokens.count > 0) {
            seconds = [tokens[tokens.count - 1] doubleValue];
        }

        if(tokens.count > 1) {
            minutes = [tokens[tokens.count - 2] doubleValue];
        }

        if(tokens.count > 2) {
            hours = [tokens[tokens.count - 3] doubleValue];
        }

    }

    return [NSNumber numberWithDouble: hours * 3600 + minutes * 60 + seconds ];
}

-(NSString *)substringFromString:(NSString *)string withSuffix:(NSString *)suffix
{
    NSRange range = [string rangeOfString:suffix];

    if(range.location == NSNotFound) {
        return nil;
    }

    return [string substringToIndex:range.location];
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

        return milliseconds;
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