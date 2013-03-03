//
//  Bookmark.h
//  LauncherOSX
//
//  Created by Boris Schneiderman on 2013-02-19.
//  Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LOXBook;

@interface LOXBookmark : NSObject

@property (nonatomic, retain) NSString *idref;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *spineItemCFI;
@property (nonatomic, retain) NSString *contentCFI;
@property (nonatomic, assign) LOXBook *book;

+ (id)bookmarkFromDictionary:(NSDictionary *)dict;

- (NSDictionary *)toDictionary;

-(bool)isNew;

@end
