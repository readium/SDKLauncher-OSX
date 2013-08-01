//
// Created by Boris Schneiderman on 2013-08-01.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXCSSStyle.h"


@implementation LOXCSSStyle {


@private NSDictionary *_entries;

}

@synthesize entries = _entries;

- (id)initWithSelector:(NSString *)selector content:(NSString *)content entries:(NSDictionary *)entries {

    self = [super init];
    if(self) {
        self.selector = selector;
        self.content = content;
        _entries = entries;
        [_entries retain];

    }


    return self;
}

- (void)dealloc {
    [_entries release];
    [super dealloc];
}

@end