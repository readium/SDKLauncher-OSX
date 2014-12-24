//
// Created by Boris Schneiderman on 2013-07-16.
//
//  Copyright (c) 2014 Readium Foundation and/or its licensees. All rights reserved.
//  
//  Redistribution and use in source and binary forms, with or without modification, 
//  are permitted provided that the following conditions are met:
//  1. Redistributions of source code must retain the above copyright notice, this 
//  list of conditions and the following disclaimer.
//  2. Redistributions in binary form must reproduce the above copyright notice, 
//  this list of conditions and the following disclaimer in the documentation and/or 
//  other materials provided with the distribution.
//  3. Neither the name of the organization nor the names of its contributors may be 
//  used to endorse or promote products derived from this software without specific 
//  prior written permission.
//  
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
//  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
//  IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
//  OF THE POSSIBILITY OF SUCH DAMAGE.

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
        self.mediaOverlaysSkipSkippables = [NSNumber numberWithBool:NO];
        self.mediaOverlaysEscapeEscapables = [NSNumber numberWithBool:YES];
        self.mediaOverlaysSkippables = [NSString stringWithUTF8String:""];
        self.mediaOverlaysEscapables = [NSString stringWithUTF8String:""];
        self.mediaOverlaysEnableClick = [NSNumber numberWithBool:YES];
        self.columnGap = [NSNumber numberWithInt:20];
        self.mediaOverlaysRate = [NSNumber numberWithInt:1];
        self.mediaOverlaysVolume = [NSNumber numberWithInt:100];
        
        self.syntheticSpread = @"auto";
        self.scroll = @"auto";

        _doNotUpdateView = NO;

        _observableProperties = [NSArray arrayWithObjects:
                NSStringFromSelector(@selector(fontSize)),
                        NSStringFromSelector(@selector(columnGap)),
                        NSStringFromSelector(@selector(mediaOverlaysSkipSkippables)),
                        NSStringFromSelector(@selector(mediaOverlaysEscapeEscapables)),
                        NSStringFromSelector(@selector(mediaOverlaysSkippables)),
                        NSStringFromSelector(@selector(mediaOverlaysEscapables)),
                        NSStringFromSelector(@selector(mediaOverlaysEnableClick)),
                        NSStringFromSelector(@selector(mediaOverlaysRate)),
                        NSStringFromSelector(@selector(mediaOverlaysVolume)),
                                 
                        NSStringFromSelector(@selector(scroll)),
                        NSStringFromSelector(@selector(syntheticSpread)),
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
            @"enableGPUHardwareAccelerationCSS3D": [NSNumber numberWithBool:NO],

            NSStringFromSelector(@selector(fontSize)): self.fontSize,
            NSStringFromSelector(@selector(mediaOverlaysSkipSkippables)): self.mediaOverlaysSkipSkippables,
            NSStringFromSelector(@selector(mediaOverlaysEscapeEscapables)): self.mediaOverlaysEscapeEscapables,
            NSStringFromSelector(@selector(mediaOverlaysSkippables)): self.mediaOverlaysSkippables,
            NSStringFromSelector(@selector(mediaOverlaysEscapables)): self.mediaOverlaysEscapables,
            NSStringFromSelector(@selector(mediaOverlaysEnableClick)): self.mediaOverlaysEnableClick,
            NSStringFromSelector(@selector(mediaOverlaysRate)): self.mediaOverlaysRate,
            NSStringFromSelector(@selector(mediaOverlaysVolume)): self.mediaOverlaysVolume,
            NSStringFromSelector(@selector(columnGap)): self.columnGap,
            
            NSStringFromSelector(@selector(syntheticSpread)): self.syntheticSpread,
            NSStringFromSelector(@selector(scroll)): self.scroll,

            
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