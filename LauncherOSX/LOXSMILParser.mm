//
// Created by Boris Schneiderman on 2013-08-14.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXSMILParser.h"
#import "LOXMediaOverlay.h"


@interface LOXSMILParser ()
- (void)pushItem:(NSDictionary *)item;
@end

@implementation LOXSMILParser
{
    NSXMLParser *_parser;
    LOXMediaOverlay *_mediaOverlay;

    NSMutableArray *_stack;
    NSArray *_nodeNames;
}

- (id)initWithData:(NSData *)data
{
    self = [super init];

    if (self) {

        _stack = [[NSMutableArray array] retain];

        _parser = [[NSXMLParser alloc] initWithData:data];
        [_parser setDelegate:self];

        _nodeNames = [[NSArray arrayWithObjects:@"seq", @"par", @"text", @"audio", nil] retain];

    }

    return self;

}



- (void) parser:(NSXMLParser *)parser
didStartElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName
     attributes:(NSDictionary *)attributeDict
{

    if([elementName isEqualToString:@"smil"]) {
        _mediaOverlay.smilVersion = attributeDict[@"version"];
    }

    if(![_nodeNames containsObject:elementName]) {
        return;
    }

    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    item[@"nodeType"] = elementName;

    NSArray *keys = [attributeDict allKeys];

    for(NSString *key in keys) {

        NSString *propName;

        if([key isEqualToString:@"epub:textref"]) {
            propName = @"textref";
        }
        else if([key isEqualToString:@"epub:type"]) {
            propName = @"epub:type";
        }
        else {
            propName = [[key copy] autorelease];
        }

        item[propName] = attributeDict[key];
    }

    [self pushItem:item];


}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{

}

- (void)parser:(NSXMLParser *)parser
 didEndElement:(NSString *)elementName
  namespaceURI:(NSString *)namespaceURI
 qualifiedName:(NSString *)qName
{

    if(![_nodeNames containsObject:elementName]) {
        return;
    }

    NSMutableDictionary *item = [self popItem];

    NSMutableDictionary *parent = [self pickItem];

    if(parent) {
        NSMutableArray *children = parent[@"children"];
        if(!children) {
            children = [NSMutableArray array];
            parent[@"children"] = children;
        }

        [children addObject:item];

    }
    else {
        [_mediaOverlay addItem:item];
    }

}

- (LOXMediaOverlay *)parse
{
    [_mediaOverlay release];
    _mediaOverlay = [[LOXMediaOverlay alloc] init];

    if( [_parser parse] ) {
        return _mediaOverlay;
    }

    return nil;
}

-(void)pushItem:(NSDictionary *)item
{
    [_stack addObject:item];
}

-(id)popItem
{
    id item = [self pickItem];

    if(item) {
        [_stack removeLastObject];
    }

    return item;
}

-(id)pickItem
{
    if([_stack count] == 0) {
        return nil;
    }

    return [_stack objectAtIndex:[_stack count] - 1];
}

- (void)dealloc
{
    [_parser release];
    [_mediaOverlay release];
    [_stack release];
    [_nodeNames release];
    [super dealloc];
}

@end