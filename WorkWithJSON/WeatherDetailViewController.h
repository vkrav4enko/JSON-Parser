//
//  WeatherDetailViewController.h
//  WorkWithJSON
//
//  Created by Владимир on 15.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WeatherInfo.h"

@interface WeatherDetailViewController : UIViewController
@property (nonatomic, strong) WeatherInfo *weatherInfo;

@property (weak, nonatomic) IBOutlet UILabel *city;
@property (weak, nonatomic) IBOutlet UILabel *temp;
@property (weak, nonatomic) IBOutlet UILabel *humidity;
@property (weak, nonatomic) IBOutlet UILabel *wind;
@property (weak, nonatomic) IBOutlet UILabel *presure;
@property (weak, nonatomic) IBOutlet UILabel *cloud;

@end
