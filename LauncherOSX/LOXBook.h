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
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class LOXBookmark;


@interface LOXBook : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) NSString * filePath;
@property (nonatomic, strong, readonly) NSArray *bookmarks;

@property (nonatomic, strong) LOXBookmark *lastOpenPage;

@property(nonatomic, strong) NSDate* dateCreated;
@property(nonatomic, strong) NSDate* dateOpened;
@property(nonatomic, strong) NSString *packageId;

- (NSDictionary *)toDictionary;

- (void)addBookmark:(LOXBookmark *)bookmark;

+ (id)bookFromDictionary:(NSDictionary *)dict;

- (void)removeBookmark:(LOXBookmark *)bookmark;


@end

