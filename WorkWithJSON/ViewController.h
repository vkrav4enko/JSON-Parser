//
//  ViewController.h
//  WorkWithJSON
//
//  Created by Владимир on 08.07.13.
//  Copyright (c) 2013 Владимир. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>


@interface ViewController : UIViewController <CLLocationManagerDelegate,UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (weak, nonatomic) IBOutlet UITextView *textField;

@end
