//
//  FirstViewController.m
//  MyLocations
//
//  Created by Zhang Honghao on 1/31/14.
//  Copyright (c) 2014 org-honghao. All rights reserved.
//

#import "CurrentLocationViewController.h"
#import "LocationDetailsViewController.h"
#import "NSMutableString+AddText.h"
#import <AudioToolbox/AudioToolbox.h>
#import <QuartzCore/QuartzCore.h>

@interface CurrentLocationViewController ()

@end

@implementation CurrentLocationViewController {
    CLLocationManager *_locationManager;
    CLLocation *_location;
    BOOL _updatingLocation;
    NSError *_lastLocationError;
    
    CLGeocoder *_geocoder;
    CLPlacemark *_placemark;
    BOOL _performingReverseGeocoding;
    NSError *_lastGeocodingError;
    
    UIActivityIndicatorView *spinner;
    SystemSoundID soundID;
    
    UIImageView *logoImageView;
    BOOL firstTime;
}

#pragma mark - init methods

-(id)initWithCoder:(NSCoder *)aDecoder{
    if((self = [super initWithCoder:aDecoder])){
        _locationManager = [[CLLocationManager alloc] init];
        _geocoder = [[CLGeocoder alloc] init];
        firstTime = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //self.navigationItem.title = @"asdasd";
    [self updateLabels];
    [self configureGetButton];
    [self loadSoundEffect];
    
    if (firstTime) {
        [self showLogoView];
    } else {
        [self hideLogoViewAnimated:NO];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CLLocationManagerDelegate
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"Locate failed: %@", error);
    if (error.code == kCLErrorLocationUnknown){
        return;
    }
    [self stopLocationManager];
    _lastLocationError = error;
    
    [self updateLabels];
    [self configureGetButton];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *newLocation = [locations lastObject];
    NSLog(@"Updated axis, current location: %@", newLocation);
    // some new locations that won't be used
    if ([newLocation.timestamp timeIntervalSinceNow] < -5.0) {
        return;
    }
    if (newLocation.horizontalAccuracy < 0) {
        return;
    }
    
    // calculate the distance
    CLLocationDistance distance = MAXFLOAT;
    if (_location != nil) {
        distance = [newLocation distanceFromLocation:_location];
    }
    
    // if last location is nil and new location is more accurate
    if (_location == nil || _location.horizontalAccuracy > newLocation.horizontalAccuracy) {
        // update related informations
        _lastLocationError = nil;
        _location = newLocation;
        [self updateLabels];
        // if the new location is desired -> stop
        if (newLocation.horizontalAccuracy <= _locationManager.desiredAccuracy) {
            NSLog(@"*** We're done!");
            [self stopLocationManager];
            [self configureGetButton];
            // if this is a new location, force a reverse geo coding
            if (distance > 0){
                _performingReverseGeocoding = NO;
            }
        }
    }
    //
    if (!_performingReverseGeocoding) {
        NSLog(@"*** Going to geocode");
        _performingReverseGeocoding = YES;
        [_geocoder reverseGeocodeLocation:_location completionHandler:^(NSArray *placemarks, NSError *error) {
            NSLog(@"*** Found placemarks: %@, error: %@", placemarks, error);
            
            _lastGeocodingError = error;
            if (error == nil && [placemarks count] > 0) {
                if (_placemark == nil) {
                    NSLog(@"First Time");
                    [self playSoundEffect];
                }
                _placemark = [placemarks lastObject];
            } else {
                _placemark = nil;
            }
            
            _performingReverseGeocoding = NO;
            [self updateLabels];
        }];
        // if distance < 1.0 and interval is > 10, then force to stop update
    } else if (distance < 1.0) {
        NSTimeInterval timeInterval = [newLocation.timestamp timeIntervalSinceDate:_location.timestamp];
        if (timeInterval > 10) {
            NSLog(@"*** Force done!");
            [self stopLocationManager];
            [self updateLabels];
            [self configureGetButton];
        }
    }
}

#pragma mark - my methods

// get location button taped
- (IBAction)getLocation:(id)sender {
    
    if (firstTime) {
        firstTime = NO;
        [self hideLogoViewAnimated:YES];
    }
    
    if(_updatingLocation){
        [self stopLocationManager];
    } else {
        _location = nil;
        _lastLocationError = nil;
        _placemark = nil;
        _lastGeocodingError = nil;
        [self startLocationManager];
    }
    [self updateLabels];
    [self configureGetButton];
    
}

-(void)updateLabels {
    if (_location != nil) {
        self.latitudeLabel.text = [NSString stringWithFormat:@"Latitude: %.8f", _location.coordinate.latitude];
        self.longtitudeLabel.text = [NSString stringWithFormat:@"Longitude: %.8f", _location.coordinate.longitude];
        self.altitudeLabel.text = [NSString stringWithFormat:@"Altitude: %.8f", _location.altitude];
        self.tagButton.hidden = NO;
        self.messageLabel.text = @"";
        if (_placemark != nil) {
            self.adderssLabel.text = [self stringFromPlacemark: _placemark];
        } else if (_performingReverseGeocoding) {
            self.adderssLabel.text = @"Searching for Address...";
        } else if (_lastGeocodingError != nil ){
            self.adderssLabel.text = @"Error Finding Address";
        } else {
            self.adderssLabel.text = @"No Address Found";
        }
    } else {
        self.latitudeLabel.text = @"";
        self.longtitudeLabel.text = @"";
        self.altitudeLabel.text = @"";
        self.adderssLabel.text = @"";
        self.tagButton.hidden = YES;
        
        NSString *statusMessage;
        if(_lastLocationError != nil){
            if ([_lastLocationError.domain isEqualToString:kCLErrorDomain] && _lastLocationError.code == kCLErrorDenied) {
                statusMessage = @"Location Services Disabled";
            } else {
                statusMessage = @"Error Getting Location";
            }
        } else if (![CLLocationManager locationServicesEnabled]) {
            statusMessage = @"Location Services Disabled";
        } else if (_updatingLocation) {
            statusMessage = @"Searching...";
        } else {
            statusMessage = @"Press the Button to Start";
        }
        
        self.messageLabel.text = statusMessage;
    }
}

-(void)startLocationManager {
    if ([CLLocationManager locationServicesEnabled]) {
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        [_locationManager startUpdatingLocation];
        _updatingLocation = YES;
        
        [self performSelector:@selector(didTimeOut:) withObject:nil afterDelay:60];
    }
}

-(void)stopLocationManager{
    if (_updatingLocation) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(didTimeOut:) object:nil];
        
        [_locationManager stopUpdatingLocation];
        _locationManager.delegate = nil;
        _updatingLocation = NO;
    }
}

-(void)configureGetButton {
    if (_updatingLocation) {
        [self.getButton setTitle:@"STOP" forState:UIControlStateNormal];
        spinner = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
        spinner.center = CGPointMake(self.getButton.bounds.size.width - spinner.bounds.size.width / 2.0f - 10, self.getButton.bounds.size.height / 2.0f);
        [spinner startAnimating];
        [self.getButton addSubview:spinner];
    } else {
        [self.getButton setTitle:@"Get My Location" forState:UIControlStateNormal];
        
        [spinner removeFromSuperview];
        spinner = nil;
    }
}

-(NSString *)stringFromPlacemark: (CLPlacemark *)thePlacemark {
    NSMutableString *line1 = [NSMutableString stringWithCapacity:100];
    [line1 addText:thePlacemark.subThoroughfare withSeparator:@""];
    [line1 addText:thePlacemark.thoroughfare withSeparator:@" "];
    
    NSMutableString *line2 = [NSMutableString stringWithCapacity:100];
    [line2 addText:thePlacemark.locality withSeparator:@""];
    [line2 addText:thePlacemark.administrativeArea withSeparator:@" "];
    [line2 addText:thePlacemark.postalCode withSeparator:@" "];
    
    if ([line1 length] == 0) {
        [line2 appendString:@"\n "];  // need two lines or UILabel will vertically center the text
        return line2;
    } else {
        [line1 appendString:@"\n"];
        [line1 appendString:line2];
        return line1;
    }
}

-(void)didTimeOut:(id)obj {
    NSLog(@"*** Time Out");
    if (_location == nil) {
        [self stopLocationManager];
        
        _lastLocationError = [NSError errorWithDomain:@"MyLocationsErrorDomain" code:1 userInfo:nil];
        [self updateLabels];
        [self configureGetButton];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"TagLocation"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        LocationDetailsViewController *controller = (LocationDetailsViewController *) navigationController.topViewController;
        
        controller.managedObjectContext = self.managedObjectContext;
        
        controller.coordinate = _location.coordinate;
        controller.placemark = _placemark;
        
        
    }
}

#pragma mark - Sound Effect
- (void)loadSoundEffect
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Sound.caf" ofType:nil];
    
    NSURL *fileURL = [NSURL fileURLWithPath:path isDirectory:NO];
    if (fileURL == nil) {
        NSLog(@"NSURL is nil for path: %@", path);
        return;
    }
    
    OSStatus error = AudioServicesCreateSystemSoundID((__bridge CFURLRef)fileURL, &soundID);
    if (error != kAudioServicesNoError) {
        NSLog(@"Error code %ld loading sound at path: %@", error, path);
        return;
    }
}

- (void)unloadSoundEffect
{
    AudioServicesDisposeSystemSoundID(soundID);
    soundID = 0;
}

- (void)playSoundEffect
{
    AudioServicesPlaySystemSound(soundID);
}

#pragma mark - Logo View

- (void)showLogoView
{
    self.panelView.hidden = YES;
    
    logoImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Logo"]];
    logoImageView.center = CGPointMake(160.0f, 140.0f);
    [self.view addSubview:logoImageView];
}

- (void)hideLogoViewAnimated:(BOOL)animated
{
    self.panelView.hidden = NO;
    
    if (animated) {
        
        self.panelView.center = CGPointMake(600.0f, 140.0f);
        
        CABasicAnimation *panelMover = [CABasicAnimation animationWithKeyPath:@"position"];
        panelMover.removedOnCompletion = NO;
        panelMover.fillMode = kCAFillModeForwards;
        panelMover.duration = 0.6f;
        panelMover.fromValue = [NSValue valueWithCGPoint:self.panelView.center];
        panelMover.toValue = [NSValue valueWithCGPoint:CGPointMake(160.0f, self.panelView.center.y)];
        panelMover.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        panelMover.delegate = self;
        [self.panelView.layer addAnimation:panelMover forKey:@"panelMover"];
        
        CABasicAnimation *logoMover = [CABasicAnimation animationWithKeyPath:@"position"];
        logoMover.removedOnCompletion = NO;
        logoMover.fillMode = kCAFillModeForwards;
        logoMover.duration = 0.5f;
        logoMover.fromValue = [NSValue valueWithCGPoint:logoImageView.center];
        logoMover.toValue = [NSValue valueWithCGPoint:CGPointMake(-160.0f, logoImageView.center.y)];
        logoMover.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        [logoImageView.layer addAnimation:logoMover forKey:@"logoMover"];
        
        CABasicAnimation *logoRotator = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        logoRotator.removedOnCompletion = NO;
        logoRotator.fillMode = kCAFillModeForwards;
        logoRotator.duration = 0.5f;
        logoRotator.fromValue = [NSNumber numberWithFloat:0];
        logoRotator.toValue = [NSNumber numberWithFloat:-2*M_PI];
        logoRotator.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
        [logoImageView.layer addAnimation:logoRotator forKey:@"logoRotator"];
        
    } else {
        [logoImageView removeFromSuperview];
        logoImageView = nil;
    }
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    [self.panelView.layer removeAllAnimations];
    self.panelView.center = CGPointMake(160.0f, 140.0f);
    
    [logoImageView.layer removeAllAnimations];
    [logoImageView removeFromSuperview];
    logoImageView = nil;
}

@end
