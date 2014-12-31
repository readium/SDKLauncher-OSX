//
//  LOXSpineViewController.m
//  LauncherOSX
//
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

#import "LOXSpineViewController.h"
#import "LOXSpineItem.h"
#import "LOXSpine.h"
#import "LOXPackage.h"
#import "LOXCurrentPagesInfo.h"
#import "LOXOpenPageInfo.h"
#import "LOXAppDelegate.h"


@interface LOXSpineViewController ()

- (void)onPageChanged:(id)onPageChanged;

- (LOXSpineItem *)getOpenSpineItem;
@end

@implementation LOXSpineViewController {

    LOXPackage *_package;

}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onPageChanged:)
                                                 name:LOXPageChangedEvent
                                               object:nil];
}

- (void)onPageChanged:(id)onPageChanged
{
    LOXSpineItem *openSpineItem = [self getOpenSpineItem];

    if(!openSpineItem) {
        return;
    }

    [self selectSpieItem:openSpineItem];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_package.spine itemCount];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    LOXSpineItem *item = [[_package.spine items] objectAtIndex:(NSUInteger) row];

    NSString* propIdentifier = [tableColumn identifier];
    return [item valueForKey:propIdentifier];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    LOXSpineItem * selectedItem = [self getSelectedItem];

    if(!selectedItem) {
        return;
    }

    LOXSpineItem *openSpineItem = [self getOpenSpineItem];

    if(selectedItem != openSpineItem) {
        [self.selectionChangedLiscener spineView:self selectionChangedTo:selectedItem];
    }
}

- (LOXSpineItem *)getOpenSpineItem
{
    LOXOpenPageInfo *openPage = self.currentPagesInfo.firstOpenPage;

    if(!openPage) {
        return nil;
    }

    return [_package.spine getSpineItemWithId:openPage.idref];
}

- (LOXSpineItem *)getSelectedItem
{
    NSInteger row = [_tableView selectedRow];
    LOXSpineItem * selectedItem = row == -1 ? nil : [[_package.spine items] objectAtIndex:(NSUInteger) row];
    return selectedItem;
}

- (void)selectSpieItem: (LOXSpineItem *) spineItem
{
    for (NSUInteger i = 0; i < _package.spine.itemCount; i++){
        if ([[_package.spine items] objectAtIndex:i] == spineItem) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:i];
            [_tableView selectRowIndexes:indexSet byExtendingSelection:NO];
            break;
        }
    }
}

- (void)setPackage:(LOXPackage *)package
{
    _package = package;

    [_tableView reloadData];
}


@end
