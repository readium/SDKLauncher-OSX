//
// Created by Boris Schneiderman on 2013-08-06.
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
//  OF THE POSSIBILITY OF SUCH DAMAGE.//
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

            LOXCSSStyle *style = [[LOXCSSStyle alloc] initWithSelector:selector declarationsBlock:block];
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