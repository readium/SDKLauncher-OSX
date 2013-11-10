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
#import <ePub3/spine.h>


namespace ePub3 {
    class SpineItem;
}

@class LOXPackage;

@interface LOXSpineItem : NSObject {

@private
    ePub3::SpineItemPtr _sdkSpineItem;
    NSString* _idref;

    //NSString* _packageStorrageId;
}

@property(nonatomic, readonly) NSString *idref;
//@property(nonatomic, readonly) NSString *packageStorageId;
@property(nonatomic, readonly) NSString *href;
@property(nonatomic, readonly) NSString *page_spread;
@property(nonatomic, readonly) NSString *rendition_layout;
@property(nonatomic, readonly) NSString *mediaOverlayId;

- (id)initWithSdkSpineItem:(ePub3::SpineItemPtr)sdkSpineItem fromPackage:(LOXPackage*)package;
//- (id)initWithStorageId:(NSString *)storageId forSdkSpineItem:(ePub3::SpineItemPtr)sdkSpineItem fromPackage:(LOXPackage *)package;

- (ePub3::SpineItemPtr) sdkSpineItem;


-(NSDictionary *)toDictionary;

@end