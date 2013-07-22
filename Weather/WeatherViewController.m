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
#import "SearchViewController.h"
#import "AppDelegate.h"
#import "WeatherInfo.h"
#import "NSManagedObject+ActiveRecord.h"

@interface WeatherViewController ()

@property (nonatomic, strong) NSArray *forecast;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) OWMWeatherAPI *weatherAPI;
@property (nonatomic, strong) NSDictionary *result;
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
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    _cityName.text = appDelegate.cityName;
    NSLog(@"%@",_cityName.text);
    
    if (![_cityName.text isEqualToString:@""])
    {        
        [_weatherAPI currentWeatherByCityName:_cityName.text withCallback:^(NSError *error, NSDictionary *result) {
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
        [_weatherAPI forecastWeatherByCityName:_cityName.text withCallback:^(NSError *error, NSDictionary *result) {
            
            if (error) {
                NSLog(@"OpenWeatherApi error:");
                return;
            }
            
            _forecast = result[@"list"];
            [self.forecastTableView reloadData];
            [self.activityIndicator stopAnimating];
            [_locationManager stopUpdatingLocation];
            
        }];
        appDelegate.cityName = @"";
    }
    else
    {
        [_locationManager startUpdatingLocation];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Detail" style:UIBarButtonItemStyleBordered target:self action:@selector(showDetail:)];
    }
}

- (void) showDetail: (id) sender{
    
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    NSManagedObjectContext *context = appDelegate.managedObjectContext;
    WeatherInfo* newWeatherInfo = [NSEntityDescription insertNewObjectForEntityForName:@"WeatherInfo" inManagedObjectContext:context];
    newWeatherInfo.city = _result[@"name"];
    newWeatherInfo.clouds = [NSString stringWithFormat:@"Clouds: %@%%",[[_result objectForKey:@"clouds"] objectForKey:@"all"]];
    newWeatherInfo.wind = [NSString stringWithFormat:@"Wind: %@ mps", [[_result objectForKey:@"wind"] objectForKey:@"speed"]];
    newWeatherInfo.humidity = [NSString stringWithFormat:@"Humidity: %@%%", [[_result objectForKey:@"main"] objectForKey:@"humidity"]];
    NSNumber *temperature = [[_result objectForKey:@"main"] objectForKey:@"temp"];
    newWeatherInfo.temperature = [NSString stringWithFormat:@"%.0f", [temperature floatValue] ];
    newWeatherInfo.pressure = [NSString stringWithFormat:@"Pressure: %@hPa", [[_result objectForKey:@"main"] objectForKey:@"pressure"]];
    newWeatherInfo.timeStamp = [NSDate date];
    NSString *filter = [NSString stringWithFormat:@"city like \"%@\"", [_result objectForKey:@"name"]];
    NSArray *entities = [WeatherInfo findAllSortedBy:@"city" ascending:NO withPredicate:[NSPredicate predicateWithFormat:filter] inContext:context];
    NSLog(@"%@", entities);
    WeatherInfo *info = [entities objectAtIndex:0];
    NSLog(@"%@", info.city);

    NSError *saveError;
    if (![context save:&saveError]) {
        NSLog(@"Whoops, couldn't save: %@", [saveError localizedDescription]);
    }
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:[storyboard instantiateViewControllerWithIdentifier:@"History"]];
    [self.mm_drawerController setCenterViewController:navigationController withCloseAnimation:YES completion:nil];
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
        _result = result;
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
