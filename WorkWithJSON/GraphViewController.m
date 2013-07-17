//
//  GraphViewController.m
//  WorkWithJSON
//
//  Created by Владимир on 16.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "GraphViewController.h"
#import "AppDelegate.h"
#import "WeatherInfo.h"
#import "NSManagedObject+ActiveRecord.h"
#import "WeatherInfoViewController.h"

@interface GraphViewController ()
@property (nonatomic, strong) CPTBarPlot *tempPlot;
@property (nonatomic, strong) NSArray *arrayWithEntities;
@property (nonatomic, strong) CPTPlotSpaceAnnotation *priceAnnotation;
-(void)configureHost;
-(void)initPlot;
-(void)configureGraph;
-(void)configurePlots;
-(void)configureAxes;

@end

@implementation GraphViewController
@synthesize graph;
CGFloat const CPDBarWidth2 = 0.75f;
CGFloat const CPDBarInitialX2 = 0.5f;

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
    
  
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    WeatherInfoViewController *masterController = [self.navigationController.viewControllers objectAtIndex:0];
    _weatherInfo = masterController.weatherInfo;
    NSManagedObjectContext *context = appDelegate.managedObjectContext;
   
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"dd MMM"];
    NSDate *refDate       = [NSDate date];
    CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
    timeFormatter.referenceDate = refDate;
    NSTimeInterval oneDay = 24 * 60 * 60;
    
    
    
    // Create graph from theme
    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame : CGRectZero];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
    [graph applyTheme:theme];
    _hostView.hostedGraph = graph;
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    
    CGFloat xMin = - oneDay * 20 + 10;
    CGFloat xMax = oneDay * 20;
    CGFloat yMin = -5.0f;
    CGFloat yMax = 48.0f;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(xMin) length:CPTDecimalFromFloat(xMax)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(yMin) length:CPTDecimalFromFloat(yMax)];
    
    plotSpace.allowsUserInteraction = YES;
    
    CPTPlotRange *globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(yMin) length:CPTDecimalFromDouble(yMax)];
    
    plotSpace.globalYRange = globalYRange;
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
       
    CPTXYAxis *x          = axisSet.xAxis;
    x.majorIntervalLength         = CPTDecimalFromFloat(oneDay*2);
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    x.minorTicksPerInterval       = 0;
    
    
    x.labelFormatter            = timeFormatter;
    
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength         = CPTDecimalFromString(@"10");
    y.minorTicksPerInterval       = 5;
    y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(oneDay);
    axisSet.yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:50.0];
    
    
    // Create a plot that uses the data source method
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    dataSourceLinePlot.identifier = @"Date Plot";
    
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = 3.f;
    lineStyle.lineColor              = [CPTColor greenColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    
    dataSourceLinePlot.dataSource = self;
    [graph addPlot:dataSourceLinePlot];
    
    // Add some data
    NSMutableArray *newData = [NSMutableArray array];
    NSUInteger dayInHistory;
    float temp = 0;
    for ( dayInHistory = 0; dayInHistory < 10; dayInHistory++ ) {
        NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
        [dateFormatter2 setDateFormat:@"yyyyMMdd"];
        
        NSTimeInterval x = - oneDay * dayInHistory;
        
        NSDate *currentDate = [NSDate dateWithTimeInterval:x sinceDate:[NSDate date]];
        NSString *currentDateString = [dateFormatter2 stringFromDate:currentDate];
        
        NSString *filter = [NSString stringWithFormat:@"sectionIdentifier == %i", [currentDateString integerValue]];
        _arrayWithEntities = [WeatherInfo findAllSortedBy:@"timeStamp" ascending:YES withPredicate:[NSPredicate predicateWithFormat:filter] inContext:context];
        //NSLog (@"%@",_arrayWithEntities);
        
        id y;
    
        float averageValue = 0;
        if (_arrayWithEntities.count)
        {
            for (int i = 0; i < _arrayWithEntities.count; i++)
            {
                _weatherInfo = [_arrayWithEntities objectAtIndex:i];
                averageValue += [_weatherInfo.temperature floatValue];
            }
            averageValue /= _arrayWithEntities.count;
            NSLog(@"%f", averageValue);
            y = [NSDecimalNumber numberWithFloat:averageValue];
            temp = averageValue;
        }
        else
            y = [NSDecimalNumber numberWithFloat:temp];
       
        
        
        
        //id y             = [NSDecimalNumber numberWithFloat:1.2 * rand() / (float)RAND_MAX + 1.2];
        [newData addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSDecimalNumber numberWithFloat:x], [NSNumber numberWithInt:CPTScatterPlotFieldX],
          y, [NSNumber numberWithInt:CPTScatterPlotFieldY],
          nil]];
    }
    _plotData = newData;
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return _plotData.count;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSDecimalNumber *num = [[_plotData objectAtIndex:index] objectForKey:[NSNumber numberWithInt:fieldEnum]];
    
    return num;
}


-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait)
        [self.navigationController popViewControllerAnimated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





@end
