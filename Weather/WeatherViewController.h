//
//  WeatherViewController.h
//  WorkWithJSON
//
//  Created by Владимир on 19.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface WeatherViewController : UIViewController <CLLocationManagerDelegate, UITableViewDataSource>
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (weak, nonatomic) IBOutlet UITextView *cityName;
@property (weak, nonatomic) IBOutlet UILabel *currentTemp;
@property (weak, nonatomic) IBOutlet UITableView *forecastTableView;
@property (weak, nonatomic) IBOutlet UILabel *currentTimestamp;
@property (weak, nonatomic) IBOutlet UITextView *weather;


@end
