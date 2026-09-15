//
//  infoTabBarController.h
//  AngelDemo
//
//  Created by Ugur Kirbac on 2/25/14.
//  Copyright (c) 2014 Ugur Kirbac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "BLEDevice.h"
#import "BLEUtility.h"
#import "Sensors.h"
#import "infoViewController.h"
@interface infoTabBarController : UITabBarController<CBCentralManagerDelegate,CBPeripheralDelegate>

@property (strong,nonatomic) infoViewController *infoView;

@property (strong,nonatomic) BLEDevice *m_bleDevice;
@property NSMutableArray *sensorsEnabled;
@property (strong,nonatomic) sensorIMU3000 *gyroSensor;
- (void)initBLE:(BLEDevice*) bleDevice;

/// Simulated readings instead of a SensorTag, for the Simulator or a demo without hardware.
@property (nonatomic) BOOL demoMode;
- (void)initDemo;

@property (strong,nonatomic) sensorTagValues *currentVal;
@property (strong,nonatomic) NSMutableArray *vals;
@property (strong,nonatomic) NSTimer *logTimer;

@property float logInterval;

-(void) configureSensorTag;
-(void) deconfigureSensorTag;

- (IBAction) handleCalibrateGyro;

-(void) logValues:(NSTimer *)timer;

@end
