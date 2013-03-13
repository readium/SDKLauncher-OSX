//
//  LOXBook.h
//  LauncherOSX
//
//  Created by Boris Schneiderman on 2013-02-19.
//  Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LOXBookmark;


@interface LOXBook : NSObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * filePath;
@property (nonatomic, retain, readonly) NSArray *bookmarks;

@property(nonatomic, retain) NSDate* dateCreated;
@property(nonatomic, retain) NSDate* dateOpened;
@property(nonatomic, retain) NSString *packageId;

- (NSDictionary *)toDictionary;

- (void)addBookmark:(LOXBookmark *)bookmark;

+ (id)bookFromDictionary:(NSDictionary *)dict;

- (void)removeBookmark:(LOXBookmark *)bookmark;


@end

