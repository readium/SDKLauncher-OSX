//  Created by Boris Schneiderman.
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
//  OF THE POSSIBILITY OF SUCH DAMAGE.

#import "LOXBookmark.h"
#import "LOXBook.h"


@implementation LOXBookmark

@synthesize idref;
@synthesize book;
@synthesize title;
@synthesize spineItemCFI;
@synthesize contentCFI;
@synthesize basePath = _basePath;


+(id) bookmarkFromDictionary:(NSDictionary *)dict
{
    LOXBookmark * bookmark = [[LOXBookmark alloc] init];

    for (id key in dict.allKeys) {
        [bookmark setValue:dict[key] forKey:key];
    }

    return bookmark;
}

-(NSDictionary *) toDictionary
{
    return @{@"idref"        : self.idref,
             @"basePath"     : self.basePath,
             @"title"        : self.title,
             @"spineItemCFI" : self.spineItemCFI,
             @"contentCFI"   : self.contentCFI };
}

- (id) init
{
    self = [super init];

    if(self) {
        self.idref = @"";
        self.basePath = @"";
        self.title = @"";
        self.spineItemCFI = @"";
        self.contentCFI = @"";
    }

    return self;
}

- (bool)isNew
{
    return self.book == nil;
}

@end
