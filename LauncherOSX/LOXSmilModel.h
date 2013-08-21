//
// Created by Boris Schneiderman on 2013-08-14.
// Copyright (c) 2013 Boris Schneiderman. All rights reserved.
//
// To change the template use AppCode | Preferences | File Templates.
//


#import <Foundation/Foundation.h>


@interface LOXSmilModel : NSObject

@property (nonatomic, readonly) NSArray *childern;
@property (nonatomic, copy) NSString *href;
@property (nonatomic, copy) NSString *id;
@property (nonatomic, copy) NSString *smilVersion;


- (void)addItem:(NSDictionary *)item;

- (NSDictionary *)toDictionary;
@end