//
//  CustomSegue.m
//  WorkWithJSON
//
//  Created by Владимир on 19.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import "CustomSegue.h"
#import "AppDelegate.h"
#import "UIViewController+MMDrawerController.h"

@interface CustomSegue ()
@property (nonatomic, strong) MMDrawerController *drawerController;
@end

@implementation CustomSegue

- (void)perform
{
    AppDelegate *appDelegat = (AppDelegate *) [UIApplication sharedApplication].delegate;
    UINavigationController * navigationController = [[UINavigationController alloc] initWithRootViewController:[self destinationViewController]];
    _drawerController = appDelegat.drawerController;
    [_drawerController setCenterViewController:navigationController withCloseAnimation:YES completion:nil];    
    
}

@end
