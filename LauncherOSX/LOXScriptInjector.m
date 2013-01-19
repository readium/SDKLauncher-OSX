//
// Created by boriss on 2013-01-18.
//
// To change the template use AppCode | Preferences | File Templates.
//


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