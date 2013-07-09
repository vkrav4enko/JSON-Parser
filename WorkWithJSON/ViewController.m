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
@interface ViewController ()


@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    [_locationManager startUpdatingLocation];
    [_locationManager performSelector:@selector(stopUpdatingLocation) withObject:nil afterDelay:1.0f];

    _mapView.showsUserLocation = NO;
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
                                            [NSArray arrayWithObjects:
                                             @"Map",
                                             @"Satellite",
                                             @"Hybrid",
                                             nil]];
    [segmentedControl addTarget:self action:@selector(changeMapType:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.frame = CGRectMake(0.0f, 43.0f, 200.0f, 30.0f);
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    
    [self.view addSubview:segmentedControl];
    

    [_mapView addAnnotation:[_mapView userLocation]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    NSString *strURL = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f", newLocation.coordinate.latitude, newLocation.coordinate.longitude];
    
    NSString *weather  = [NSString stringWithContentsOfURL:[NSURL URLWithString:strURL] encoding:NSUTF8StringEncoding error:nil];
    
    ParseJSON *parser = [[ParseJSON alloc] initWithString:weather];
    id obj = [parser parse];
    NSLog(@"%@", obj);
    
    Annotation *annotation = [Annotation new];
    annotation.title = @"Current location";
    annotation.subtitle = [NSString stringWithFormat:@"Temperature = %@", [[obj objectForKey:@"main"] objectForKey:@"temp"]];
    annotation.coordinate = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    [_mapView addAnnotation:annotation];
    [self openAnnotation:annotation];
    MKCoordinateRegion region = self.mapView.region;
    region.center = CLLocationCoordinate2DMake(newLocation.coordinate.latitude, newLocation.coordinate.longitude);
    region.span.longitudeDelta /= 2; // Bigger the value, closer the map view
    region.span.latitudeDelta /= 2;
    [self.mapView setRegion:region animated:YES];

}

- (void)changeMapType:(UISegmentedControl*)sender {
    if (sender.selectedSegmentIndex == 0) {
        _mapView.mapType = MKMapTypeStandard;
    } else if (sender.selectedSegmentIndex == 1) {
        _mapView.mapType = MKMapTypeSatellite;
    } else if (sender.selectedSegmentIndex == 2) {
        _mapView.mapType = MKMapTypeHybrid;
    }
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
    Annotation *annotation = [Annotation new];
    annotation.title = textField.text;
    
    
    NSString *cityName = [NSString stringWithString:textField.text];
    NSString *strURL = [NSString stringWithFormat:@"http://maps.google.com/maps/api/geocode/json?address=%@&sensor=true", cityName];
    NSString *geocode  = [NSString stringWithContentsOfURL:[NSURL URLWithString:strURL] encoding:NSUTF8StringEncoding error:nil];
    ParseJSON *parcer = [[ParseJSON alloc] initWithString:geocode];
    id obj = [parcer parse];
    NSLog(@"%@", obj);
    
    NSNumber *number = [[[[[obj objectForKey: @"results"] objectAtIndex:0] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"] ;
    float lat = [number floatValue];
    number = [[[[[obj objectForKey: @"results"] objectAtIndex:0] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"] ;
    float lng = [number floatValue];
    
    strURL = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f", lat, lng];
    
    NSString *weather  = [NSString stringWithContentsOfURL:[NSURL URLWithString:strURL] encoding:NSUTF8StringEncoding error:nil];
    
    ParseJSON *parser2 = [[ParseJSON alloc] initWithString:weather];
    id obj2 = [parser2 parse];
    annotation.subtitle = [NSString stringWithFormat:@"temperature = %@", [[obj2 objectForKey:@"main"] objectForKey:@"temp"]];
    
    NSLog(@"lat = %f, lng = %f", lat, lng);
    
    annotation.coordinate = CLLocationCoordinate2DMake(lat, lng);
    [_mapView addAnnotation:annotation];
    
    MKCoordinateRegion region = self.mapView.region;
    region.center = CLLocationCoordinate2DMake(lat, lng);
    region.span.longitudeDelta /= 2; // Bigger the value, closer the map view
    region.span.latitudeDelta /= 2;
    [self.mapView setRegion:region animated:YES];
    [self.view endEditing:YES];
    [self openAnnotation:annotation];
    return YES;

}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.text = @"";
    return YES;
}

@end
