//
// Created by boriss on 2013-01-23.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface LOXTemporaryFileStorage : NSObject{

@private
    NSString *_rootFolder;

}
- (NSString *)absolutePathForFile:(NSString *)fileName;

@property(nonatomic, readonly) NSString *rootDirectory;

- (id)initWithBasePath:(NSString *)basePath;

- (bool)isResoursFoundAtPath:(NSString *)fullPath;

- (bool)isLocalResourcePath:(NSString *)path;

- (NSString *)relativePathFromFullPath:(NSString *)fullPath;

- (void)saveData:(NSData *)data toPaht:(NSString *)path;


@end