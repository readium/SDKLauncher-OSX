//  Created by Boris Schneiderman.
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

#import "LOXTocViewController.h"
#import "LOXToc.h"
#import "LOXAppDelegate.h"
#import "LOXPackage.h"


@interface LOXTocViewController ()
- (void)updateToc;

- (BOOL)isClickableItem:(LOXTocEntry *)item;

@end

@implementation LOXTocViewController {

    NSMutableArray *_cells;
    LOXPackage *_package;

}

-(id)init
{
    self = [super init];
    if(self) {
        _cells = [NSMutableArray array];
    }

    return self;
}

-(void)awakeFromNib
{
    [_outlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [_outlineView setTarget:self];
    [_outlineView setAction:@selector(clickInView:)];
}

-(void)updateToc
{
    [_cells removeAllObjects];
    [_outlineView reloadData];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if(item == nil) { //root
        return _package.toc;
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
        return _package.toc == nil ? 0 : 1;
    }

    LOXTocEntry *container = (LOXTocEntry *)item;

    return container.children.count;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    LOXTocEntry *container = (LOXTocEntry *)item;

    return container.title;
}


- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    if(item == nil) {
        return nil;
    }

    LOXTocEntry * container = (LOXTocEntry *)item;

    if([self isClickableItem: container]){
        NSTextFieldCell * cell = [[NSTextFieldCell alloc] init];
        [cell setTextColor:[NSColor blueColor]];
        [cell setBackgroundColor:[NSColor redColor]];
        cell.selectable = YES;

        [_cells addObject:cell];
        return cell;
    }

    return nil;

}

-(BOOL)isClickableItem:(LOXTocEntry*) item
{
    return item.contentRef.length > 0;
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

    if(rowIndex < 0) {
        return;
    }

    LOXTocEntry * entry = (LOXTocEntry*)[_outlineView itemAtRow: rowIndex];
    if(entry == nil || entry.contentRef.length == 0) {
        return;
    }

    [_appDelegate openContentUrl:entry.contentRef fromSourceFileUrl:_package.toc.sourceHref];
}


////because entry contentRef can be relative to the toc file but spine item are relative to the package document
////we have to build the href path from toc location and entry content ref
//-(NSString*) resolveContentRef:(NSString *)contentRef
//{
//    if(_package.toc.sourcerHref.length == 0) {
//        return contentRef;
//    }
//
//    //count and remove leading parent directory navigation ".."
//    NSArray *contentPathComponents = [contentRef componentsSeparatedByString:@"/"];
//
//    int parentNavCount = 0;
//    for(NSString *part in contentPathComponents) {
//
//        if(![part isEqualToString: @".."]) {
//            break;
//        }
//
//        parentNavCount++;
//    }
//
//    NSRange range;
//    range.location = parentNavCount;
//    range.length = contentPathComponents.count - parentNavCount;
//    contentPathComponents = [contentPathComponents subarrayWithRange:range];
//    NSString * cleanedContentRef = [contentPathComponents componentsJoinedByString:@"/"];
//
//    //remove trailing directory navigation equal parent navigation count for contentRef path (above)
//    //remove toc file name
//    NSString *tocDir = [_package.toc.sourcerHref stringByDeletingLastPathComponent];
//
//    while(parentNavCount > 0 && tocDir.length > 0) {
//        tocDir = [tocDir stringByDeletingLastPathComponent];
//        parentNavCount--;
//    }
//
//
//    NSString* combinedPath = [tocDir stringByAppendingPathComponent:cleanedContentRef] ;
//
//    return combinedPath;
//}

- (void)setPackage:(LOXPackage *)package
{
    _package = package;

    [self updateToc];

}
@end