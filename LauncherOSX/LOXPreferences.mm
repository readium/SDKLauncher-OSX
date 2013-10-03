//
// Created by Boris Schneiderman on 2013-07-16.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXPreferences.h"


@implementation LOXPreferences {

    NSArray *_observableProperties;

}

- (id)init
{
    self = [super init];
    if(self) {

        self.fontSize = [NSNumber numberWithInt:100];
        self.isSyntheticSpread = [NSNumber numberWithBool:YES];
        self.mediaOverlaysSkipSkippables = [NSNumber numberWithBool:NO];
        self.mediaOverlaysEscapeEscapables = [NSNumber numberWithBool:YES];
        self.mediaOverlaysSkippables = [NSString stringWithUTF8String:""];
        self.mediaOverlaysEscapables = [NSString stringWithUTF8String:""];
        self.mediaOverlaysEnableClick = [NSNumber numberWithBool:YES];
        self.columnGap = [NSNumber numberWithInt:20];

        _observableProperties = [NSArray arrayWithObjects:@"fontSize",@"isSyntheticSpread",@"columnGap",@"mediaOverlaysSkipSkippables",@"mediaOverlaysEscapeEscapables",@"mediaOverlaysSkippables",@"mediaOverlaysEscapables",@"mediaOverlaysEnableClick",nil];
        [_observableProperties retain];
    }

    return self;
}


- (void)updateMediaOverlaysSkippables:(NSString *)str
{
    //self.mediaOverlaysSkippables = [NSString stringWithString:str];
    [self setMediaOverlaysSkippables:[NSString stringWithString:str]];
}

- (void)updateMediaOverlaysEscapables:(NSString *)str
{
    //self.mediaOverlaysEscapables = [NSString stringWithString:str];
    [self setMediaOverlaysEscapables:[NSString stringWithString:str]];
}


-(id)initWithDictionary:(NSDictionary *)dict
{
    self = [self init];
    if(self) {

        for (id key in dict.allKeys) {
            [self setValue:dict[key] forKey:key];
        }
    }

    return self;
}

-(NSDictionary *) toDictionary
{
    return @{  @"fontSize": self.fontSize,
               @"isSyntheticSpread": self.isSyntheticSpread,
               @"mediaOverlaysSkipSkippables": self.mediaOverlaysSkipSkippables,
               @"mediaOverlaysEscapeEscapables": self.mediaOverlaysEscapeEscapables,
               @"mediaOverlaysSkippables": self.mediaOverlaysSkippables,
               @"mediaOverlaysEscapables": self.mediaOverlaysEscapables,
               @"mediaOverlaysEnableClick": self.mediaOverlaysEnableClick,
               @"columnGap": self.columnGap};
}

-(void)registerChangeObserver:(NSObject *)observer
{
    for (id propertyName in _observableProperties) {
        [self registerChangeObserver:observer forProperty:propertyName];
    }

}

-(void)removeChangeObserver:(NSObject *)observer
{
    for (id propertyName in _observableProperties) {
        [self removeObserver:observer forKeyPath:propertyName];
    }
}


-(void)registerChangeObserver:(NSObject *)observer forProperty:(NSString *)property
{
    [self addObserver:observer
           forKeyPath:property
              options:NSKeyValueObservingOptionNew
              context:NULL];
}

- (void)dealloc {
    [_observableProperties release];
    [super dealloc];
}

@end