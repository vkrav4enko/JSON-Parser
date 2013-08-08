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
#import "AppDelegate.h"
#import "WeatherInfo.h"
#import "NSManagedObject+ActiveRecord.h"
#import "MBProgressHUD.h"
#import "Weather.h"

@interface WeatherViewController ()

@property (nonatomic, strong) NSArray *forecast;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) OWMWeatherAPI *weatherAPI;
@property (nonatomic, strong) NSDictionary *result;
@property (nonatomic) float lat;
@property (nonatomic) float lon;

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
    
    self.title = @"Weather";
    
    
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    
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
        self.title = _cityName.text;
        [_weatherAPI currentWeatherByCityName:_cityName.text withCallback:^(NSError *error, NSDictionary *result) {
            if (error) {
                NSLog(@"OpenWeatherApi error:");
                return;
            }
            self.cityName.text = [NSString stringWithFormat:@"%@, %@",
                                  result[@"name"],
                                  result[@"sys"][@"country"]
                                  ];
            self.title = _cityName.text;            
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
            [MBProgressHUD hideHUDForView:self.view animated:YES];
            [_locationManager stopUpdatingLocation];
            
        }];
        appDelegate.cityName = @"";
    }
    else
    {
        [_locationManager startUpdatingLocation];
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Details" style:UIBarButtonItemStyleBordered target:self action:@selector(showDetail:)];
    }
}

- (void) showDetail: (id) sender{
    
    RKManagedObjectStore *managedObjectStore = [RKManagedObjectStore defaultStore];
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"WeatherInfo" inManagedObjectStore:managedObjectStore];
    [entityMapping addAttributeMappingsFromDictionary:@{
     @"name":          @"city",
     @"clouds.all":    @"clouds",
     @"wind.speed":    @"wind",
     @"main.humidity": @"humidity",
     @"main.temp":     @"temperature",
     @"main.pressure": @"pressure",
     @"dt":            @"timeStamp"}];
     
    
    RKLogConfigureByName("RestKit/Network", RKLogLevelTrace);
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodGET pathPattern:@"/data/2.5/:weather" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];    
    [[RKObjectManager sharedManager] addResponseDescriptor:responseDescriptor];
    NSString *path = [NSString stringWithFormat:@"/data/2.5/weather?lat=%f&lon=%f", _lat , _lon];
    [[RKObjectManager sharedManager] getObjectsAtPath:path parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {        
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        
    }];
    
    
    
    
    
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
    _lat = newLocation.coordinate.latitude;
    _lon = newLocation.coordinate.longitude;
    
    //Current Weather
    RKObjectMapping *weatherMapping = [RKObjectMapping mappingForClass:[Weather class]];
    [weatherMapping addAttributeMappingsFromDictionary:
     @{@"dt": @"timeStamp",
     @"main.temp": @"temperature",
     @"weather": @"weatherInfo",
     @"name": @"city"
     }];
    RKResponseDescriptor *weatherResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:weatherMapping method:RKRequestMethodGET pathPattern:@"/data/2.5/:weather" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [[RKObjectManager sharedManager] addResponseDescriptor:weatherResponseDescriptor];
    NSString *pathWeather = [NSString stringWithFormat:@"/data/2.5/weather?lat=%f&lon=%f", _lat , _lon];
    [[RKObjectManager sharedManager] getObject:[Weather new] path:pathWeather parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        
        Weather *weather = mappingResult.array [0];
        self.cityName.text = weather.city;
        self.navigationItem.prompt = _cityName.text;
        
        self.currentTemp.text = [self stringTemperature:weather.temperature];
        
        self.currentTimestamp.text =  [_dateFormatter stringFromDate:weather.timeStamp];
        
        self.weather.text = [[weather.weatherInfo objectAtIndex:0] objectForKey:@"description"];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        RKLogError(@"Operation failed with error: %@", error);
    }];

    //Forecast Table
    RKObjectMapping *forecastMapping = [RKObjectMapping mappingForClass:[Weather class]];
    [forecastMapping addAttributeMappingsFromDictionary:
     @{@"dt": @"timeStamp",
       @"weather": @"weatherInfo",
       @"main.temp": @"temperature",
     }];
    
    RKResponseDescriptor *forecastResponceDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:forecastMapping method:RKRequestMethodGET pathPattern:@"/data/2.5/:forecast" keyPath:@"list" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    NSString *pathForecast = [NSString stringWithFormat:@"/data/2.5/forecast?lat=%f&lon=%f", _lat , _lon];
    [[RKObjectManager sharedManager] addResponseDescriptor:forecastResponceDescriptor];
        
    [[RKObjectManager sharedManager] getObject:[Weather new] path:pathForecast parameters:nil success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        _forecast = [NSArray arrayWithArray:mappingResult.array];
        [self.forecastTableView reloadData];        
        [_locationManager stopUpdatingLocation];
        
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        RKLogError(@"Operation failed with error: %@", error);
    }];
    [MBProgressHUD hideHUDForView:self.view animated:YES];

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
    
    Weather *weather = [_forecast objectAtIndex:indexPath.row];
    cell.textLabel.text = [self stringTemperature:weather.temperature];
    
    cell.detailTextLabel.text = [_dateFormatter stringFromDate:weather.timeStamp];
    
    return cell;
    
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Forecast";
}

- (NSString *) stringTemperature: (NSNumber *) temperature
{
    float temp = [temperature floatValue] - 273.15;
    return [NSString stringWithFormat:@"%.1fºC", temp];
}



@end
