//
// Created by boriss on 2013-01-18.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface LOXScriptInjector : NSObject    {

@private


}

@property (nonatomic, retain) NSString *baseUrlPath;

-(id)init;

- (NSString *)injectHtmlFile:(NSString *)path;


@end