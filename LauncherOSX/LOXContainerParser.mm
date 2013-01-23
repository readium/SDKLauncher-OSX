//  Created by Boris Schneiderman.
//  Copyright (c) 2012-2013 The Readium Foundation.
//
//  The Readium SDK is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//


#import "LOXContainerParser.h"


@implementation LOXContainerParser

- (id)init
{
    self = [super init];
    if (self) {
        _rootFiles = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void)dealloc
{
    [_rootFiles release];
    [super dealloc];
}

- (NSArray*)parseData:(NSData *)data
{
    [_rootFiles removeAllObjects];

    NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:data] autorelease];

    [parser setDelegate:self];
    [parser parse];

    return _rootFiles;

}

- (void) parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qualifiedName
     attributes:(NSDictionary *)attributeDict
{
    if([elementName isEqual:@"rootfile"]){

        NSString *rootFile = [attributeDict objectForKey:@"full-path"];
        if(rootFile){
            [_rootFiles addObject:rootFile];
        }
    }
}

@end