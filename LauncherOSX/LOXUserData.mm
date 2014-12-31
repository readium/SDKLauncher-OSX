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

#import "LOXUserData.h"
#import "LOXBook.h"
#import "LOXPreferences.h"

@interface LOXUserData ()


//- (void)loadDataFromFile:(NSString *)file;

@property(strong, nonatomic, readwrite) NSArray *books;

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
        self.preferences = [[LOXPreferences alloc] init];

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

    self.preferences = dict ? ([[LOXPreferences alloc] initWithDictionary:dict])
                                : ([[LOXPreferences alloc] init]);
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

- (LOXBook *)findBookWithId:(NSString *)packageId fileName:(NSString*)fileName
{
    for (LOXBook *book in self.books) {
        if (   [book.packageId compare:packageId] == NSOrderedSame
            && [[book.filePath lastPathComponent] caseInsensitiveCompare:fileName] == NSOrderedSame) {
            return book;
        }
    }

    return nil;
}


- (void)addBook:(LOXBook *)book
{
    [_books addObject:book];
}

@end