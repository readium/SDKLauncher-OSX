//
// Created by Boris Schneiderman on 2013-07-31.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXSampleStylesProvider.h"
#import "LOXCSSStyle.h"


@implementation LOXSampleStylesProvider {

    NSDictionary *_styles;
}


- (id)init
{
    self = [super init];

    if(self) {

        NSString* path = [[NSBundle mainBundle] pathForResource:@"sample_styles" ofType:@"css"];

        NSString* content = [NSString stringWithContentsOfFile:path
                                                      encoding:NSUTF8StringEncoding
                                                         error:NULL];

        _styles = [[self parseCSS:content] retain];
    }

    return self;
}

- (NSDictionary *)parseCSS:(NSString *)content
{
    content = [self removeCommentsFromString:content];

    NSError *error = NULL;

//    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([^{]+)\\s*\\{\\s*([^}]+)\\s*\\}"
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([^{]+)\\{([^}]+)\\}"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];

    NSArray *matches = [regex matchesInString:content
                                      options:0
                                        range:NSMakeRange(0, [content length])];

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    for(NSTextCheckingResult *match in matches) {

        if(match.numberOfRanges == 3) {

            NSString *selector = [content substringWithRange:[match rangeAtIndex:1]];
            selector = [selector stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *block = [content substringWithRange:[match rangeAtIndex:2]];
            NSDictionary *declarations = [self parseStatementsFromBlock:block];

            LOXCSSStyle *style = [[[LOXCSSStyle alloc] initWithSelector:selector content:block declarations:declarations] autorelease];
            [dict setObject:style forKey:style.selector];
        }

    }

    return dict;

}

- (NSDictionary *)parseStatementsFromBlock:(NSString *)block {

    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(.+?):(.+?);"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];

    NSArray *matches = [regex matchesInString:block
                                      options:0
                                        range:NSMakeRange(0, [block length])];

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    for(NSTextCheckingResult *match in matches) {

        if(match.numberOfRanges == 3) {

            NSString *name = [block substringWithRange:[match rangeAtIndex:1]];
            name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *value = [block substringWithRange:[match rangeAtIndex:2]];
            value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

            [dict setObject:value forKey:name];
        }

    }

    return dict;
}

-(NSString*) removeCommentsFromString:(NSString*)string
{
    NSError *error = NULL;
    NSString *commentsPattern = @"(?<!"")\\/\\*.+?\\*\\/(?!"")";

    NSRegularExpression *regexComments = [NSRegularExpression regularExpressionWithPattern:commentsPattern
                                                                                   options:NSRegularExpressionCaseInsensitive
                                                                                     error:&error];


    return [regexComments stringByReplacingMatchesInString:string
                                                      options:NSRegularExpressionCaseInsensitive
                                                        range:NSMakeRange(0, [string length])
                                                 withTemplate:@""];
}


-(NSArray *)selectors
{
    return [_styles allKeys];
}

-(LOXCSSStyle *)styleForSelector:(NSString *)selector
{
    return _styles[selector];
}

- (void)dealloc
{
    [_styles release];
    [super dealloc];
}

@end