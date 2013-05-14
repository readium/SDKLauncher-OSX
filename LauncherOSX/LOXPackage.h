//
// Created by Boris Schneiderman on 2013-05-06.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>

@class LOXSpine;
@class LOXSpineItem;
@class LOXTemporaryFileStorage;
@class LOXToc;


@interface LOXPackage : NSObject

-(id)initWithSdkPackage:(const ePub3::Package*) sdkPackage;

- (NSString *)getPathToSpineItem:(LOXSpineItem *)spineItem;

- (void)prepareResourceWithPath:(NSString *)path;

- (NSString *)getCfiForSpineItem:(LOXSpineItem *)spineItem;

- (LOXSpineItem *)findSpineItemWithBasePath:(NSString *)href;


- (NSString *)toJSON;

- (NSDictionary *)toDictionary;

@property(nonatomic, readonly) LOXSpine *spine;
@property(nonatomic, readonly) NSString *title;
@property(nonatomic, readonly) NSString *packageId;
@property(nonatomic, readonly) LOXToc *toc;
@property(nonatomic, readonly) NSString* layout;
@property(nonatomic, readonly) NSString* rootDirectory;


@end