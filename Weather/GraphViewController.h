//
//  GraphViewController.h
//  WorkWithJSON
//
//  Created by Владимир on 16.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "WeatherInfo.h"

@interface GraphViewController : UIViewController <CPTScatterPlotDataSource, CPTScatterPlotDelegate, CPTPlotDataSource, CPTPlotDelegate, CPTPlotSpaceDelegate>

@property (weak, nonatomic) IBOutlet CPTGraphHostingView *hostView;

@property (nonatomic, strong) WeatherInfo *weatherInfo;
@property(nonatomic,strong) CPTXYGraph *graph;
@property(nonatomic,strong) NSArray *plotData;
@property (nonatomic, strong) CPTPlotSpaceAnnotation *weatherAnnotation;

@end
