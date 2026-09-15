//
//  infoTabBarController.m
//  AngelDemo
//
//  Created by Ugur Kirbac on 2/25/14.
//  Copyright (c) 2014 Ugur Kirbac. All rights reserved.
//

#import "infoTabBarController.h"
#import "infoViewController.h"
@interface infoTabBarController ()

@property (strong, nonatomic) NSTimer *demoTimer;
@property (nonatomic) NSUInteger demoTick;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation infoTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.sensorsEnabled = [[NSMutableArray alloc] init];
    if (self.demoMode) {
        self.title = @"Demo mode";
        [self startDemo];
        return;
    }
    if (self.m_bleDevice.p.state != CBPeripheralStateConnected) {
        self.m_bleDevice.manager.delegate = self;
        [self.m_bleDevice.manager connectPeripheral:self.m_bleDevice.p options:nil];
    }
    else {
        self.m_bleDevice.p.delegate = self;
        [self configureSensorTag];
        self.title = @"TI BLE Sensor Tag application";
    }
}


-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.demoMode) {
        [self stopDemo];
    }
    else {
        [self deconfigureSensorTag];
    }
}

-(void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    self.sensorsEnabled = nil;
    self.m_bleDevice.manager.delegate = nil;
    // A repeating timer retains its target, so a running one would keep this screen alive.
    [self.logTimer invalidate];
    self.logTimer = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.

    self.infoView = (infoViewController *)[[self viewControllers] objectAtIndex:1];

    // The map tab shows the user's position, which needs permission since iOS 8.
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager requestWhenInUseAuthorization];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initBLE:(BLEDevice*) bleDevice{

    self.m_bleDevice = bleDevice;

    self.currentVal = [[sensorTagValues alloc]init];
    self.vals = [[NSMutableArray alloc]init];
    // Without an instance every gyroscope reading came back as zero.
    self.gyroSensor = [[sensorIMU3000 alloc] init];

    self.logInterval = 1.0; //1000 ms

    self.logTimer = [NSTimer scheduledTimerWithTimeInterval:self.logInterval target:self selector:@selector(logValues:) userInfo:nil repeats:YES];

    NSLog(@"INITBLE GIRDI");
}

- (void)initDemo {
    self.demoMode = YES;
    self.currentVal = [[sensorTagValues alloc] init];
    self.vals = [[NSMutableArray alloc] init];
}



#pragma mark - Demo mode

// Stands in for a SensorTag when there is none, for example in the iOS Simulator, which has
// no Bluetooth. It feeds the Info screen the same values the sensor callbacks below do.
- (void)startDemo {
    self.demoTick = 0;
    [self.demoTimer invalidate];
    self.demoTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(demoStep:) userInfo:nil repeats:YES];
    [self demoStep:self.demoTimer];
}

- (void)stopDemo {
    [self.demoTimer invalidate];
    self.demoTimer = nil;
}

- (void)demoStep:(NSTimer *)timer {
    self.demoTick++;
    double t = self.demoTick;

    float tAmb = 22.5 + 1.5 * sin(t / 20.0) + arc4random_uniform(40) / 100.0;
    float humidity = 45.0 + 5.0 * sin(t / 30.0) + arc4random_uniform(100) / 100.0;
    self.currentVal.tAmb = tAmb;
    self.currentVal.humidity = humidity;
    [self.infoView setTemp:[NSString stringWithFormat:@"%.1f°C", tAmb]];
    [self.infoView setHumidity:[NSString stringWithFormat:@"%0.1f%%rH", humidity]];

    // Signal strength drifts away and back, passing through the -80 to -90 dBm band
    // that raises the forget alert.
    int rssi = (int)(-72.0 - 16.0 * sin(t / 8.0)) + (int)arc4random_uniform(4);
    [self.infoView setRSSIValue:@(rssi)];

    // Every 15 seconds the tag is "picked up".
    if (self.demoTick % 15 == 0) {
        [self.infoView sendWarningonMotion];
    }
}



// Sensor Tag code sample


-(void) configureSensorTag {
    // Configure sensortag, turning on Sensors and setting update period for sensors etc ...



    if (([self sensorEnabled:@"Ambient temperature active"]) || ([self sensorEnabled:@"IR temperature active"])) {
        // Enable Temperature sensor
        CBUUID *sUUID = [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"IR temperature service UUID"]];
        CBUUID *cUUID = [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"IR temperature config UUID"]];
        uint8_t data = 0x01;
        [BLEUtility writeCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID = [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"IR temperature data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID enable:YES];

        if ([self sensorEnabled:@"Ambient temperature active"]) [self.sensorsEnabled addObject:@"Ambient temperature"];
        if ([self sensorEnabled:@"IR temperature active"]) [self.sensorsEnabled addObject:@"IR temperature"];

    }

    if ([self sensorEnabled:@"Accelerometer active"]) {
        CBUUID *sUUID = [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Accelerometer service UUID"]];
        CBUUID *cUUID = [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Accelerometer config UUID"]];
        CBUUID *pUUID = [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Accelerometer period UUID"]];
        NSInteger period = [[self.m_bleDevice.setupData valueForKey:@"Accelerometer period"] integerValue];
        uint8_t periodData = (uint8_t)(period / 10);
        NSLog(@"%d",periodData);
        [BLEUtility writeCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:pUUID data:[NSData dataWithBytes:&periodData length:1]];
        uint8_t data = 0x01;
        [BLEUtility writeCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID = [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Accelerometer data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID enable:YES];
        [self.sensorsEnabled addObject:@"Accelerometer"];
    }


    if ([self sensorEnabled:@"Humidity active"]) {
        CBUUID *sUUID = [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Humidity service UUID"]];
        CBUUID *cUUID = [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Humidity config UUID"]];
        uint8_t data = 0x01;
        [BLEUtility writeCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID = [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Humidity data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID enable:YES];
        [self.sensorsEnabled addObject:@"Humidity"];
    }

       if ([self sensorEnabled:@"Gyroscope active"]) {
        CBUUID *sUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Gyroscope service UUID"]];
        CBUUID *cUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Gyroscope config UUID"]];
        uint8_t data = 0x07;
        [BLEUtility writeCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Gyroscope data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID enable:YES];
        [self.sensorsEnabled addObject:@"Gyroscope"];
    }



}

-(void) deconfigureSensorTag {
    if (([self sensorEnabled:@"Ambient temperature active"]) || ([self sensorEnabled:@"IR temperature active"])) {
        // Enable Temperature sensor
        CBUUID *sUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"IR temperature service UUID"]];
        CBUUID *cUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"IR temperature config UUID"]];
        unsigned char data = 0x00;
        [BLEUtility writeCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"IR temperature data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID enable:NO];
    }
    if ([self sensorEnabled:@"Accelerometer active"]) {
        CBUUID *sUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Accelerometer service UUID"]];
        CBUUID *cUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Accelerometer config UUID"]];
        uint8_t data = 0x00;
        [BLEUtility writeCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Accelerometer data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID enable:NO];
    }

       if ([self sensorEnabled:@"Humidity active"]) {
        CBUUID *sUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Humidity service UUID"]];
        CBUUID *cUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Humidity config UUID"]];
        uint8_t data = 0x00;
        [BLEUtility writeCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Humidity data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID enable:NO];
    }

    if ([self sensorEnabled:@"Gyroscope active"]) {
        CBUUID *sUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Gyroscope service UUID"]];
        CBUUID *cUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Gyroscope config UUID"]];
        uint8_t data = 0x00;
        [BLEUtility writeCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID data:[NSData dataWithBytes:&data length:1]];
        cUUID =  [CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Gyroscope data UUID"]];
        [BLEUtility setNotificationForCharacteristic:self.m_bleDevice.p sCBUUID:sUUID cCBUUID:cUUID enable:NO];
    }

}

-(bool)sensorEnabled:(NSString *)Sensor {
    NSString *val = [self.m_bleDevice.setupData valueForKey:Sensor];
    if (val) {
        if ([val isEqualToString:@"1"]) return TRUE;
    }
    return FALSE;
}

-(int)sensorPeriod:(NSString *)Sensor {
    NSString *val = [self.m_bleDevice.setupData valueForKey:Sensor];
    return (int)[val integerValue];
}



#pragma mark - CBCentralManager delegate function

-(void) centralManagerDidUpdateState:(CBCentralManager *)central {

}

-(void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}
- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error{


    [self.infoView deviceDisconnected];
}

#pragma mark - CBperipheral delegate functions

-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error {
    NSLog(@"..");
    if ([service.UUID isEqual:[CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Gyroscope service UUID"]]]) {
        [self configureSensorTag];
    }
}



-(void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error {
    NSLog(@".");
    for (CBService *s in peripheral.services) [peripheral discoverCharacteristics:nil forService:s];
}

-(void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didUpdateNotificationStateForCharacteristic %@, error = %@",characteristic.UUID, error);
}



-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    //NSLog(@"didUpdateValueForCharacteristic = %@",characteristic.UUID);
    NSString *sensTemp;
    NSString* sensHumidity;

    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"IR temperature data UUID"]]]) {
        float tAmb = [sensorTMP006 calcTAmb:characteristic.value];
        float tObj = [sensorTMP006 calcTObj:characteristic.value];

        sensTemp =  [NSString stringWithFormat:@"%.1f°C",tAmb];
        self.currentVal.tAmb = tAmb;
        self.currentVal.tIR = tObj;

        NSLog(@"%@", sensTemp);
        [self.infoView setTemp:sensTemp];
    }

    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Humidity data UUID"]]]) {

        float rHVal = [sensorSHT21 calcPress:characteristic.value];
        self.currentVal.humidity = rHVal;
        sensHumidity = [NSString stringWithFormat:@"%0.1f%%rH",rHVal];
        NSLog(@"%@", sensHumidity);
        [self.infoView setHumidity:sensHumidity];
    }



    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Gyroscope data UUID"]]]) {

        float x = [self.gyroSensor calcXValue:characteristic.value];
        float y = [self.gyroSensor calcYValue:characteristic.value];
        float z = [self.gyroSensor calcZValue:characteristic.value];

        self.currentVal.gyroX = x;
        self.currentVal.gyroY = y;
        self.currentVal.gyroZ = z;

    }

    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:[self.m_bleDevice.setupData valueForKey:@"Accelerometer data UUID"]]]) {
        float x = [sensorKXTJ9 calcXValue:characteristic.value];
        float y = [sensorKXTJ9 calcYValue:characteristic.value];
        float z = [sensorKXTJ9 calcZValue:characteristic.value];

        float mot = (pow(x,2)-pow(self.currentVal.gyroX,2))+(pow(y,2)-pow(self.currentVal.gyroY,2))+(pow(z,2)-pow(self.currentVal.gyroZ,2));
        if( mot < 0.1)
            NSLog(@"NO MOTION");
        else [self.infoView sendWarningonMotion];

        self.currentVal.accX = x;
        self.currentVal.accY = y;
        self.currentVal.accZ = z;

    }

    // The RSSI property was removed from CBPeripheral; the value now arrives in
    // peripheral:didReadRSSI:error: below.
    [peripheral readRSSI];
}

-(void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    if (!error) {
        [self.infoView setRSSIValue:RSSI];
    }
}


-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    NSLog(@"didWriteValueForCharacteristic %@ error = %@",characteristic.UUID,error);
}




- (IBAction) handleCalibrateGyro {
    NSLog(@"Calibrate gyroscope pressed ! ");
    [self.gyroSensor calibrate];
}


-(void) logValues:(NSTimer *)timer {
    NSString *date = [NSDateFormatter localizedStringFromDate:[NSDate date]
                                                    dateStyle:NSDateFormatterShortStyle
                                                    timeStyle:NSDateFormatterMediumStyle];
    self.currentVal.timeStamp = date;
    sensorTagValues *newVal = [[sensorTagValues alloc]init];
    newVal.tAmb = self.currentVal.tAmb;
    newVal.tIR = self.currentVal.tIR;
    newVal.accX = self.currentVal.accX;
    newVal.accY = self.currentVal.accY;
    newVal.accZ = self.currentVal.accZ;
    newVal.gyroX = self.currentVal.gyroX;
    newVal.gyroY = self.currentVal.gyroY;
    newVal.gyroZ = self.currentVal.gyroZ;
    newVal.magX = self.currentVal.magX;
    newVal.magY = self.currentVal.magY;
    newVal.magZ = self.currentVal.magZ;
    newVal.press = self.currentVal.press;
    newVal.humidity = self.currentVal.humidity;
    newVal.timeStamp = date;

    [self.vals addObject:newVal];

}


@end
