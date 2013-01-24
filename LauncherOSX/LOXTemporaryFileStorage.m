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

@synthesize uuid = _uuid;
@synthesize rootDirectory = _rootDirectory;

-(id)initWithUUID:(NSString *)uuid forBasePath:(NSString *)basePath
{
    self = [super init];

    if(self) {

        _uuid = uuid;
        [_uuid retain];

        NSString *subdir;

        if(basePath && basePath.length > 0 && ![basePath isEqualToString:@"/"]) {
            subdir = [_uuid stringByAppendingPathComponent:basePath];
        }
        else {
            subdir = uuid;
        }

        if([subdir hasSuffix:@"/"]) {
            subdir = [subdir substringToIndex:subdir.length - 1];
        }

        _rootDirectory = [[NSTemporaryDirectory() stringByAppendingPathComponent:subdir] retain];

        [self createCleanDirectory:_rootDirectory];

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
    return [path hasPrefix:_rootDirectory];
}

-(NSString *)relativePathFromFullPath:(NSString*)fullPath
{
    if ([fullPath hasPrefix:_rootDirectory]) {
        return [fullPath substringFromIndex:_rootDirectory.length + 1];
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
    return [NSString stringWithFormat:@"%@/%@", _rootDirectory, fileName];
}

- (void)dealloc
{
    [_rootDirectory release];
    [_uuid release];

    [super dealloc];
}

@end