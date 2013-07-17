//
//  WeatherInfo.m
//  WorkWithJSON
//
//  Created by Владимир on 15.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "WeatherInfo.h"


@implementation WeatherInfo

@dynamic timeStamp, primitiveTimeStamp;
@dynamic temperature;
@dynamic clouds;
@dynamic wind;
@dynamic pressure;
@dynamic city;
@dynamic humidity;
@dynamic sectionIdentifier, primitiveSectionIdentifier;

#pragma mark -
#pragma mark Transient properties

- (NSString *)sectionIdentifier {
    
    // Create and cache the section identifier on demand.
    
    [self willAccessValueForKey:@"sectionIdentifier"];
    NSString *tmp = [self primitiveSectionIdentifier];
    [self didAccessValueForKey:@"sectionIdentifier"];
    
    if (!tmp) {
        /*
         Sections are organized by month and year. Create the section identifier as a string representing the number (year * 1000) + month; this way they will be correctly ordered chronologically regardless of the actual name of the month.
         */
        NSCalendar *calendar = [NSCalendar currentCalendar];
        
        NSDateComponents *components = [calendar components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) fromDate:[self timeStamp]];
        tmp = [NSString stringWithFormat:@"%d", ([components year] * 10000) + ([components month]*100) + [components day]];
        [self setPrimitiveSectionIdentifier:tmp];
    }
    return tmp;
}

#pragma mark -
#pragma mark Time stamp setter

- (void)setTimeStamp:(NSDate *)newDate {
    
    // If the time stamp changes, the section identifier become invalid.
    [self willChangeValueForKey:@"timeStamp"];
    [self setPrimitiveTimeStamp:newDate];
    [self didChangeValueForKey:@"timeStamp"];
    
    [self setPrimitiveSectionIdentifier:nil];
}

#pragma mark -
#pragma mark Key path dependencies

+ (NSSet *)keyPathsForValuesAffectingSectionIdentifier {
    // If the value of timeStamp changes, the section identifier may change as well.
    return [NSSet setWithObject:@"timeStamp"];
}


@end
