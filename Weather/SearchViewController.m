//
//  ViewController.m
//  WorkWithJSON
//
//  Created by Владимир on 08.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "SearchViewController.h"
#import "ParseJSON.h"
#import "Annotation.h"
#import "AppDelegate.h"
#import "WeatherInfo.h"
#import "NSManagedObject+ActiveRecord.h"
#import "MMDrawerBarButtonItem.h"
#import "MMDrawerController.h"
#import "UIViewController+MMDrawerController.h"
#import "WeatherViewController.h"

@interface SearchViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) NSTimer *timer;
- (BOOL) findWithCityName: (NSString *) city;

@end

@implementation SearchViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.title = @"Weather map";
    
    
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
    MMDrawerBarButtonItem * leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(leftDrawerButtonPress:)];
    [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES]; 
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Home" style:UIBarButtonItemStyleBordered target:self action:@selector(showCurrentLocation:)];
           
    _textField.returnKeyType = UIReturnKeySearch;
    
    
//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Show" style:UIBarButtonItemStyleBordered target:self action:@selector(showWeather:)];
}

-(void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
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
    _parsedDictionary  = obj;
    
    
    Annotation *annotation = [Annotation new];
    annotation.title = @"Current location";
    NSNumber *temperature = [[obj objectForKey:@"main"] objectForKey:@"temp"];    
    annotation.subtitle = [NSString stringWithFormat:@"temperature = %.0f ºC", [temperature floatValue] - 273.15f];
    annotation.coordinate = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    
    MKCoordinateRegion region = self.mapView.region;
    region.center = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    region.span.longitudeDelta = 10.0f;
    region.span.latitudeDelta = 15.0f;
    [self.mapView setRegion:region animated:YES];
    
    [_mapView addAnnotation:annotation];
    [self openAnnotation:annotation];
    if (annotation)
    [_locationManager stopUpdatingLocation];
    

}

- (void)showCurrentLocation:(UIButton*)sender {
    
    [_locationManager startUpdatingLocation];
    //[_locationManager performSelector:@selector(stopUpdatingLocation) withObject:nil afterDelay:1.0f];
    [self.view endEditing:YES];
}



- (void)openAnnotation:(id)annotation;
{
    [_mapView selectAnnotation:annotation animated:YES];
    
}

- (BOOL) findWithCityName: (NSString *) city
{
    @try {
        [_mapView removeAnnotations:_mapView.annotations];
        Annotation *annotation = [Annotation new];
        annotation.title = city;
        
        
        NSString *cityName = [NSString stringWithString:city];
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
        _parsedDictionary  = obj2;
        
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
        return YES;
    }
    @catch (NSException *exception) {
        return NO;
    }

}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (![self findWithCityName:textField.text])
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"City name is not correct" delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
        alert.tag = 1;
        [alert show];
    }
    [textField endEditing:YES];
    return YES;

}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1)
        [self showCurrentLocation:nil];
    else
    {
        if (buttonIndex == 0)
        {
            [self showCurrentLocation:nil];
            _textField.text = @"";
            
        }
        else
        {
            UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
            UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:[storyboard instantiateViewControllerWithIdentifier:@"History"]];
            [self.mm_drawerController setCenterViewController:navigationController withCloseAnimation:YES completion:nil];
        }
        
    }
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.text = @"";
    return YES;
}

#pragma mark - MKMapViewDelegate methods 

- (void)mapView:(MKMapView *)mapView regionWillChangeAnimated:(BOOL)animated
{
    [_textField endEditing:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    static NSString* annotationIdentifier = @"annotationIdentifier";
    MKPinAnnotationView* annotationView = (MKPinAnnotationView *)[mapView
                                                                  dequeueReusableAnnotationViewWithIdentifier:
                                                                  annotationIdentifier];
    if (!annotationView) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:nil];
    }
    
    [annotationView setPinColor:MKPinAnnotationColorRed];
    [annotationView setPinColor:MKPinAnnotationColorGreen];
    annotationView.animatesDrop = YES;
    annotationView.canShowCallout = YES;
    annotationView.rightCalloutAccessoryView = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control
{
    Annotation *annotationTapped = (Annotation *)view.annotation;
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    
    
    if (![annotationTapped.title isEqualToString:@"Current location"])
    {
        appDelegate.cityName = annotationTapped.title;
    }
    
    UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:[storyboard instantiateViewControllerWithIdentifier:@"Weather"]];
    [self.mm_drawerController setCenterViewController:navigationController withCloseAnimation:YES completion:nil];
    
}



@end






