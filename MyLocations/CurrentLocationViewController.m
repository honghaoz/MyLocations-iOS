//
//  FirstViewController.m
//  MyLocations
//
//  Created by Zhang Honghao on 1/31/14.
//  Copyright (c) 2014 org-honghao. All rights reserved.
//

#import "CurrentLocationViewController.h"
#import "LocationDetailViewController.h"

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
}

#pragma mark - init methods

-(id)initWithCoder:(NSCoder *)aDecoder{
    if((self = [super initWithCoder:aDecoder])){
        _locationManager = [[CLLocationManager alloc] init];
        _geocoder = [[CLGeocoder alloc] init];
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
    } else {
        [self.getButton setTitle:@"Get My Location" forState:UIControlStateNormal];
    }
}

-(NSString *)stringFromPlacemark: (CLPlacemark *)thePlacemark {
    return [NSString stringWithFormat:@"%@ %@\n %@ %@ %@",
            thePlacemark.subThoroughfare, thePlacemark.thoroughfare,
            thePlacemark.locality, thePlacemark.administrativeArea, thePlacemark.postalCode];
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
        LocationDetailViewController *controller = (LocationDetailViewController *) navigationController.topViewController;
        controller.coordinate = _location.coordinate;
        controller.placemark = _placemark;
        
    }
}

@end
