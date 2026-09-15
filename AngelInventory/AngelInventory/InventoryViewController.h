//
//  InventoryViewController.h
//  AngelInventory
//
//  Created by Ugur Kirbac on 2/27/14.
//  Copyright (c) 2014 Ugur Kirbac. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface InventoryViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate>{
    
    IBOutlet UITextView *resultTextView;
}
@property (nonatomic, strong) IBOutlet UITextView *resultTextView;

-(IBAction)StartScan:(id) sender;

@end
