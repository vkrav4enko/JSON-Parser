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
    [dateFormatter setDateFormat:@"yyyyMMdd"];
    NSDate *today = [NSDate date];
        

    NSTimeInterval oneDay = 24 * 60 * 60;
    
    
    
    // Create graph from theme
    graph = [(CPTXYGraph *)[CPTXYGraph alloc] initWithFrame : CGRectZero];
    CPTTheme *theme = [CPTTheme themeNamed:kCPTDarkGradientTheme];
    [graph applyTheme:theme];
    _hostView.hostedGraph = graph;
    
    // Setup scatter plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    
    CGFloat xMin = - oneDay * 20 + 10;
    CGFloat xMax = oneDay * 30;
    CGFloat yMin = -10.0f;
    CGFloat yMax = 48.0f;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(xMin) length:CPTDecimalFromFloat(xMax)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(yMin) length:CPTDecimalFromFloat(yMax)];
    
    plotSpace.allowsUserInteraction = YES;
    
    CPTPlotRange *globalYRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(yMin) length:CPTDecimalFromDouble(yMax)];
    
    plotSpace.globalYRange = globalYRange;
    
   
    
    // Axes
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
       
    CPTXYAxis *x = axisSet.xAxis;
    CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor grayColor];
    tickLineStyle.lineWidth = 1.0f;

    x.majorIntervalLength         = CPTDecimalFromFloat(oneDay*30);
    x.orthogonalCoordinateDecimal = CPTDecimalFromString(@"2");
    x.labelAlignment = CPTAlignmentCenter;
    x.labelOffset = 9;
    
    x.majorTickLineStyle = tickLineStyle;
    x.majorTickLength = 5.0f;
    
    x.minorTickLength = 5.0f;
    x.minorTickLabelOffset = 0;
    


    
    //Date formatter set
    NSDateFormatter *majorDateFormatter = [[NSDateFormatter alloc] init];
    NSDateFormatter *minorDateFormatter = [[NSDateFormatter alloc] init];
    [majorDateFormatter setDateFormat: @"MMMM"];
    [minorDateFormatter setDateFormat: @"d"];
    x.minorTicksPerInterval = 30; // every day
    CPTTimeFormatter  *majorTimeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:majorDateFormatter];
    CPTTimeFormatter  *minorTimeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:minorDateFormatter];
    
    majorTimeFormatter.referenceDate = today;
    minorTimeFormatter.referenceDate = today;
    
    x.labelFormatter = majorTimeFormatter;
    x.minorTickLabelFormatter = minorTimeFormatter;


    
    CPTXYAxis *y = axisSet.yAxis;
    y.majorIntervalLength         = CPTDecimalFromString(@"10");
    y.minorTicksPerInterval       = 5;
    y.orthogonalCoordinateDecimal = CPTDecimalFromFloat(oneDay);
    axisSet.yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:50.0];
    
    
    // Create a plot that uses the data source method
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    dataSourceLinePlot.delegate = self;
    dataSourceLinePlot.identifier = @"Date Plot";
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.size = CGSizeMake(10.0f, 10.0f);
    plotSymbol.fill = [CPTFill fillWithColor:[CPTColor greenColor]];
    dataSourceLinePlot.plotSymbol = plotSymbol;
    
    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = 3.f;
    lineStyle.lineColor              = [CPTColor greenColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;
    
    dataSourceLinePlot.dataSource = self;
    [graph addPlot:dataSourceLinePlot];
    
    // Add some data
    NSMutableArray *newData = [NSMutableArray array];
    NSUInteger dayInHistory;
    
    for ( dayInHistory = 0; dayInHistory < 10; dayInHistory++ ) {
        NSDateFormatter *dateFormatter2 = [NSDateFormatter new];
        [dateFormatter2 setDateFormat:@"yyyyMMdd"];
        
        NSTimeInterval x = - oneDay * dayInHistory;
        
        NSDate *currentDate = [NSDate dateWithTimeInterval:x sinceDate:[NSDate date]];
        NSString *currentDateString = [dateFormatter2 stringFromDate:currentDate];
        
        NSString *filter = [NSString stringWithFormat:@"sectionIdentifier == %i and city like \"San Francisco\"", [currentDateString integerValue]];
        _arrayWithEntities = [WeatherInfo findAllSortedBy:@"timeStamp" ascending:YES withPredicate:[NSPredicate predicateWithFormat:filter] inContext:context];
        //NSLog (@"%@",_arrayWithEntities);
        
      
        
       
        
        
        
      
        [newData addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [NSDecimalNumber numberWithFloat:x], [NSNumber numberWithInt:CPTScatterPlotFieldX],
          _arrayWithEntities, [NSNumber numberWithInt:CPTScatterPlotFieldY],
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
    NSNumber *num = [NSNumber new];
    
    if (fieldEnum == CPTScatterPlotFieldX)
    {
        num = [[_plotData objectAtIndex:index] objectForKey:[NSNumber numberWithInt:fieldEnum]];        
    }
    else
    {
        NSArray *array = [[_plotData objectAtIndex:index] objectForKey:[NSNumber numberWithInt:fieldEnum]];
        float averageValue = 0;
        if (array.count)
        {
            for (int i = 0; i < array.count; i++)
            {
                _weatherInfo = [array objectAtIndex:i];
                averageValue += [_weatherInfo.temperature floatValue];
            }
            averageValue /= array.count;
            NSLog(@"%f", averageValue);
            num = [NSNumber numberWithFloat:averageValue];
        }
        
        
    }
    return num;
}


-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait)
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)scatterPlot:(CPTScatterPlot *)plot plotSymbolWasSelectedAtRecordIndex:(NSUInteger)idx
{
    //1 - Prepare data
    NSArray *array = [[_plotData objectAtIndex:idx] objectForKey:[NSNumber numberWithInt:CPTScatterPlotFieldY]];
    _weatherInfo = [array objectAtIndex:0];
    float temperature = [[self numberForPlot:plot field:CPTScatterPlotFieldY recordIndex:idx] floatValue];
    
    
    // 2 - Create style, if necessary
    static CPTMutableTextStyle *style = nil;
    if (!style) {
        style = [CPTMutableTextStyle textStyle];
        style.color= [CPTColor yellowColor];
        style.fontSize = 12.0f;
        style.fontName = @"Helvetica-Bold";
    }
    
    // 3 - Create annotation, if necessary
    if (!self.weatherAnnotation) {
        NSNumber *x = [NSNumber numberWithInt:0];
        NSNumber *y = [NSNumber numberWithInt:0];
        NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];
        self.weatherAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plot.plotSpace anchorPlotPoint:anchorPoint];
    }
    
    
    // 5 - Create text layer for annotation
    NSString *weatherInfo = [NSString stringWithFormat:@"Temperature = %.0fºC\n%@\n%@\n%@\n%@", temperature, _weatherInfo.pressure, _weatherInfo.clouds, _weatherInfo.wind, _weatherInfo.humidity];
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:weatherInfo style:style];
    self.weatherAnnotation.contentLayer = textLayer;
    // 6 - Get plot index based on identifier
    
    // 7 - Get the anchor point for annotation
    CGFloat x = 0 ;
    NSNumber *anchorX = [NSNumber numberWithFloat:x];
    CGFloat y = temperature + 5;
    NSNumber *anchorY = [NSNumber numberWithFloat:y];
    self.weatherAnnotation.anchorPlotPoint = [NSArray arrayWithObjects:anchorX, anchorY, nil];
    // 8 - Add the annotation
    [plot.graph.plotAreaFrame.plotArea addAnnotation:self.weatherAnnotation];
    
}




- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





@end
