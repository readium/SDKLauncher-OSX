//
// Created by boriss on 2013-01-22.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>
#import "LOXSpineItem.h"

@class LOXPackage;

@interface LOXSpineItemCocoa : NSObject<LOXSpineItem>  {

@private
    NSString* _idref;
    LOXPackage* _package;

}

@property(nonatomic, readonly) NSString *idref;
@property(nonatomic, readonly) LOXPackage *package;


- (id)initWithIdref:(NSString *)idref forPackage:(LOXPackage *)package;

- (NSString *)getHref;


@end