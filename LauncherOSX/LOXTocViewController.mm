//
// Created by boriss on 2013-03-15.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXTocViewController.h"
#import "LOXToc.h"
#import "LOXAppDelegate.h"


@implementation LOXTocViewController {

    LOXToc* _toc;

}

-(void)awakeFromNib
{
    [_outlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [_outlineView setTarget:self];
    [_outlineView setAction:@selector(clickInView:)];
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

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if(item == nil) {
        return nil;
    }

    LOXTocEntry * container = (LOXTocEntry *)item;

    if(container.contentRef.length > 0){
        NSTextFieldCell * cell = [[[NSTextFieldCell alloc] init] autorelease];
        [cell setTextColor:[NSColor blueColor]];
        [cell setBackgroundColor:[NSColor redColor]];
        return cell;
    }

    return nil;

}


//Prevent cell editing
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    return NO;
}

//Prevent call on selection changed
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView
{
    return NO;
}
//
- (NSIndexSet *)tableView:(NSTableView *)tableView selectionIndexesForProposedSelection:(NSIndexSet *)proposedSelectionIndexes
{
    return nil;
}

-(void)clickInView:(NSTableView *)tableView
{
    NSInteger rowIndex = [_outlineView clickedRow];
    NSInteger colIndex = [_outlineView clickedColumn];

    NSLog(@"row:%d, col %d", (int)rowIndex, (int)colIndex);

    if(rowIndex < 0) {
        return;
    }

    LOXTocEntry * entry = (LOXTocEntry*)[_outlineView itemAtRow: rowIndex];
    if(entry == nil || entry.contentRef.length == 0) {
        return;
    }

    [_appDelegate openContentDocRef:entry.contentRef];
}

@end