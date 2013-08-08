//
//  Weather.h
//  Weather
//
//  Created by Владимир on 08.08.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Weather : NSObject
@property (nonatomic, copy) NSString *city;
@property (nonatomic, strong) NSNumber *temperature;
@property (nonatomic, copy) NSString *weatherDescription;
@property (nonatomic, strong) NSDate *timeStamp;
@property (nonatomic, strong) NSArray *weatherInfo;
@end
