//
//  LOXUtil.m
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

#import "LOXUtil.h"

@implementation LOXUtil

+ (NSString *)uuid
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return [(NSString *) string autorelease];
}

+ (void)ensureDirectoryForFile:(NSString*)filePath
{
    NSString * dirPath = [filePath stringByDeletingLastPathComponent];

    NSError * error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
    if (error != nil) {
        NSLog(@"error creating directory: %@", error);
    }
}

+(id)valueForKey:(NSString *)keyName orDefault:(id)defaultValue fromDictionary:(NSDictionary*)dict
{
    id val = [dict objectForKey:keyName];
    return val ? val : defaultValue;
}

@end
