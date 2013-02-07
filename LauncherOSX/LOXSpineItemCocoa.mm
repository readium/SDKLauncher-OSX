//
// Created by boriss on 2013-01-22.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXSpineItemCocoa.h"
#import "LOXPackage.h"


@implementation LOXSpineItemCocoa

@synthesize idref = _idref;
@synthesize package = _package;

- (id)initWithIdref:(NSString *)idref forPackage:(LOXPackage*) package
{
    self = [super init];
    if(self) {
        _idref = idref;
        [_idref retain];
        _package = package;
    }

    return self;
}

-(NSString *) getHref
{
    return [_package getHrefForItem:self];
}

- (void)dealloc
{
    [_idref release];
    [super dealloc];
}

@end