//
// Created by Boris Schneiderman on 2013-07-16.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXPreferences.h"


@implementation LOXPreferences {

    NSArray *_observableProperties;
    bool _doNotUpdateView;
}

- (void)setDoNotUpdateView:(bool)doNotUpdate
{
    _doNotUpdateView = doNotUpdate;
}

-(bool) isMediaOverlayProperty:(NSString*)name
{
    return     [name isEqualToString:NSStringFromSelector(@selector(mediaOverlaysSkipSkippables))]
            || [name isEqualToString:NSStringFromSelector(@selector(mediaOverlaysEscapeEscapables))]
            || [name isEqualToString:NSStringFromSelector(@selector(mediaOverlaysEnableClick))]
            || [name isEqualToString:NSStringFromSelector(@selector(mediaOverlaysEscapables))]
            || [name isEqualToString:NSStringFromSelector(@selector(mediaOverlaysSkippables))]
            || [name isEqualToString:NSStringFromSelector(@selector(mediaOverlaysRate))]
            || [name isEqualToString:NSStringFromSelector(@selector(mediaOverlaysVolume))];
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
        self.mediaOverlaysRate = [NSNumber numberWithInt:1];
        self.mediaOverlaysVolume = [NSNumber numberWithInt:100];
        self.isScrollDoc = [NSNumber numberWithBool:NO];
        self.isScrollContinuous = [NSNumber numberWithBool:NO];

        _doNotUpdateView = NO;

        _observableProperties = [NSArray arrayWithObjects:
                NSStringFromSelector(@selector(fontSize)),
                        NSStringFromSelector(@selector(isSyntheticSpread)),
                        NSStringFromSelector(@selector(columnGap)),
                        NSStringFromSelector(@selector(mediaOverlaysSkipSkippables)),
                        NSStringFromSelector(@selector(mediaOverlaysEscapeEscapables)),
                        NSStringFromSelector(@selector(mediaOverlaysSkippables)),
                        NSStringFromSelector(@selector(mediaOverlaysEscapables)),
                        NSStringFromSelector(@selector(mediaOverlaysEnableClick)),
                        NSStringFromSelector(@selector(mediaOverlaysRate)),
                        NSStringFromSelector(@selector(mediaOverlaysVolume)),
                        NSStringFromSelector(@selector(isScrollDoc)),
                        NSStringFromSelector(@selector(isScrollContinuous)),
                        nil];
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
            
            @try
            {
                [self setValue:dict[key] forKey:key];
            }
            @catch(NSException *ex)
            {
                NSLog(@"Error: %@", ex);
            }
        }
    }

    return self;
}

-(NSDictionary *) toDictionary
{
    return @{
            NSStringFromSelector(@selector(fontSize)): self.fontSize,
            NSStringFromSelector(@selector(isSyntheticSpread)): self.isSyntheticSpread,
            NSStringFromSelector(@selector(mediaOverlaysSkipSkippables)): self.mediaOverlaysSkipSkippables,
            NSStringFromSelector(@selector(mediaOverlaysEscapeEscapables)): self.mediaOverlaysEscapeEscapables,
            NSStringFromSelector(@selector(mediaOverlaysSkippables)): self.mediaOverlaysSkippables,
            NSStringFromSelector(@selector(mediaOverlaysEscapables)): self.mediaOverlaysEscapables,
            NSStringFromSelector(@selector(mediaOverlaysEnableClick)): self.mediaOverlaysEnableClick,
            NSStringFromSelector(@selector(mediaOverlaysRate)): self.mediaOverlaysRate,
            NSStringFromSelector(@selector(mediaOverlaysVolume)): self.mediaOverlaysVolume,
            NSStringFromSelector(@selector(columnGap)): self.columnGap,
            NSStringFromSelector(@selector(isScrollDoc)): self.isScrollDoc,
            NSStringFromSelector(@selector(isScrollContinuous)): self.isScrollContinuous,
            NSStringFromSelector(@selector(doNotUpdateView)): [NSNumber numberWithBool:_doNotUpdateView]
    };
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

@end