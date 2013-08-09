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
    
    RKEntityMapping *entityMapping = [RKEntityMapping mappingForEntityForName:@"WeatherInfo" inManagedObjectStore:[RKManagedObjectStore defaultStore]];
    [entityMapping addAttributeMappingsFromDictionary:@{
     @"name":          @"city",
     @"clouds.all":    @"clouds",
     @"wind.speed":    @"wind",
     @"main.humidity": @"humidity",
     @"main.temp":     @"temperature",
     @"main.pressure": @"pressure",
     @"dt":            @"timeStamp"}];
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:entityMapping method:RKRequestMethodGET pathPattern:@"/data/2.5/weather" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    NSString *stringURL = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f", _lat , _lon];
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString: stringURL]];
    RKManagedObjectRequestOperation *managedObjectRequestOperation = [[RKManagedObjectRequestOperation alloc] initWithRequest:request responseDescriptors:@[ responseDescriptor ]];
    managedObjectRequestOperation.managedObjectContext = [[RKManagedObjectStore defaultStore] mainQueueManagedObjectContext];
    [[NSOperationQueue currentQueue] addOperation:managedObjectRequestOperation];
    
//    [[RKObjectManager sharedManager] addResponseDescriptor:responseDescriptor];
//    RKRoute *coreDataRoute = [RKRoute routeWithName:@"coreData" pathPattern:@"/data/2.5/weather" method:RKRequestMethodGET];
//    [[[RKObjectManager sharedManager].router routeSet] addRoute:coreDataRoute];
//    
//    [[RKObjectManager sharedManager] getObjectsAtPathForRouteNamed:@"coreData"
//                                                            object:nil
//                                                        parameters:@{@"lat": @(_lat), @"lon": @(_lon)}
//                                                           success:nil
//                                                           failure:nil];    
    
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
    
    [[RKObjectManager sharedManager] getObject:[Weather new]
                                          path:@"/data/2.5/weather"
                                    parameters:@{@"lat": @(_lat), @"lon": @(_lon) }
                                       success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult)
    {
        if (mappingResult.array.count)
        {
            Weather *weather = mappingResult.array [0];
            self.cityName.text = weather.city;
            self.navigationItem.prompt = _cityName.text;
            
            self.currentTemp.text = [self stringTemperature:weather.temperature];
            
            self.currentTimestamp.text =  [_dateFormatter stringFromDate:weather.timeStamp];
            
            self.weather.text = [[weather.weatherInfo objectAtIndex:0] objectForKey:@"description"];
        }        
        
    }
                                       failure:^(RKObjectRequestOperation *operation, NSError *error)
    {
        RKLogError(@"Operation failed with error: %@", error);
    }];


    [[RKObjectManager sharedManager] getObjectsAtPathForRouteNamed:@"forecasts"
                                                            object:nil
                                                        parameters:@{@"lat": @(_lat), @"lon": @(_lon) } success:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult)
    {
        _forecast = [NSArray arrayWithArray:mappingResult.array];
        [self.forecastTableView reloadData];
        [_locationManager stopUpdatingLocation];
    }
                                                           failure:^(RKObjectRequestOperation *operation, NSError *error)
    {
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
    cell.textLabel.text = [[self stringTemperature:weather.temperature] stringByAppendingFormat:@" - %@", [[weather.weatherInfo objectAtIndex:0] objectForKey:@"main"]];
    
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
