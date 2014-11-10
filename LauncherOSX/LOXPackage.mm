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
#import <ePub3/manifest.h>


#import "LOXPackage.h"
#import "LOXSpine.h"
#import "LOXSpineItem.h"
#import "LOXUtil.h"
#import "LOXToc.h"
#import "LOXMediaOverlay.h"

#import <ePub3/utilities/byte_stream.h>

@interface LOXPackage () {
    //@private std::vector<std::unique_ptr<ePub3::ByteStream>> m_archiveReaderVector;
}

- (NSString *)findProperty:(NSString *)propName withPrefix:(NSString *)prefix;

- (LOXToc *)getToc;

- (void)copyTitleFromNavElement:(ePub3::NavigationElementPtr)element toEntry:(LOXTocEntry *)entry;

//- (void)saveContentOfReader:(std::unique_ptr<ePub3::ByteStream>&)reader toPath:(NSString *)path;

@end

@implementation LOXPackage {

    ePub3::PackagePtr _sdkPackage;
}

@synthesize packageUUID = m_packageUUID;

@synthesize spine = _spine;
@synthesize title = _title;
@synthesize packageId = _packageId;
@synthesize toc = _toc;
@synthesize rendition_layout = _rendition_layout;
@synthesize rendition_spread = _rendition_spread;
@synthesize rendition_orientation = _rendition_orientation;
@synthesize rendition_flow = _rendition_flow;
//@synthesize rootDirectory = _rootDirectory;
@synthesize mediaOverlay = _mediaOverlay;

//
//- (void)rdpackageResourceWillDeallocate:(RDPackageResource *)packageResource {
//    for (auto i = m_archiveReaderVector.begin(); i != m_archiveReaderVector.end(); i++) {
//        if (i->get() == packageResource.byteStream) {
//            m_archiveReaderVector.erase(i);
//            return;
//        }
//    }
//
//    NSLog(@"The archive reader was not found!");
//}

- (NSString *) resourceRelativePath:(NSString *)urlAbsolutePath
{
    if (urlAbsolutePath == nil)
    {
        NSLog(@"The resource path is null!");
        return nil;
    }

    NSRange range = [urlAbsolutePath rangeOfString:@"/"];

    if (range.location != 0) {
        NSLog(@"The HTTP request path doesn't begin with a forward slash!");
        return nil;
    }

    range = [urlAbsolutePath rangeOfString:@"/" options:0 range:NSMakeRange(1, urlAbsolutePath.length - 1)];

    if (range.location == NSNotFound) {
        NSLog(@"The HTTP request path is incomplete!");
        return nil;
    }

    NSString *packageUUID = [urlAbsolutePath substringWithRange:NSMakeRange(1, range.location - 1)];

    if (![packageUUID isEqualToString:self.packageUUID]) {
        NSLog(@"The HTTP request has the wrong package UUID!");
        return nil;
    }

    return [urlAbsolutePath substringFromIndex:NSMaxRange(range)];
}

- (RDPackageResource *)resourceAtRelativePath:(NSString *)relativePath {

    if (relativePath == nil || relativePath.length == 0) {
        return nil;
    }

    NSRange range = [relativePath rangeOfString:@"#"];

    if (range.location != NSNotFound) {
        relativePath = [relativePath substringToIndex:range.location];
    }

    ePub3::string s = ePub3::string(relativePath.UTF8String);

    //ConstManifestItemPtr
    std::shared_ptr<const ePub3::ManifestItem> manItem = _sdkPackage->ManifestItemAtRelativePath(s);

    if (manItem == nullptr) {
        NSLog(@"Relative path '%@' does not have a manifest item!", relativePath);
        return nil;
    }

    std::shared_ptr<ePub3::ByteStream> byteStream = nullptr;
    bool FORCE_BYTE_RANGE = false;
    if (FORCE_BYTE_RANGE)
    {
        byteStream = _sdkPackage->GetFilterChainByteStreamRange(std::const_pointer_cast<ePub3::ManifestItem>(manItem));

        if (byteStream == nullptr) {
            NSLog(@"Relative path '%@' does not have an archive byte stream!", relativePath);
            return nil;
        }
    }
    else
    {
        byteStream = _sdkPackage->GetFilterChainByteStream(std::const_pointer_cast<ePub3::ManifestItem>(manItem));

        if (byteStream == nullptr) {
            NSLog(@"Relative path '%@' does not have an archive byte stream!", relativePath);
            return nil;
        }

        if (byteStream->BytesAvailable() > 1024*1024) // 1MB
        {
            byteStream = nullptr;
            byteStream = _sdkPackage->GetFilterChainByteStreamRange(std::const_pointer_cast<ePub3::ManifestItem>(manItem));
        }
    }

    RDPackageResource *resource = [[RDPackageResource alloc]
            initWithByteStream:byteStream //release()
                relativePath:relativePath
                          pack: self];

    return resource;
}


- (id)initWithSdkPackage:(ePub3::PackagePtr)sdkPackage {

    self = [super init];
    if(self) {

        _sdkPackage = sdkPackage;

        CFUUIDRef uuid = CFUUIDCreate(NULL);
        m_packageUUID = CFBridgingRelease(CFUUIDCreateString(NULL, uuid));
        CFRelease(uuid);

//
//        m_relativePathsThatAreHTML = [[NSMutableSet alloc] init];
//        m_relativePathsThatAreNotHTML = [[NSMutableSet alloc] init];

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
        _toc = [self getToc];
        _packageId = [NSString stringWithUTF8String:_sdkPackage->PackageID().c_str()];
        _title = [NSString stringWithUTF8String:_sdkPackage->Title().c_str()];

        _rendition_layout = [self findProperty:@"layout" withPrefix:@"rendition"];
        _rendition_orientation = [self findProperty:@"orientation" withPrefix:@"rendition"];
        _rendition_spread = [self findProperty:@"spread" withPrefix:@"rendition"];
        _rendition_flow = [self findProperty:@"flow" withPrefix:@"rendition"];

        auto spineItem = _sdkPackage->FirstSpineItem();
        while (spineItem) {

            LOXSpineItem *loxSpineItem = [[LOXSpineItem alloc] initWithSdkSpineItem:spineItem fromPackage:self];
            [_spine addItem: loxSpineItem];
            spineItem = spineItem->Next();
        }

        _mediaOverlay = [[LOXMediaOverlay alloc] initWithSdkPackage:_sdkPackage];
    }
    
    return self;
}

- (NSString *) findProperty:(NSString *)propName withPrefix:(NSString *)prefix
{
    auto prop = _sdkPackage->PropertyMatching([propName UTF8String], [prefix UTF8String]);
    if(prop != nullptr) {
        return [NSString stringWithUTF8String: prop->Value().c_str()];
    }

    return @"";
}

- (LOXToc*)getToc
{
    auto navTable = _sdkPackage->NavigationTable("toc");

    if(navTable == nil) {
        return nil;
    }

    LOXToc *toc = [[LOXToc alloc] init];

    toc.title = [NSString stringWithUTF8String:navTable->Title().c_str()];
    if(toc.title.length == 0) {
        toc.title = @"Table of Contents";
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

            LOXTocEntry *entry = [[LOXTocEntry alloc] init];
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
//
//-(void)prepareResourceWithPath:(NSString *)path
//{
//
//    if (![_storage isLocalResourcePath:path]) {
//        return;
//    }
//
//    if([_storage isResoursFoundAtPath:path]) {
//        return;
//    }
//
//    NSString * relativePath = [_storage relativePathFromFullPath:path];
//
//    std::string str([relativePath UTF8String]);
//
//    // DEPRECATED (use ByteStream instead)
//    //ePub3::unique_ptr<ePub3::ArchiveReader>& reader = _sdkPackage->ReaderForRelativePath(str);
//
//    std::unique_ptr<ePub3::ByteStream> reader = _sdkPackage->ReadStreamForRelativePath(str); //_sdkPackage->BasePath() API changed
//
//    if(reader == NULL){
//        NSLog(@"No archive found for path %@", relativePath);
//        return;
//    }
//
//    [self saveContentOfReader:reader toPath: path];
//}
//
//- (void)saveContentOfReader: (std::unique_ptr<ePub3::ByteStream> &) reader toPath:(NSString *)path
//{
//    uint8_t buffer[1024];
//
//    NSMutableData * data = [NSMutableData data];
//
//    ssize_t readBytes = 0;
//    while ((readBytes  = reader->ReadBytes(buffer, 1024)) > 0) {
//        [data appendBytes:buffer length:(NSUInteger) readBytes];
//    }
//
//    [_storage saveData:data  toPaht:path];
//}

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

    //[dict setObject:_rootDirectory forKey:@"rootUrl"];
    [dict setObject:@"/" forKey:@"rootUrl"];

    [dict setObject:_rendition_layout forKey:@"rendition_layout"];
    [dict setObject:_rendition_spread forKey:@"rendition_spread"];
    [dict setObject:_rendition_orientation forKey:@"rendition_orientation"];
    [dict setObject:_rendition_flow forKey:@"rendition_flow"];
    [dict setObject:[_spine toDictionary] forKey:@"spine"];
    [dict setObject:[_mediaOverlay toDictionary] forKey:@"media_overlay"];

    return dict;
}

-(ePub3::PackagePtr) sdkPackage
{
    return _sdkPackage;
}


@end