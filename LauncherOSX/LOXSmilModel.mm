//
// Created by Boris Schneiderman on 2013-08-14.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXSmilModel.h"


@implementation LOXSmilModel {

    NSMutableArray *_children;

}

@synthesize children = _children;

-(id)init
{
    self = [super init];
    if (self){

        _children = [[NSMutableArray array] retain];

    }

    return self;
}

-(void)addItem:(NSDictionary*)item
{
    [_children addObject:item];
}

- (void)dealloc {
    [_children release];
    [super dealloc];
}

-(NSDictionary *)toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setObject:self.id forKey:@"id"];
    [dict setObject:self.spineItemId forKey:@"spineItemId"];
    [dict setObject:self.href forKey:@"href"];
    [dict setObject:self.smilVersion forKey:@"smilVersion"];
    [dict setObject:self.children forKey:@"children"];
    [dict setObject:self.duration forKey:@"duration"];

    return dict;
}

@end