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


@interface LOXSpineViewController ()

@end

@implementation LOXSpineViewController

- (id)init
{
    self = [super init];
    if (self) {
        _spineItems = [[NSMutableArray alloc] init];
    }

    return self;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [_spineItems count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    LOXSpineItem *item = [_spineItems objectAtIndex:(NSUInteger) row];

    NSString* propIdentifier = [tableColumn identifier];
    return [item valueForKey:propIdentifier];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *tableView = notification.object;
    NSInteger row = [tableView selectedRow];

    LOXSpineItem *selectedItem = row == -1 ? nil : [_spineItems objectAtIndex:(NSUInteger) row];

    [self.selectionChangedLiscener spineView:self selectionChangedTo:selectedItem];
}

- (void)addSpineItem:(NSString *)spineItem
{
    [_spineItems addObject:spineItem];
    [_tableView reloadData];
}

- (void)clear
{
    [_spineItems removeAllObjects];
    [_tableView reloadData];
}

- (void)selectSpineIndex:(NSUInteger)index
{
    [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:index] byExtendingSelection:NO];
}


- (void)dealloc
{
    [self clear];
    [_spineItems release];
    [super dealloc];
}

@end
