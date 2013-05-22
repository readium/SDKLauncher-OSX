
#import <ePub3/nav_table.h>
#import <ePub3/package.h>


#import "LOXPackage.h"
#import "LOXSpine.h"
#import "LOXSpineItem.h"
#import "LOXTemporaryFileStorage.h"
#import "LOXUtil.h"
#import "LOXToc.h"


@interface LOXPackage ()

- (LOXToc *)getToc;

- (void)saveContentOfReader:(ePub3::ArchiveReader const *)reader toPath:(NSString *)path;

@end

@implementation LOXPackage {

    const ePub3::Package *_sdkPackage;
    LOXTemporaryFileStorage *_storage;
}

@synthesize spine = _spine;
@synthesize title = _title;
@synthesize packageId = _packageId;
@synthesize toc = _toc;
@synthesize layout = _layout;
@synthesize rootDirectory = _rootDirectory;

- (id)initWithSdkPackage:(ePub3::Package const *)sdkPackage {

    self = [super init];
    if(self) {

        _sdkPackage = sdkPackage;
        _spine = [[LOXSpine alloc] init];
        _toc = [[self getToc] retain];
        _packageId =[NSString stringWithUTF8String:_sdkPackage->PackageID().c_str()];
        _title = [NSString stringWithUTF8String:_sdkPackage->Title().c_str()];
//        _layout = [NSString stringWithUTF8String:_sdkPackage->Layout().c_str()];
        _layout = @"pre-paginated"; //this is temporary  - sdkPackage will expose property sun ZZZZ

        _storage = [[self createStorageForPackage:_sdkPackage] retain];

        _rootDirectory = _storage.rootDirectory;

        const ePub3::SpineItem *spineItem = _sdkPackage->FirstSpineItem();
        while (spineItem) {

            LOXSpineItem *loxSpineItem = [[[LOXSpineItem alloc] initWithStorageId:_storage.uuid forSdkSpineItem:spineItem] autorelease];
            [_spine addItem: loxSpineItem];
            spineItem = spineItem->Next();
        }

    }
    
    return self;
}

- (void)dealloc {
    [_spine release];
    [_toc release];
    [_storage release];
    [super dealloc];
}


- (LOXTemporaryFileStorage *)createStorageForPackage:(const ePub3::Package*)package
{
    NSString *packageBasePath = [NSString stringWithUTF8String:package->BasePath().c_str()];
    return [[[LOXTemporaryFileStorage alloc] initWithUUID:[LOXUtil uuid] forBasePath:packageBasePath] autorelease];
}

- (NSString*)getPathToSpineItem:(LOXSpineItem *) spineItem
{
    NSString *fullPath = [_storage absolutePathForFile: spineItem.href];

    return fullPath;
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

    [self addNavElementChildrenFrom:navTable toTocEntry:toc];

    return toc;
}

- (void)addNavElementChildrenFrom:(const ePub3::NavigationElement *)navElement toTocEntry:(LOXTocEntry *)parentEntry
{
    for (auto el = navElement->Children().begin(); el != navElement->Children().end(); el++) {

        auto navPoint = dynamic_cast<ePub3::NavigationPoint*>(*el);

        if(navPoint != nil) {

            LOXTocEntry *entry = [[[LOXTocEntry alloc] init] autorelease];
            [self copyTitleFromNavElement:navPoint toEntry:entry];
            entry.contentRef = [NSString stringWithUTF8String:navPoint->Content().c_str()];

            [parentEntry addChild:entry];

            [self addNavElementChildrenFrom:navPoint toTocEntry:entry];
        }

    }
}

-(void)copyTitleFromNavElement:(ePub3::NavigationElement*)element toEntry:(LOXTocEntry *)entry
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

- (void)saveContentOfReader:(const ePub3::ArchiveReader *)reader toPath:(NSString *)path
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

-(bool)isPackageContainsPath:(NSString*) path
{
    return [path rangeOfString:_storage.uuid].location != NSNotFound;
}

- (LOXSpineItem *)findSpineItemWithBasePath:(NSString *)href
{
    for (LOXSpineItem * spineItem in _spine.items) {
        if ([[self removeLeadingRelativeParentPath:spineItem.href] isEqualToString: [self removeLeadingRelativeParentPath:href]]) {
            return spineItem;
        }
    }

    return nil;
}

//path's can come from different files id different dpth and they may contain leading "../"
//we have to remove it to compare path's
-(NSString*) removeLeadingRelativeParentPath: (NSString*) path
{
    NSString* ret = [NSString stringWithString:[path lowercaseString]];

    while([ret hasPrefix:@"../"]) {
        ret  = [ret substringFromIndex:3];
    }

    return ret;
}

-(NSString*) toJSON
{
    NSDictionary * dict = [self toDictionary];

    NSData* encodedData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:nil];

    NSString* jsonString = [[[NSString alloc] initWithData:encodedData encoding:NSUTF8StringEncoding] autorelease];

    return jsonString;
}

-(NSDictionary *) toDictionary
{
    NSMutableDictionary * dict = [NSMutableDictionary dictionary];

    [dict setObject:_rootDirectory forKey:@"rootUrl"];
    [dict setObject:_layout forKey:@"layout"];
    [dict setObject:[_spine toDictionary] forKey:@"spine"];

    return dict;
}



@end