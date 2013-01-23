//
//  LOXAppDelegate.m
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

#import "LOXAppDelegate.h"
#import "LOXePubApi.h"

#include "container.h"


using namespace ePub3;

@interface LOXAppDelegate ()
- (NSString *)selectFile;
- (void) updateWebView;
- (void) initApiOfType:(ePubApiType)apiType;
- (void) openDocument;
- (void) reportError:(NSString *) error;
@end

@implementation LOXAppDelegate

- (void)dealloc
{
    [_epubApi release];
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    self.spineViewController.selectionChangedLiscener = self;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}

- (void)openDocument
{
    NSString *path = [self selectFile];

    if (path == nil) {
        return;
    }

    [self.spineViewController clear];

    [_epubApi openFile:path];

    NSArray *items = [_epubApi getSpineItems];

    for (id item in items) {
        [self.spineViewController addSpineItem:item];
    }

    if(items.count > 0) {
        [self.spineViewController selectSpineIndex:0];
    }

}

- (void)reportError:(NSString *)error
{
    NSLog(@"%@", error);

    NSAlert *alert = [[[NSAlert alloc] init] autorelease];
    [alert setMessageText:error];
    [alert runModal];
}


- (void)openDocumentWithSdkApi:(id)sender
{
    try {
        [self initApiOfType:kePubSdkApi];
        [self openDocument];
    }
    catch (NSException *e) {
        [self reportError:[e reason]];
    }
    catch (std::exception& e) {
        auto msg = e.what();
        [self reportError:[NSString stringWithUTF8String:msg]];
    }
    catch (...) {
        [self reportError:@"unknown exceprion"];
    }
}

- (void)openDocumentWithCocoaApi:(id)sender
{
    try {
        [self initApiOfType:kePubCocoaApi];
        [self openDocument];
    }
    catch (NSException *e) {
        [self reportError:[e reason]];
    }
    catch (std::exception& e) {
        auto msg = e.what();
        [self reportError:[NSString stringWithUTF8String:msg]];
    }
    catch (...) {
        [self reportError:@"unknown exceprion"];
    }
}


- (void)spineView:(LOXSpineViewController *)spineViewController selectionChangedTo:(id <LOXSpineItem>)spineItem
{
    self.currentSpineItem = spineItem;
    [self updateWebView];
}

- (NSString *)selectFile
{
    NSOpenPanel *dlg = [NSOpenPanel openPanel];

    NSArray *fileTypesArray = [NSArray arrayWithObjects:@"epub", nil];

    [dlg setCanChooseFiles:YES];
    [dlg setAllowedFileTypes:fileTypesArray];
    [dlg setAllowsMultipleSelection:FALSE];

    if ([dlg runModal] == NSOKButton) {
        NSURL *url = [dlg URL];

        return [url path];
    }

    return nil;
}

- (void)updateWebView
{
    if (self.currentSpineItem)
    {
        NSString * path = [_epubApi getPathToSpineItem:self.currentSpineItem];
        [self.webViewController displayUrlPath:path];
    }
    else
    {
        [self.webViewController clear];
    }
}

- (void)initApiOfType:(ePubApiType)apiType
{
     if(_epubApi) {
        if(_epubApi.apiType == apiType)   {
            return;
        }
        else{
            [_epubApi release];
        }
     }

     _epubApi = [[LOXePubApi ePubApiOfType:apiType] retain];
}




@end
