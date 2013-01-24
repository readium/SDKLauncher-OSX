//
// Created by boriss on 2013-01-23.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import "LOXTemporaryFileStorage.h"
#import "LOXUtil.h"


@interface LOXTemporaryFileStorage ()

- (void)createCleanDirectory:(NSString *)directory;


@end

@implementation LOXTemporaryFileStorage

@synthesize rootDirectory = _rootFolder;

-(id)initWithBasePath:(NSString *)basePath
{
    self = [super init];

    if(self) {

        NSString* uuid = [LOXUtil uuid];

        NSString *subdir;

        if(basePath && basePath.length > 0 && ![basePath isEqualToString:@"/"]) {
            subdir = [uuid stringByAppendingPathComponent:basePath];
        }
        else {
            subdir = uuid;
        }

        if([subdir hasSuffix:@"/"]) {
            subdir = [subdir substringToIndex:subdir.length - 1];
        }

        _rootFolder = [[NSTemporaryDirectory() stringByAppendingPathComponent:subdir] retain];

        [self createCleanDirectory:_rootFolder];

    }

    return self;
}

- (void)createCleanDirectory:(NSString *)directory
{
    BOOL isDir;

    if ([[NSFileManager defaultManager] fileExistsAtPath:directory isDirectory:&isDir]) {
        [[NSFileManager defaultManager] removeItemAtPath:directory error:nil];
    }

    [self ensureDirectory:directory];
}

-(bool)isLocalResourcePath:(NSString*)path
{
    return [path hasPrefix:_rootFolder];
}

-(NSString *)relativePathFromFullPath:(NSString*)fullPath
{
    if ([fullPath hasPrefix:_rootFolder]) {
        return [fullPath substringFromIndex:_rootFolder.length + 1];
    }

    return fullPath;

}

- (void)saveData:(NSData *)data toPaht:(NSString *)path
{
    NSString *directory = [path stringByDeletingLastPathComponent];

    [self ensureDirectory:directory];

    [data writeToFile:path atomically:YES];
}

- (void)ensureDirectory:(NSString *) path
{
    BOOL isDir;

    if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir) {
        return;
    }

    [[NSFileManager defaultManager] createDirectoryAtPath:path
                              withIntermediateDirectories:YES attributes:nil error:nil];
}


-(bool) isResoursFoundAtPath:(NSString *)fullPath
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:fullPath];
}

- (NSString *)absolutePathForFile:(NSString *)fileName
{
    return [NSString stringWithFormat:@"%@/%@", _rootFolder, fileName];
}

- (void)dealloc
{
    [_rootFolder release];
    _rootFolder = nil;

    [super dealloc];
}

@end