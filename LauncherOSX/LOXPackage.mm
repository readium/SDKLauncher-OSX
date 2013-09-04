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


#import <ePub3/nav_element.h>
#import <ePub3/nav_table.h>
#import <ePub3/archive.h>
#import <ePub3/package.h>


#import "LOXPackage.h"
#import "LOXSpine.h"
#import "LOXSpineItem.h"
#import "LOXTemporaryFileStorage.h"
#import "LOXUtil.h"
#import "LOXToc.h"
#import "LOXMediaOverlay.h"


@interface LOXPackage ()

- (NSString *)getLayoutProperty;

- (LOXToc *)getToc;

- (void)copyTitleFromNavElement:(ePub3::NavigationElementPtr)element toEntry:(LOXTocEntry *)entry;

- (void)saveContentOfReader:(ePub3::unique_ptr<ePub3::ArchiveReader>&)reader toPath:(NSString *)path;

@end

@implementation LOXPackage {

    ePub3::PackagePtr _sdkPackage;
    LOXTemporaryFileStorage *_storage;

}

@synthesize spine = _spine;
@synthesize title = _title;
@synthesize packageId = _packageId;
@synthesize toc = _toc;
@synthesize rendition_layout = _rendition_layout;
@synthesize rootDirectory = _rootDirectory;
@synthesize mediaOverlay = _mediaOverlay;


- (id)initWithSdkPackage:(ePub3::PackagePtr)sdkPackage {

    self = [super init];
    if(self) {

        _sdkPackage = sdkPackage;

        NSString* direction;

        auto pageProgression = _sdkPackage->PageProgressionDirection();
        if(pageProgression == ePub3::PageProgression::LeftToRight) {
            direction = @"ltr";
        }
        else if(pageProgression == ePub3::PageProgression::RightToLeft) {
            direction = @"rtl";
        }
        else {
            direction = @"default";
        }

        _spine = [[LOXSpine alloc] initWithDirection:direction];
        _toc = [[self getToc] retain];
        _packageId = [[NSString stringWithUTF8String:_sdkPackage->PackageID().c_str()] retain];
        _title = [[NSString stringWithUTF8String:_sdkPackage->Title().c_str()] retain];

        _rendition_layout = [[self getLayoutProperty] retain];

        _storage = [[self createStorageForPackage:_sdkPackage] retain];

        _rootDirectory = [_storage.rootDirectory retain];

        auto spineItem = _sdkPackage->FirstSpineItem();
        while (spineItem) {

            LOXSpineItem *loxSpineItem = [[[LOXSpineItem alloc] initWithStorageId:_storage.uuid forSdkSpineItem:spineItem fromPackage:self] autorelease];
            [_spine addItem: loxSpineItem];
            spineItem = spineItem->Next();
        }

        _mediaOverlay = [[LOXMediaOverlay alloc] initWithSdkPackage:_sdkPackage];

        auto propList = _sdkPackage->PropertiesMatching("duration", "media");

        for(auto iter = propList.begin(); iter != propList.end(); iter++) {

            auto prop = iter;


        }
    }
    
    return self;
}

-(NSString*)getLayoutProperty
{
    auto prop = _sdkPackage->PropertyMatching("layout", "rendition");
    if(prop != nullptr) {
        return [NSString stringWithUTF8String: prop->Value().c_str()];
    }

    return @"";
}

- (void)dealloc {
    [_spine release];
    [_toc release];
    [_storage release];
    [_packageId release];
    [_title release];
    [_rendition_layout release];
    [_rootDirectory release];
    [_mediaOverlay release];
    [super dealloc];
}


- (LOXTemporaryFileStorage *)createStorageForPackage:(ePub3::PackagePtr)package
{
    NSString *packageBasePath = [NSString stringWithUTF8String:package->BasePath().c_str()];
    return [[[LOXTemporaryFileStorage alloc] initWithUUID:[LOXUtil uuid] forBasePath:packageBasePath] autorelease];
}

- (LOXToc*)getToc
{
    auto navTable = _sdkPackage->NavigationTable("toc");

    if(navTable == nil) {
        return nil;
    }

    LOXToc *toc = [[[LOXToc alloc] init] autorelease];

    toc.title = [NSString stringWithUTF8String:navTable->Title().c_str()];
    if(toc.title.length == 0) {
        toc.title = @"Table of content";
    }

    toc.sourceHref = [NSString stringWithUTF8String:navTable->SourceHref().c_str()];


    [self addNavElementChildrenFrom:std::dynamic_pointer_cast<ePub3::NavigationElement>(navTable) toTocEntry:toc];

    return toc;
}

- (void)addNavElementChildrenFrom:(ePub3::NavigationElementPtr)navElement toTocEntry:(LOXTocEntry *)parentEntry
{
    for (auto el = navElement->Children().begin(); el != navElement->Children().end(); el++) {

        ePub3::NavigationPointPtr navPoint = std::dynamic_pointer_cast<ePub3::NavigationPoint>(*el);

        if(navPoint != nil) {

            LOXTocEntry *entry = [[[LOXTocEntry alloc] init] autorelease];
            [self copyTitleFromNavElement:navPoint toEntry:entry];
            entry.contentRef = [NSString stringWithUTF8String:navPoint->Content().c_str()];

            [parentEntry addChild:entry];

            [self addNavElementChildrenFrom:navPoint toTocEntry:entry];
        }

    }
}

-(void)copyTitleFromNavElement:(ePub3::NavigationElementPtr)element toEntry:(LOXTocEntry *)entry
{
    NSString *title = [NSString stringWithUTF8String: element->Title().c_str()];
    entry.title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

}


-(void)prepareResourceWithPath:(NSString *)path
{

    if (![_storage isLocalResourcePath:path]) {
        return;
    }

    if([_storage isResoursFoundAtPath:path]) {
        return;
    }

    NSString * relativePath = [_storage relativePathFromFullPath:path];

    std::string str([relativePath UTF8String]);
    auto reader = _sdkPackage->ReaderForRelativePath(str);

    if(reader == NULL){
        NSLog(@"No archive found for path %@", relativePath);
        return;
    }

    [self saveContentOfReader:reader toPath: path];
}

- (void)saveContentOfReader:(ePub3::unique_ptr<ePub3::ArchiveReader>&)reader toPath:(NSString *)path
{
    char buffer[1024];

    NSMutableData * data = [NSMutableData data];

    ssize_t readBytes = reader->read(buffer, 1024);

    while (readBytes > 0) {
        [data appendBytes:buffer length:(NSUInteger) readBytes];
        readBytes = reader->read(buffer, 1024);
    }

    [_storage saveData:data  toPaht:path];
}

-(NSString*) getCfiForSpineItem:(LOXSpineItem *) spineItem
{
    ePub3::string cfi = _sdkPackage->CFIForSpineItem([spineItem sdkSpineItem]).String();
    NSString * nsCfi = [NSString stringWithUTF8String: cfi.c_str()];
    return [self unwrapCfi: nsCfi];
}

-(NSString *)unwrapCfi:(NSString *)cfi
{
    if ([cfi hasPrefix:@"epubcfi("] && [cfi hasSuffix:@")"]) {
        NSRange r = NSMakeRange(8, [cfi length] - 9);
        return [cfi substringWithRange:r];
    }

    return cfi;
}

-(NSDictionary *) toDictionary
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];

    [dict setObject:_rootDirectory forKey:@"rootUrl"];
    [dict setObject:_rendition_layout forKey:@"rendition_layout"];
    [dict setObject:[_spine toDictionary] forKey:@"spine"];
    [dict setObject:[_mediaOverlay toDictionary] forKey:@"media_overlay"];


    return dict;
}


@end