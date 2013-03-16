//
// Created by boriss on 2013-03-15.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXTocEntry.h"


@implementation LOXTocEntry {

    NSMutableArray* _children;

}

@synthesize children = _children;

- (id)init
{
    if ((self = [super init])) {
        _children = [[NSMutableArray alloc] init];
        self.contentRef = @"";

    }
    return self;
}

- (void)dealloc
{
    [_children release];
    [super dealloc];
}


-(void)addChild:(LOXTocEntry*)child
{
    [_children addObject:child];
}

@end