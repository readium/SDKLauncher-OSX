//
// Created by Boris Schneiderman on 2013-08-14.
// Modified by Daniel Weck
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


#import "LOXSmilModel.h"


@implementation LOXSmilModel {

    NSMutableArray *_children;

}

@synthesize children = _children;

-(id)init
{
    self = [super init];
    if (self){

        _children = [NSMutableArray array];

    }

    return self;
}

-(void)addItem:(NSDictionary*)item
{
    [_children addObject:item];
}


-(NSDictionary *)toDictionary
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    [dict setObject:self.id forKey:@"id"];
    [dict setObject:self.spineItemId forKey:@"spineItemId"];
    [dict setObject:self.href forKey:@"href"];
    [dict setObject:self.smilVersion forKey:@"smilVersion"];
    [dict setObject:self.children forKey:@"children"];
    [dict setObject:self.duration forKey:@"duration"];

    return dict;
}

@end