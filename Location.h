//
//  Location.h
//  MyLocations
//
//  Created by Zhang Honghao on 2/1/14.
//  Copyright (c) 2014 org-honghao. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Location : NSManagedObject <MKAnnotation>

@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * locationDescription;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) CLPlacemark *placemark;
@property (nonatomic, retain) NSNumber *photoId;

- (BOOL)hasPhoto;
- (NSString *)photoPath;
- (UIImage *)photoImage;

- (void)removePhotoFile;

@end
