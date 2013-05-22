//
// Created by boriss on 2013-02-25.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXUserData.h"
#import "LOXBook.h"

@interface LOXUserData ()


//- (void)loadDataFromFile:(NSString *)file;

@property(retain, nonatomic, readwrite) NSArray *books;

@end


@implementation LOXUserData {

    NSMutableArray *_books;

}


@synthesize books = _books;

- (id)init
{

    self = [super init];
    if (self) {

        self.books = [NSMutableArray array];

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

        [ud synchronize];
    }
    @catch(NSException *ex)
    {
        NSLog(@"Error: %@", ex);
    }
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

    [_books release];
    [super dealloc];
}

- (void)addBook:(LOXBook *)book
{
    [_books addObject:book];
}

@end