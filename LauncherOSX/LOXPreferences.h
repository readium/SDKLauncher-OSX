//
// Created by Boris Schneiderman on 2013-07-16.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface LOXPreferences : NSObject



@property (nonatomic, strong) NSNumber *isSyntheticSpread;
@property (nonatomic, strong) NSNumber *fontSize;
@property (nonatomic, strong) NSNumber *columnGap;
@property (nonatomic, strong) NSNumber *mediaOverlaysSkipSkippables;
@property (nonatomic, strong) NSNumber *mediaOverlaysEscapeEscapables;
@property (nonatomic, strong) NSString *mediaOverlaysSkippables;
@property (nonatomic, strong) NSString *mediaOverlaysEscapables;
@property (nonatomic, strong) NSNumber *mediaOverlaysEnableClick;
@property (nonatomic, strong) NSNumber *mediaOverlaysRate;
@property (nonatomic, strong) NSNumber *mediaOverlaysVolume;
@property (nonatomic, strong) NSNumber *isScrollDoc;
@property (nonatomic, strong) NSNumber *isScrollContinuous;

- (void)updateMediaOverlaysSkippables:(NSString *)str;
- (void)updateMediaOverlaysEscapables:(NSString *)str;

- (void)setDoNotUpdateView:(bool)doNotUpdate;

- (bool)isMediaOverlayProperty:(NSString *)name;

- (id)initWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)toDictionary;

- (void)registerChangeObserver:(NSObject *)observer;


- (void)removeChangeObserver:(NSObject *)observer;
@end