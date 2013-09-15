//
// Created by Boris Schneiderman on 2013-08-20.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface LOXMediaOverlay : NSObject

@property(nonatomic, readonly) NSArray *smilModels;
//@property(nonatomic, copy) NSString *duration;
@property (nonatomic, copy) NSNumber *duration;
@property(nonatomic, copy) NSString *narrator;
@property(nonatomic, copy) NSString *activeClass;
@property(nonatomic, copy) NSString *playbackActiveClass;

- (id)initWithSdkPackage:(ePub3::PackagePtr)sdkPackage;

- (NSDictionary *)toDictionary;
@end