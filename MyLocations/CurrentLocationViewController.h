//
//  CurrentLocationViewController
//  MyLocations
//
//  Created by Zhang Honghao on 1/31/14.
//  Copyright (c) 2014 org-honghao. All rights reserved.
//

@interface CurrentLocationViewController : UIViewController <CLLocationManagerDelegate>

@property(nonatomic,weak) IBOutlet UILabel *messageLabel;
@property(nonatomic,weak) IBOutlet UILabel *latitudeLabel;
@property(nonatomic,weak) IBOutlet UILabel *longtitudeLabel;
@property(nonatomic,weak) IBOutlet UILabel *altitudeLabel;
@property(nonatomic,weak) IBOutlet UILabel *adderssLabel;
@property(nonatomic,weak) IBOutlet UIButton *tagButton;
@property(nonatomic,weak) IBOutlet UIButton *getButton;

@property (nonatomic, strong) IBOutlet UIView *panelView;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
-(IBAction) getLocation:(id)sender;

@end
