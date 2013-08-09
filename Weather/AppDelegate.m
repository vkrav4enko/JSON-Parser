//
//  AppDelegate.m
//  WorkWithJSON
//
//  Created by Владимир on 08.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "AppDelegate.h"
#import "Weather.h"
#import "WeatherInfo.h"



@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSError *error = nil;
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:nil];
    RKManagedObjectStore *managedObjectStore = [[RKManagedObjectStore alloc] initWithManagedObjectModel:managedObjectModel];
    
    NSString *path = [RKApplicationDataDirectory() stringByAppendingPathComponent:@"Weather.sqlite"];
    NSPersistentStore *persistentStore = [managedObjectStore addSQLitePersistentStoreAtPath:path fromSeedDatabaseAtPath:nil withConfiguration:nil options:nil error:&error];
    if (! persistentStore) {
        RKLogError(@"Failed adding persistent store at path '%@': %@", path, error);
    }
    [managedObjectStore createManagedObjectContexts];
    [RKManagedObjectStore setDefaultStore:managedObjectStore];
    _managedObjectContext = [[RKManagedObjectStore defaultStore] mainQueueManagedObjectContext];
    
    [self configureObjectManager];
    
    //Menu controller
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController * leftSideDrawerViewController = [storyboard instantiateViewControllerWithIdentifier:@"Menu"];
    _drawerController = [[MMDrawerController alloc]
                                             initWithCenterViewController:[storyboard instantiateInitialViewController]
                                             leftDrawerViewController:leftSideDrawerViewController];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self.window setRootViewController:_drawerController];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void) configureObjectManager
{
    NSURL *baseURL = [NSURL URLWithString:@"http://api.openweathermap.org"];
    RKObjectManager *objectManager = [RKObjectManager managerWithBaseURL:baseURL];
    objectManager.managedObjectStore = [RKManagedObjectStore defaultStore];
    
    //Forecast mapping
    RKObjectMapping *forecastMapping = [RKObjectMapping mappingForClass:[Weather class]];
    [forecastMapping addAttributeMappingsFromDictionary:
     @{@"dt": @"timeStamp",
     @"weather": @"weatherInfo",
     @"main.temp": @"temperature",
     }];
    RKResponseDescriptor *forecastResponceDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:forecastMapping method:RKRequestMethodGET pathPattern:@"/data/2.5/forecast" keyPath:@"list" statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [[RKObjectManager sharedManager] addResponseDescriptor:forecastResponceDescriptor];
    RKRoute *route = [RKRoute routeWithName:@"forecasts" pathPattern:@"/data/2.5/forecast" method:RKRequestMethodGET];
    [[[RKObjectManager sharedManager].router routeSet] addRoute:route];
    
    
    //Current Weather mapping
    RKObjectMapping *weatherMapping = [RKObjectMapping mappingForClass:[Weather class]];
    [weatherMapping addAttributeMappingsFromDictionary:
     @{@"dt": @"timeStamp",
     @"main.temp": @"temperature",
     @"weather": @"weatherInfo",
     @"name": @"city"
     }];
    RKResponseDescriptor *weatherResponseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:weatherMapping method:RKRequestMethodGET pathPattern:@"/data/2.5/weather" keyPath:nil statusCodes:RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful)];
    [[RKObjectManager sharedManager] addResponseDescriptor:weatherResponseDescriptor];

}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveContext];
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end


@implementation MMDrawerController (rotate)
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown;
}
@end



