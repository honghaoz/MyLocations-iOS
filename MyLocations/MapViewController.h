//
//  MapViewController.h
//  MyLocations
//
//  Created by Zhang Honghao on 2/4/14.
//  Copyright (c) 2014 org-honghao. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MapViewController : UIViewController <MKMapViewDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) IBOutlet MKMapView *mapView;

- (IBAction)showUser;

- (IBAction)showLocations;

@end
