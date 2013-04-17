//
//  LOXSpineViewController.m
//  LauncherOSX
//
//  Created by Boris Schneiderman.
//  Copyright (c) 2012-2013 The Readium Foundation.
//
//  The Readium SDK is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "LOXSpineViewController.h"
#import "LOXSpineItem.h"
#import "LOXSpine.h"


@interface LOXSpineViewController ()

@end

@implementation LOXSpineViewController


- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_spine itemCount];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    LOXSpineItem *item = [[_spine items] objectAtIndex:(NSUInteger) row];

    NSString* propIdentifier = [tableColumn identifier];
    return [item valueForKey:propIdentifier];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    NSInteger row = [tableView selectedRow];

    LOXSpineItem * selectedItem = row == -1 ? nil : [[_spine items] objectAtIndex:(NSUInteger) row];

    [self.selectionChangedLiscener spineView:self selectionChangedTo:selectedItem];
}

- (void)selectSpieItem: (LOXSpineItem *) spineItem
{
    for (NSUInteger i = 0; i < _spine.itemCount; i++){
        if ([[_spine items] objectAtIndex:i] == spineItem) {
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:i];
            [_tableView selectRowIndexes:indexSet byExtendingSelection:NO];
            break;
        }
    }
}

- (void)setSpine:(LOXSpine *)spine
{
    [_spine release];

    _spine = spine;
    [_spine retain];

    [_tableView reloadData];
}

- (void)selectSpineIndex:(NSUInteger)index
{
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
}


- (void)dealloc
{
    [_spine release];
    [super dealloc];
}

@end
