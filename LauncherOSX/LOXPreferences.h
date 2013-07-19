//
// Created by Boris Schneiderman on 2013-07-16.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface LOXPreferences : NSObject



@property (nonatomic, retain) NSNumber *isSyntheticSpread;
@property (nonatomic, retain) NSNumber *fontSize;
@property (nonatomic, retain) NSNumber *columnGap;


- (id)initWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)toDictionary;

- (void)registerChangeObserver:(NSObject *)observer;


- (void)removeChangeObserver:(NSObject *)observer;
@end