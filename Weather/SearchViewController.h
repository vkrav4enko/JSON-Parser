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


@interface SearchViewController : UIViewController <CLLocationManagerDelegate,UITextFieldDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (nonatomic, strong) CLLocationManager* locationManager;
@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic, strong) id parsedDictionary;

@end
