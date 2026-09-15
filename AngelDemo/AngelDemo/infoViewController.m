//
//  infoViewController.m
//  AngelDemo
//
//  Created by Guest Account on 2/24/14.
//  Copyright (c) 2014 Ugur Kirbac. All rights reserved.
//

#import "infoViewController.h"

@interface infoViewController ()

@property (strong, nonatomic) NSTimer *fadeTimer;

@end

@implementation infoViewController
@synthesize humidityValue,tempValue,myRSSIValue;


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
    self.forgetAlertEnabled = FALSE;
    self.motionAlertEnabled = FALSE;
    self.motionAlertIgnored = FALSE;
    self.userResponded = TRUE;

	// Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.fadeTimer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(alphaFader:) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    // A repeating timer retains its target, so a running one would keep this screen alive.
    [self.fadeTimer invalidate];
    self.fadeTimer = nil;
}

- (IBAction)switchMotion:(id)sender {

    if(self.motionSwitch.on)
    {
        self.motionAlertEnabled = TRUE;
        self.motionAlertIgnored  = FALSE;
    }
    else{
        self.motionAlertEnabled = FALSE;
    }
}

- (IBAction)switchForget:(id)sender {

    if(self.forgetSwitch.on)
    {
        self.forgetAlertEnabled = TRUE;
    }
    else{
        self.forgetAlertEnabled = FALSE;
    }
}

// One alert at a time: userResponded stays FALSE until the shown alert is dismissed.
// UIAlertView was removed from iOS, so this presents a UIAlertController instead.
- (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                    button:(NSString *)button
                   handler:(void (^)(void))handler
{
    // Present from the tab bar, so the alert shows whichever tab is open.
    UIViewController *presenter = self.tabBarController ?: self;
    if (presenter.view.window == nil || presenter.presentedViewController != nil) {
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:button
                                              style:UIAlertActionStyleCancel
                                            handler:^(UIAlertAction *action) {
        self.userResponded = TRUE;
        if (handler) handler();
    }]];
    self.userResponded = FALSE;
    [presenter presentViewController:alert animated:YES completion:nil];
}

// Motion detection and warning
-(void)sendWarningonMotion{

    //[[NSNotificationCenter defaultCenter] postNotificationName:@"shake" object:self];
    if(self.userResponded && self.motionAlertEnabled && !self.motionAlertIgnored){
        [self showAlertWithTitle:@"Your Angel Moved!"
                         message:@"What do you want to do?"
                          button:@"Ignore"
                         handler:^{
            self.motionAlertIgnored = TRUE;
        }];
    }
}



-(void)deviceDisconnected{
    if(self.userResponded)
    {
        [self showAlertWithTitle:@"Your Angel is lost!"
                         message:@"Do you know where it is?"
                          button:@"Ignore"
                         handler:nil];
    }
}


// Forget Alert Implement

-(void)sendWarningonForget{
    if(self.userResponded && self.forgetAlertEnabled)
    {
        [self showAlertWithTitle:@"Did you forget your angel?"
                         message:@"Go get it back!"
                          button:@"Got it!"
                         handler:nil];
    }
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)setLabelValues:(NSString*)temp humidity:(NSString*)humidity RSSI:(NSString*)myRSSI{

    double delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        self.tempValue.text = temp;

    });


}

// A new reading is shown at full strength and then fades, so a stale value looks stale.
// Before, the alpha was never restored and every value faded out for good.
-(void)showValue:(NSString *)value inLabel:(UILabel *)label {
    label.text = value;
    label.textColor = [label.textColor colorWithAlphaComponent:1.0];
}

-(void)setTemp:(NSString*)temp{
    [self showValue:temp inLabel:self.tempValue];
}

-(void)setHumidity:(NSString*)humidity{
    [self showValue:humidity inLabel:self.humidityValue];
}
-(void)setRSSIValue:(NSNumber*)myRSSI{
 if(myRSSI != nil)
 {
     NSString *numberStr = [NSNumberFormatter localizedStringFromNumber:myRSSI numberStyle:NSNumberFormatterDecimalStyle];

     [self showValue:numberStr inLabel:self.myRSSIValue];

     if([myRSSI intValue]>(-90) && [myRSSI intValue]<(-80)){
         [self sendWarningonForget];
     }

 }


}




-(void) alphaFader:(NSTimer *)timer {
    CGFloat w,a;
    if (self.tempValue) {
        [self.tempValue.textColor getWhite:&w alpha:&a];
        if (a > MIN_ALPHA_FADE) a -= ALPHA_FADE_STEP;
        self.tempValue.textColor = [self.tempValue.textColor colorWithAlphaComponent:a];
    }


    if (self.humidityValue) {
        [self.humidityValue.textColor getWhite:&w alpha:&a];
        if (a > MIN_ALPHA_FADE) a -= ALPHA_FADE_STEP;
        self.humidityValue.textColor = [self.humidityValue.textColor colorWithAlphaComponent:a];
    }

    if (self.myRSSIValue) {
        [self.myRSSIValue.textColor getWhite:&w alpha:&a];
        if (a > MIN_ALPHA_FADE) a -= ALPHA_FADE_STEP;
        self.myRSSIValue.textColor = [self.myRSSIValue.textColor colorWithAlphaComponent:a];
    }

}




@end
