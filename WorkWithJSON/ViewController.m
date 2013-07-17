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
#import "AppDelegate.h"
#import "WeatherInfo.h"
#import "NSManagedObject+ActiveRecord.h"

@interface ViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) NSTimer *timer;
- (BOOL) findWithCityName: (NSString *) city;

@end

@implementation ViewController

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
    
    
    UIButton *buttonHome = [UIButton buttonWithType:UIButtonTypeRoundedRect];       
    buttonHome.frame = CGRectMake(0.0f, 7.0f, 50.0f, 30.0f);
    [buttonHome setTitle:@"Home" forState:UIControlStateNormal];
    [buttonHome addTarget:self action:@selector(showCurrentLocation:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:buttonHome];
    
    UIButton *buttonWeather = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    buttonWeather.frame = CGRectMake(270.0f, 7.0f, 50.0f, 30.0f);
    [buttonWeather setTitle:@"Show" forState:UIControlStateNormal];
    [buttonWeather addTarget:self action:@selector(showWeather:) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:buttonWeather];
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

- (void) showWeather: (UIButton*) sender {
    NSLog(@"%@", _textField.text);
    if(![self findWithCityName:_textField.text] && ![_textField.text isEqualToString:@""])
    {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Oops" message:@"City name is not correct" delegate:self cancelButtonTitle:@"Try again" otherButtonTitles: @"I don't care", nil];
        alert.tag = 0;
        [alert show];
                
    }
    else
    {        
        AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
        NSManagedObjectContext *context = appDelegate.managedObjectContext;
        WeatherInfo* newWeatherInfo = [NSEntityDescription insertNewObjectForEntityForName:@"WeatherInfo" inManagedObjectContext:context];
        
        newWeatherInfo.city = [_parsedDictionary objectForKey:@"name"];
        newWeatherInfo.clouds = [NSString stringWithFormat:@"Clouds: %@%%",[[_parsedDictionary objectForKey:@"clouds"] objectForKey:@"all"]];
        newWeatherInfo.wind = [NSString stringWithFormat:@"Wind: %@ mps", [[_parsedDictionary objectForKey:@"wind"] objectForKey:@"speed"]];
        newWeatherInfo.humidity = [NSString stringWithFormat:@"Humidity: %@%%", [[_parsedDictionary objectForKey:@"main"] objectForKey:@"humidity"]];
        NSNumber *temperature = [[_parsedDictionary objectForKey:@"main"] objectForKey:@"temp"];    
        [NSString stringWithFormat:@"temperature = %.0f ºC", [temperature floatValue] - 273.15f];
        newWeatherInfo.temperature = [NSString stringWithFormat:@"%.0f", [temperature floatValue] - 273.15f];
        newWeatherInfo.pressure = [NSString stringWithFormat:@"Pressure: %@hPa", [[_parsedDictionary objectForKey:@"main"] objectForKey:@"pressure"]];
        newWeatherInfo.timeStamp = [NSDate date];
        
        
        NSString *filter = [NSString stringWithFormat:@"city like \"%@\"", [_parsedDictionary objectForKey:@"name"]];
        NSArray *entities = [WeatherInfo findAllSortedBy:@"city" ascending:NO withPredicate:[NSPredicate predicateWithFormat:filter] inContext:context];
        NSLog(@"%@", entities);
        WeatherInfo *info = [entities objectAtIndex:0];
        NSLog(@"%@", info.city);
        

        
        NSError *error;
        if (![context save:&error]) {
            NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
        }
        
        [self.tabBarController setSelectedIndex:1];
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
            [self.tabBarController setSelectedIndex:0];
            [_textField becomeFirstResponder];
            
        }
        else
            [self.tabBarController setSelectedIndex:1];
              
    }
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.text = @"";
    return YES;
}

@end
