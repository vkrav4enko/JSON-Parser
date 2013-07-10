//
//  ViewController.m
//  WorkWithJSON
//
//  Created by Владимир on 08.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "ViewController.h"
#import "ParseJSON.h"
#import "Annotation.h"
@interface ViewController () <UIAlertViewDelegate>


@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        
        [NSTimer scheduledTimerWithTimeInterval:2 target:self
                                       selector:@selector(timerFired:)
                                       userInfo:nil
                                        repeats:YES];
        
    }
    
    [self showCurrentLocation:nil];
    _mapView.showsUserLocation = NO;
    
    
    UIButton *buttonHome = [UIButton buttonWithType:UIButtonTypeRoundedRect];       
    buttonHome.frame = CGRectMake(0.0f, 7.0f, 50.0f, 30.0f);
    [buttonHome setTitle:@"Home" forState:UIControlStateNormal];
    [buttonHome addTarget:self action:@selector(showCurrentLocation:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:buttonHome];     
}

- (void)timerFired:(NSTimer*)theTimer{
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        [self showCurrentLocation:nil];
        [theTimer invalidate];
    }
    [_locationManager startUpdatingLocation];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    [_mapView removeAnnotations:_mapView.annotations];
    NSString *strURL = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f", newLocation.coordinate.latitude, newLocation.coordinate.longitude];
    
    NSString *weather  = [NSString stringWithContentsOfURL:[NSURL URLWithString:strURL] encoding:NSUTF8StringEncoding error:nil];
    
    ParseJSON *parser = [[ParseJSON alloc] initWithString:weather];
    id obj = [parser parse];
    
    
    Annotation *annotation = [Annotation new];
    annotation.title = @"Current location";
    NSNumber *temperature = [[obj objectForKey:@"main"] objectForKey:@"temp"];    
    annotation.subtitle = [NSString stringWithFormat:@"temperature = %.0f ºC", [temperature floatValue] - 273.15f];
    annotation.coordinate = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    [_mapView addAnnotation:annotation];
    [self openAnnotation:annotation];
    MKCoordinateRegion region = self.mapView.region;
    region.center = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    region.span.longitudeDelta = 10.0f;
    region.span.latitudeDelta = 15.0f;
    [self.mapView setRegion:region animated:YES];
    

}

- (void)showCurrentLocation:(UIButton*)sender {
    
        [_locationManager startUpdatingLocation];
        [_locationManager performSelector:@selector(stopUpdatingLocation) withObject:nil afterDelay:1.0f];
        [self.view endEditing:YES];
}



- (MKAnnotationView *) mapView:(MKMapView *)map viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString *pinID = @"mapPin";
    MKAnnotationView *pinAnnotation = nil;
    pinAnnotation = (MKAnnotationView *)[_mapView dequeueReusableAnnotationViewWithIdentifier:pinID];
    if (pinAnnotation == nil)
        pinAnnotation = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pinID] ;
    
    pinAnnotation.canShowCallout = YES;
    return pinAnnotation;
    

}

- (void)openAnnotation:(id)annotation;
{
    [_mapView selectAnnotation:annotation animated:YES];
    
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    @try {
        [_mapView removeAnnotations:_mapView.annotations];
        Annotation *annotation = [Annotation new];
        annotation.title = textField.text;
        
        
        NSString *cityName = [NSString stringWithString:textField.text];
        NSString *strURL = [NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?address=%@&sensor=true", cityName];
        NSString *geocode  = [NSString stringWithContentsOfURL:[NSURL URLWithString:strURL] encoding:NSUTF8StringEncoding error:nil];
        ParseJSON *parcer = [[ParseJSON alloc] initWithString:geocode];
        id obj = [parcer parse];
        
        
        NSNumber *number = [[[[[obj objectForKey: @"results"] objectAtIndex:0] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] ;
        float lat = [number floatValue];
        number = [[[[[obj objectForKey: @"results"] objectAtIndex:0] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] ;
        float lng = [number floatValue];
        
        strURL = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f", lat, lng];
        
        NSString *weather  = [NSString stringWithContentsOfURL:[NSURL URLWithString:strURL] encoding:NSUTF8StringEncoding error:nil];
        
        ParseJSON *parser2 = [[ParseJSON alloc] initWithString:weather];
        id obj2 = [parser2 parse];
        
        NSNumber *temperature = [[obj2 objectForKey:@"main"] objectForKey:@"temp"];
        
        annotation.subtitle = [NSString stringWithFormat:@"temperature = %.0f ºC", [temperature floatValue] - 273.15f];
        
        NSLog(@"lat = %f, lng = %f", lat, lng);
        
        annotation.coordinate = CLLocationCoordinate2DMake(lat, lng);
        [_mapView addAnnotation:annotation];
        
        MKCoordinateRegion region = self.mapView.region;
        region.center = CLLocationCoordinate2DMake(lat, lng);
        region.span.longitudeDelta = 10.0f;
        region.span.latitudeDelta = 15.0f;
        [self.mapView setRegion:region animated:YES];
        [self.view endEditing:YES];
        [self openAnnotation:annotation];
        }
    @catch (NSException *exception) {
        NSLog(@"Error with exception: %@ for reason: %@", [exception name], [exception reason]);
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"City name is not correct" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
       
    }
    return YES;

}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self showCurrentLocation:nil];
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.text = @"";
    return YES;
}

@end
