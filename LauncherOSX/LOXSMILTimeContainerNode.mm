//
// Created by Boris Schneiderman on 2013-08-14.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXSMILTimeContainerNode.h"


@implementation LOXSMILTimeContainerNode {

    NSMutableArray *_children;

}

@synthesize childern = _children;

-(id)init
{
    self = [super init];
    if (self){

        _children = [[NSMutableArray array] retain];

    }

    return self;
}

- (void)dealloc {
    [_children release];
    [super dealloc];
}


@end