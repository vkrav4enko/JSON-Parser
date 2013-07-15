//
//  WeatherInfoViewController.h
//  WorkWithJSON
//
//  Created by Владимир on 15.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WeatherInfoViewController : UITableViewController
@property (nonatomic,strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, retain) NSFetchedResultsController *fetchedResultsController;
@end
