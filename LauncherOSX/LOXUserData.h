//
// Created by boriss on 2013-02-25.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class LOXBook;


@interface LOXUserData : NSObject


@property (retain, nonatomic, readonly) NSArray *books;

- (void)save;

- (LOXBook *)findBookForPath:(NSString *)path;


- (void)addBook:(LOXBook *)book;
@end