//
//  LOXPackageParser.m
//  LauncherOSX
//
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

#import "LOXPackageParser.h"
#import "LOXPackage.h"
#import "LOXManifestItem.h"
#import "LOXSpineItemSdk.h"
#import "LOXSpineItemCocoa.h"

@interface LOXPackageParser ()
- (void)clearPackage;

- (LOXManifestItem *)createManifestItemFromAttributeDict:(NSDictionary *)attributes;

@end


@implementation LOXPackageParser


- (void)parseData:(NSData *)data
{
    [self clearPackage];

    NSXMLParser *parser = [[[NSXMLParser alloc] initWithData:data] autorelease];

    [parser setDelegate:self];
    [parser parse];
}

-(LOXPackage *)package
{
    return _package;
}

- (void)clearPackage
{
    [_package release];
    _package = nil;

}

- (void)dealloc
{
    [self clearPackage];
    [super dealloc];
}


- (void) parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qualifiedName
     attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqual:@"package"]) {
        [self clearPackage];
        _package = [[LOXPackage alloc] init];
        return;
    }

    if ([elementName isEqual:@"manifest"]) {
        _isManifest = YES;
        return;
    }

    if ([elementName isEqual:@"spine"]) {
        _isSpine = YES;
        return;
    }

    if (_isManifest && [elementName isEqual:@"item"]) {
        LOXManifestItem *manifestItem = [self createManifestItemFromAttributeDict:attributeDict];
        [_package addManifestItem:manifestItem];
        return;
    }

    if (_isSpine && [elementName isEqual:@"itemref"]) {
        NSString *idref = [attributeDict objectForKey:@"idref"];

        if (idref) {

            LOXSpineItemCocoa *spineItem = [[[LOXSpineItemCocoa alloc] initWithIdref:idref forPackage:_package] autorelease];
            [_package addSpineItem:spineItem];
        }
        else {
            NSAssert(NO, @"idref mast exist");
        }
    }
}

- (LOXManifestItem *)createManifestItemFromAttributeDict:(NSDictionary *)attributes
{

    LOXManifestItem *manifestItem = [[[LOXManifestItem alloc] init] autorelease];

    manifestItem.href = [attributes objectForKey:@"href"];
    manifestItem.id = [attributes objectForKey:@"id"];
    manifestItem.mediaType = [attributes objectForKey:@"media-type"];
    manifestItem.properties = [attributes objectForKey:@"properties"];

    NSAssert(manifestItem.href, @"Href mast be set");
    NSAssert(manifestItem.id, @"id mast be set");

    return manifestItem;
}


- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{
    if ([elementName isEqual:@"manifest"]) {
        _isManifest = NO;
        return;
    }

    if ([elementName isEqual:@"getSpineItems"]) {
        _isSpine = NO;
        return;
    }
}

@end
