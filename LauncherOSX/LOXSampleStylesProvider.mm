//
// Created by Boris Schneiderman on 2013-07-31.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXSampleStylesProvider.h"



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
    NSString *commentsPattern = @"(?<!"")\\/\\*.+?\\*\\/(?!"")";

    NSError *error = NULL;
    NSRegularExpression *regexComments = [NSRegularExpression regularExpressionWithPattern:commentsPattern
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];


    content = [regexComments stringByReplacingMatchesInString:content
                                                      options:NSRegularExpressionCaseInsensitive
                                                        range:NSMakeRange(0, [content length])
                                                 withTemplate:@""];

    NSArray *tokens = [content componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"{}"]];

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    NSString* selector;
    NSString* style;

    for(NSUInteger i = 1; i < tokens.count; i = i + 2) {

        selector = [tokens[i-1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        style = tokens[i];

        NSString *trimmedStyle = [style stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if(selector.length > 0 && trimmedStyle.length > 0) {
            [dict setObject:[NSString stringWithFormat:@"{%@}", style] forKey:selector];
        }
    }

    return dict;
}

-(NSArray *)selectors
{
    return [_styles allKeys];
}

-(NSString *)styleForSelector:(NSString *)selector
{
    return _styles[selector];
}

- (void)dealloc
{
    [_styles release];
    [super dealloc];
}

@end