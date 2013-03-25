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


#import "LOXScriptInjector.h"


@interface LOXScriptInjector ()
- (void)loadHtmlTemplate;

@property (nonatomic, retain) NSString *_htmlTemplate;

@end

@implementation LOXScriptInjector


- (id)init
{
    self = [super init];
    if (self){
        [self loadHtmlTemplate];
    }

    return self;
}

- (void)loadHtmlTemplate
{
    NSString* path = [[NSBundle mainBundle] pathForResource:@"reader" ofType:@"html" inDirectory:@"Scripts"];

    self.baseUrlPath = [path stringByDeletingLastPathComponent];

    self._htmlTemplate = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

    if (!self._htmlTemplate){
       @throw [NSException exceptionWithName:@"Resource Exception" reason:@"Resourse reader.html not found" userInfo:nil];
    }
}

-(NSString *)injectHtmlFile:(NSString *)path
{
    return [self._htmlTemplate stringByReplacingOccurrencesOfString:@"${CHAPTER}" withString:path];
}


@end