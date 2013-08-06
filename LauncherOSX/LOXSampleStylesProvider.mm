//
// Created by Boris Schneiderman on 2013-07-31.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXSampleStylesProvider.h"
#import "LOXCSSStyle.h"
#import "LOXCSSParser.h"


@implementation LOXSampleStylesProvider {

    NSDictionary *_styles;
}


- (id)init
{
    self = [super init];

    if(self) {

        NSString* path = [[NSBundle mainBundle] pathForResource:@"sample_styles" ofType:@"css"];

        NSString* content = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];


        _styles = [[LOXCSSParser parseCSS:content] retain];
    }

    return self;
}

-(NSArray *)selectors
{
    return [_styles allKeys];
}

-(LOXCSSStyle *)styleForSelector:(NSString *)selector
{
    return _styles[selector];
}

- (void)dealloc
{
    [_styles release];
    [super dealloc];
}

@end