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
@property (nonatomic, retain) NSNumber *mediaOverlaysSkipSkippables;
@property (nonatomic, retain) NSNumber *mediaOverlaysEscapeEscapables;
@property (nonatomic, retain) NSString *mediaOverlaysSkippables;
@property (nonatomic, retain) NSString *mediaOverlaysEscapables;
@property (nonatomic, retain) NSNumber *mediaOverlaysEnableClick;
@property (nonatomic, retain) NSNumber *mediaOverlaysRate;
@property (nonatomic, retain) NSNumber *mediaOverlaysVolume;
@property (nonatomic, retain) NSNumber *isScrollViewDoc;
@property (nonatomic, retain) NSNumber *isScrollViewContinuous;

- (void)updateMediaOverlaysSkippables:(NSString *)str;
- (void)updateMediaOverlaysEscapables:(NSString *)str;

- (void)setDoNotUpdateView:(bool)doNotUpdate;

- (bool)isMediaOverlayProperty:(NSString *)name;

- (id)initWithDictionary:(NSDictionary *)dict;

- (NSDictionary *)toDictionary;

- (void)registerChangeObserver:(NSObject *)observer;


- (void)removeChangeObserver:(NSObject *)observer;
@end