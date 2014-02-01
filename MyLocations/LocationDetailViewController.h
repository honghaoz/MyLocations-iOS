//
//  LocationDetailViewController.h
//  MyLocations
//
//  Created by Zhang Honghao on 2/1/14.
//  Copyright (c) 2014 org-honghao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CategoryPickerViewController.h"

@interface LocationDetailViewController : UITableViewController <UITextViewDelegate, CategoryPickerViewControllerDelegate>

@property (nonatomic, strong) IBOutlet UITextView *descriptionTextView;
@property (nonatomic, strong) IBOutlet UILabel *categoryLabel;
@property (nonatomic, strong) IBOutlet UILabel *latitudeLabel;
@property (nonatomic, strong) IBOutlet UILabel *longitudeLabel;
@property (nonatomic, strong) IBOutlet UILabel *addressLabel;
@property (nonatomic, strong) IBOutlet UILabel *dateLabel;

@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) CLPlacemark *placemark;

- (IBAction)done:(id)sender;
- (IBAction)cancel:(id)sender;

@end
