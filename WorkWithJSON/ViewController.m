//
//  ViewController.m
//  WorkWithJSON
//
//  Created by Владимир on 08.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "ViewController.h"
#import "ParseJSON.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test.js" ofType:nil];
    ParseJSON *parser = [[ParseJSON alloc] initWithString:[NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil]];
    
    //ParseJSON *parser = [[ParseJSON alloc] initWithString: @"{\"id\": 100, \"name\": \"Item #100\",\"date_created\": \"01-02-2010 00:00:12\"}"];
    id obj = [parser parse];
    NSLog(@"%@", obj);
    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
