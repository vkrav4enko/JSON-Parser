//
//  ViewController.m
//  WorkWithJSON
//
//  Created by Владимир on 08.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "ViewController.h"
#import "ParseJSON.h"
@interface ViewController ()


@property (nonatomic, strong) NSTimer *timer;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:60.0f
                                              target:self
                                            selector:@selector(tick)
                                            userInfo:nil
                                             repeats:YES];
    
  
    _locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    [_locationManager startUpdatingLocation];
    [_locationManager performSelector:@selector(stopUpdatingLocation) withObject:nil afterDelay:1.0f];

    
    _mapView.showsUserLocation = YES;
    [_mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
                                            [NSArray arrayWithObjects:
                                             @"Map",
                                             @"Satellite",
                                             @"Hybrid",
                                             nil]];
    [segmentedControl addTarget:self action:@selector(changeMapType:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.frame = CGRectMake(55.0f, 120.0f, 200.0f, 30.0f);
    segmentedControl.selectedSegmentIndex = 0;
    segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    
    [self.view addSubview:segmentedControl];
    
    
   
    
//    
//    ParseJSON *parser = [[ParseJSON alloc] initWithString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]];
//    
//    
//    id obj = [parser parse];
//    NSLog(@"%@", obj);

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
    
    if ([obj isKindOfClass: [NSDictionary class]])
    {
        _textField.text = [NSString stringWithFormat:@"City: %@ \nCountry: %@ \nTemperature: %@ \nPressure: %@ \nWind: %@", [obj objectForKey:@"name"], [[obj objectForKey:@"sys"] objectForKey:@"country"], [[obj objectForKey:@"main"] objectForKey:@"temp"], [[obj objectForKey:@"main"] objectForKey:@"pressure"], [[obj objectForKey:@"wind"] objectForKey:@"speed"] ];
    }
  
    
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

- (void) tick
{
    NSLog(@"time tick");
    
    [_locationManager startUpdatingLocation];
    [_locationManager performSelector:@selector(stopUpdatingLocation) withObject:nil afterDelay:1.0f];
    
    
}

@end
