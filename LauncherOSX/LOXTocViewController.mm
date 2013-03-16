//
// Created by boriss on 2013-03-15.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXTocViewController.h"
#import "LOXToc.h"


@implementation LOXTocViewController {

    LOXToc* _toc;

}

-(void) setToc:(LOXToc *)toc
{
    [_toc release];

    _toc = toc;
    [_toc retain];

    [_outlineView reloadData];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if(item == nil) { //root
        return _toc;
    }

    LOXTocEntry * container = (LOXTocEntry *)item;

    if(index >= container.children.count) {
        return nil;
    }

    return [container.children objectAtIndex:(NSUInteger) index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    LOXTocEntry *container = (LOXTocEntry *)item;

    return container.children.count > 0;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    //root level
    if(item == nil) {
        return _toc == nil ? 0 : 1;
    }

    LOXTocEntry *container = (LOXTocEntry *)item;

    return container.children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    LOXTocEntry *container = (LOXTocEntry *)item;

    return container.title;
}

- (void)dealloc
{
    [_toc release];
    [super dealloc];
}


@end