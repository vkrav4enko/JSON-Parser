//
//  WeatherDetailViewController.m
//  WorkWithJSON
//
//  Created by Владимир on 15.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "WeatherDetailViewController.h"
#import "AppDelegate.h"
#import "WeatherInfo.h"
#import "NSManagedObject+ActiveRecord.h"
#import "WeatherInfoViewController.h"

@interface WeatherDetailViewController ()
@property (nonatomic, strong) CPTBarPlot *tempPlot;
@property (nonatomic, strong) NSArray *arrayWithEntities;
@property (nonatomic, strong) CPTPlotSpaceAnnotation *priceAnnotation;

-(void)initPlot;
-(void)configureGraph;
-(void)configurePlots;
-(void)configureAxes;



@end

@implementation WeatherDetailViewController
CGFloat const CPDBarWidth = 0.75f;
CGFloat const CPDBarInitialX = 0.5f;




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
	// Do any additional setup after loading the view.
    
    
    
    
}

- (void)viewDidAppear:(BOOL)animated
{
    AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
    WeatherInfoViewController *masterController = [self.navigationController.viewControllers objectAtIndex:0];
    _weatherInfo = masterController.weatherInfo;
    NSManagedObjectContext *context = appDelegate.managedObjectContext;
    NSString *filter = [NSString stringWithFormat:@"city like \"%@\"", _weatherInfo.city];
    _arrayWithEntities = [WeatherInfo findAllSortedBy:@"timeStamp" ascending:YES withPredicate:[NSPredicate predicateWithFormat:filter] inContext:context];
    NSLog (@"%@",_arrayWithEntities);
    [self initPlot];
    
}

#pragma mark - Chart behavior
-(void)initPlot {
    self.hostView.allowPinchScaling = NO;
    [self configureGraph];
    [self configurePlots];
    [self configureAxes];
}

-(void)configureGraph {
    
    // 1 - Create the graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    graph.plotAreaFrame.masksToBorder = NO;
    self.hostView.hostedGraph = graph;
    // 2 - Configure the graph
    [graph applyTheme:[CPTTheme themeNamed:kCPTPlainBlackTheme]];
    graph.paddingBottom = 20.0f;
    graph.paddingLeft  = 30.0f;
    graph.paddingTop    = 5.0f;
    graph.paddingRight  = 10.0f;
    // 3 - Set up styles
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor whiteColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 16.0f;
    // 4 - Set up title
    NSString *title = @"Temperature graph";
    graph.title = title;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, -16.0f);
    // 5 - Set up plot space
    CGFloat xMin = 0.0f;
    CGFloat xMax = _arrayWithEntities.count;
    CGFloat yMin = 0.0f;
    CGFloat yMax = 40.0f;  // should determine dynamically based on max price
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(xMin) length:CPTDecimalFromFloat(xMax)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(yMin) length:CPTDecimalFromFloat(yMax)];
 
    
    
}

-(void)configurePlots {
    
    self.tempPlot = [CPTBarPlot tubularBarPlotWithColor:[CPTColor greenColor] horizontalBars:NO];
    CPTMutableLineStyle *barLineStyle = [[CPTMutableLineStyle alloc] init];
    barLineStyle.lineColor = [CPTColor lightGrayColor];
    barLineStyle.lineWidth = 0.5;
    CPTGraph *graph = self.hostView.hostedGraph;
    CGFloat barX = CPDBarInitialX;
    _tempPlot.dataSource = self;
    _tempPlot.delegate = self;
    _tempPlot.barWidth = CPTDecimalFromDouble(CPDBarWidth);
    _tempPlot.barOffset = CPTDecimalFromDouble(barX);
    _tempPlot.lineStyle = barLineStyle;
    [graph addPlot:_tempPlot toPlotSpace:graph.defaultPlotSpace];
    
}

-(void)configureAxes {
    
    // 1 - Configure styles
    CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
    axisTitleStyle.color = [CPTColor whiteColor];
    axisTitleStyle.fontName = @"Helvetica-Bold";
    axisTitleStyle.fontSize = 12.0f;
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 2.0f;
    axisLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:1];
    // 2 - Get the graph's axis set
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    // 3 - Configure the x-axis
    axisSet.xAxis.labelingPolicy = CPTAxisLabelingPolicyNone;    
    axisSet.xAxis.title = @"Time";
    axisSet.xAxis.titleTextStyle = axisTitleStyle;
    axisSet.xAxis.titleOffset = 3.0f;
    axisSet.xAxis.axisLineStyle = axisLineStyle;
    // 4 - Configure the y-axis
    axisSet.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    axisSet.yAxis.labelOffset = 1.0f;
    axisSet.yAxis.labelTextStyle = axisTitleStyle;
    
    axisSet.yAxis.axisLineStyle = axisLineStyle;
}


#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    NSUInteger number = _arrayWithEntities.count;
    
    return number;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    
    if ((fieldEnum == CPTBarPlotFieldBarTip) && (index < _arrayWithEntities.count)) {
        
        WeatherInfo *weather = [_arrayWithEntities objectAtIndex:index];
        NSNumber *number = [NSNumber numberWithFloat: [weather.temperature floatValue]];
        
        return number;
    }
    
    return [NSDecimalNumber numberWithUnsignedInteger:index];
}

#pragma mark - CPTBarPlotDelegate methods
-(void)barPlot:(CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)index {
    
    // 2 - Create style, if necessary
    static CPTMutableTextStyle *style = nil;
    if (!style) {
        style = [CPTMutableTextStyle textStyle];
        style.color= [CPTColor yellowColor];
        style.fontSize = 12.0f;
        style.fontName = @"Helvetica-Bold";
    }
    // 3 - Create annotation, if necessary
    NSNumber *price = [self numberForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    if (!self.priceAnnotation) {
        NSNumber *x = [NSNumber numberWithInt:0];
        NSNumber *y = [NSNumber numberWithInt:0];
        NSArray *anchorPoint = [NSArray arrayWithObjects:x, y, nil];
        self.priceAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:plot.plotSpace anchorPlotPoint:anchorPoint];
    }
    // 4 - Create number formatter, if needed
    static NSNumberFormatter *formatter = nil;
    if (!formatter) {
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setMaximumFractionDigits:2];
    }
    // 5 - Create text layer for annotation
    NSString *priceValue = [formatter stringFromNumber:price];
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:priceValue style:style];
    self.priceAnnotation.contentLayer = textLayer;
    // 6 - Get plot index based on identifier
    
        // 7 - Get the anchor point for annotation
    CGFloat x = index + CPDBarInitialX ;
    NSNumber *anchorX = [NSNumber numberWithFloat:x];
    CGFloat y = [price floatValue] + 3.0f;
    NSNumber *anchorY = [NSNumber numberWithFloat:y];
    self.priceAnnotation.anchorPlotPoint = [NSArray arrayWithObjects:anchorX, anchorY, nil];
    // 8 - Add the annotation 
    [plot.graph.plotAreaFrame.plotArea addAnnotation:self.priceAnnotation];
    
}

@end
