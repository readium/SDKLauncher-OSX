//
// Created by Boris Schneiderman on 2013-08-06.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXCSSParser.h"
#import "LOXCSSStyle.h"


@interface LOXCSSParser ()
+ (NSString *)removeCommentsFromString:(NSString *)string;
@end

@implementation LOXCSSParser {

}

+ (NSArray *)parseCSS:(NSString *)cssContent
{
    cssContent = [self removeCommentsFromString:cssContent];

    NSError *error = NULL;

//    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([^{]+)\\s*\\{\\s*([^}]+)\\s*\\}"
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([^{]+)\\{([^}]+)\\}"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];

    NSArray *matches = [regex matchesInString:cssContent
                                      options:0
                                        range:NSMakeRange(0, [cssContent length])];

    NSMutableArray *array = [NSMutableArray array];

    for(NSTextCheckingResult *match in matches) {

        if(match.numberOfRanges == 3) {

            NSString *selector = [cssContent substringWithRange:[match rangeAtIndex:1]];
            selector = [selector stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *block = [cssContent substringWithRange:[match rangeAtIndex:2]];
            block = [NSString stringWithFormat:@"{%@}", block];

            LOXCSSStyle *style = [[[LOXCSSStyle alloc] initWithSelector:selector declarationsBlock:block] autorelease];
            [array addObject:style];
        }

    }

    return array;

}

+ (NSDictionary *)parseDeclarationsString:(NSString *)block error:(NSError**)error
{
    block = [block stringByReplacingOccurrencesOfString:@"{" withString:@""];
    block = [block stringByReplacingOccurrencesOfString:@"}" withString:@""];

    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(.+?):(.+?);"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:error];

    if(*error) {
        return nil;
    }

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

+(NSString*) removeCommentsFromString:(NSString*)string
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


@end