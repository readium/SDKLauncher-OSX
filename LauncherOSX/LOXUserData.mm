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


#import "LOXUserData.h"
#import "LOXBook.h"
#import "LOXPreferences.h"

@interface LOXUserData ()


//- (void)loadDataFromFile:(NSString *)file;

@property(retain, nonatomic, readwrite) NSArray *books;

@end


@implementation LOXUserData {

    NSMutableArray *_books;
    LOXPreferences *_preferences;

}


@synthesize books = _books;
@synthesize preferences = _preferences;

- (id)init
{

    self = [super init];
    if (self) {

        self.books = [NSMutableArray array];
        self.preferences = [[[LOXPreferences alloc] init] autorelease];

        [self load];
    }

    return self;
}

-(void)load
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    NSArray * arr = [ud objectForKey:@"books"];

    for(NSDictionary * dict in arr) {

        [self addBook:[LOXBook bookFromDictionary:dict]];
    }

    NSDictionary * dict = [ud objectForKey:@"preferences"];

    self.preferences = [dict ? ([[LOXPreferences alloc] initWithDictionary:dict])
                                : ([[LOXPreferences alloc] init]) autorelease];
}

- (void)save
{
    @try
    {
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

        NSMutableArray *books = [NSMutableArray array];

        for (LOXBook *book in self.books) {
            [books addObject:[book toDictionary]];
        }

        [ud setObject:books forKey:@"books"];

        [ud setObject:[self.preferences toDictionary] forKey:@"preferences"];

        [ud synchronize];
    }
    @catch(NSException *ex)
    {
        NSLog(@"Error: %@", ex);
    }
}

- (LOXBook *)findBookWithId:(NSString *)packageId
{
    for (LOXBook *book in self.books) {
        if ([book.packageId compare:packageId] == NSOrderedSame) {
            return book;
        }
    }

    return nil;
}

- (LOXBook *)findBookForPath:(NSString *)path
{
    for (LOXBook *book in self.books) {
        if ([book.filePath caseInsensitiveCompare:path] == NSOrderedSame) {
            return book;
        }
    }

    return nil;
}

- (void)dealloc
{
    [_preferences release];
    [_books release];
    [super dealloc];
}

- (void)addBook:(LOXBook *)book
{
    [_books addObject:book];
}

@end