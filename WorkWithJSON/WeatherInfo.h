//
//  WeatherInfo.h
//  WorkWithJSON
//
//  Created by Владимир on 15.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface WeatherInfo : NSManagedObject

@property (nonatomic, retain) NSDate * timeStamp;
@property (nonatomic, retain) NSString * temperature;
@property (nonatomic, retain) NSString * clouds;
@property (nonatomic, retain) NSString * wind;
@property (nonatomic, retain) NSString * pressure;
@property (nonatomic, retain) NSString * city;
@property (nonatomic, retain) NSString * humidity;

@end
