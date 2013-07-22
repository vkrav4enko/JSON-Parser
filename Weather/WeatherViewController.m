//
//  WeatherViewController.m
//  WorkWithJSON
//
//  Created by Владимир on 19.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "WeatherViewController.h"
#import "MMDrawerBarButtonItem.h"
#import "MMDrawerController.h"
#import "UIViewController+MMDrawerController.h"
#import "OWMWeatherAPI.h"

@interface WeatherViewController ()

@property (nonatomic, strong) NSArray *forecast;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) OWMWeatherAPI *weatherAPI;
@end

@implementation WeatherViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    MMDrawerBarButtonItem * leftDrawerButton = [[MMDrawerBarButtonItem alloc] initWithTarget:self action:@selector(leftDrawerButtonPress:)];
    [self.navigationItem setLeftBarButtonItem:leftDrawerButton animated:YES];
	
    
}

- (void)viewDidAppear:(BOOL)animated
{
    // Setup weather api
    
    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"MMMM dd HH:mm"];
    _forecast = @[];
    _weatherAPI = [[OWMWeatherAPI alloc] initWithAPIKey:@"Weather"];
    
    self.title = @"Current weather";
    
    [_activityIndicator startAnimating];
    
    
    _locationManager = [CLLocationManager new];
    _locationManager.delegate = self;
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusNotDetermined) {
        
        [NSTimer scheduledTimerWithTimeInterval:2 target:self
                                       selector:@selector(timerFired:)
                                       userInfo:nil
                                        repeats:YES];
        
    }
    [_locationManager startUpdatingLocation];
}

-(void)leftDrawerButtonPress:(id)sender{
    [self.mm_drawerController toggleDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - LocationManager updating methods

- (void)timerFired:(NSTimer*)theTimer{
    
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        [theTimer invalidate];
    }
    [_locationManager startUpdatingLocation];
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{    
    [_weatherAPI currentWeatherByCoordinate:newLocation.coordinate withCallback:^(NSError *error, NSDictionary *result) {
        if (error) {
            NSLog(@"OpenWeatherApi error:");
            return;
        }
        self.cityName.text = [NSString stringWithFormat:@"%@, %@",
                              result[@"name"],
                              result[@"sys"][@"country"]
                              ];
        
        self.currentTemp.text = [NSString stringWithFormat:@"%.1f℃",
                                 [result[@"main"][@"temp"] floatValue] ];
        
        self.currentTimestamp.text =  [_dateFormatter stringFromDate:result[@"dt"]];
        
        self.weather.text = result[@"weather"][0][@"description"];        
        
    }];
    
    [_weatherAPI forecastWeatherByCoordinate: newLocation.coordinate withCallback:^(NSError *error, NSDictionary *result) {
        
        if (error) {
            NSLog(@"OpenWeatherApi error:");
            return;
        }
        
        _forecast = result[@"list"];
        [self.forecastTableView reloadData];
        [self.activityIndicator stopAnimating];
        [_locationManager stopUpdatingLocation];
            
    }];
    
   
        
}

#pragma mark - tableview datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _forecast.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }
    
    NSDictionary *forecastData = [_forecast objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%.1f℃ - %@",
                           [forecastData[@"main"][@"temp"] floatValue],
                           forecastData[@"weather"][0][@"main"]
                           ];
    
    cell.detailTextLabel.text = [_dateFormatter stringFromDate:forecastData[@"dt"]];
    
    return cell;
    
}



@end
