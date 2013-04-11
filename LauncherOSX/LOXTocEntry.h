//
// Created by boriss on 2013-03-15.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>



@interface LOXTocEntry : NSObject

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *contentRef;
@property (nonatomic, readonly) NSArray *children;

- (void)addChild:(LOXTocEntry *)child;

@end