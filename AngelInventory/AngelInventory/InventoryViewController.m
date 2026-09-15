//
//  InventoryViewController.m
//  AngelInventory
//
//  Created by Ugur Kirbac on 2/27/14.
//  Copyright (c) 2014 Ugur Kirbac. All rights reserved.
//

#import "InventoryViewController.h"

// ZBar, the scanner this used, never shipped a 64-bit build, so no current iPhone can run it.
// Scanning now uses the barcode reader built into AVFoundation.
@interface InventoryViewController ()

@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) UIViewController *scannerController;

@end

@implementation InventoryViewController

@synthesize resultTextView;

-(IBAction)StartScan:(id) sender
{
    AVCaptureDevice *camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (camera == nil) {
        // The Simulator has no camera; a sample code still lets the rest of the flow be tried.
        [self offerSampleCode];
        return;
    }

    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (granted) {
                [self presentScannerWithCamera:camera];
            }
            else {
                [self showMessage:@"Camera access is off"
                           detail:@"Allow camera access for AngelInventory in Settings to scan barcodes."];
            }
        });
    }];
}

- (void)presentScannerWithCamera:(AVCaptureDevice *)camera
{
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:camera error:&error];
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    if (input == nil || ![session canAddInput:input] || ![session canAddOutput:output]) {
        [self showMessage:@"Could not start the camera" detail:error.localizedDescription];
        return;
    }
    [session addInput:input];
    [session addOutput:output];

    // Every symbology the device can read, except Interleaved 2 of 5, which the ZBar
    // version also switched off. The list is only known once the output is in a session.
    NSMutableArray *types = [output.availableMetadataObjectTypes mutableCopy];
    [types removeObject:AVMetadataObjectTypeInterleaved2of5Code];
    output.metadataObjectTypes = types;
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];

    UIViewController *scanner = [[UIViewController alloc] init];
    scanner.view.backgroundColor = [UIColor blackColor];
    AVCaptureVideoPreviewLayer *preview = [AVCaptureVideoPreviewLayer layerWithSession:session];
    preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    preview.frame = scanner.view.bounds;
    [scanner.view.layer addSublayer:preview];

    UIButton *cancel = [UIButton buttonWithType:UIButtonTypeSystem];
    [cancel setTitle:@"Cancel" forState:UIControlStateNormal];
    [cancel setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    cancel.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    cancel.translatesAutoresizingMaskIntoConstraints = NO;
    [cancel addTarget:self action:@selector(dismissScanner) forControlEvents:UIControlEventTouchUpInside];
    [scanner.view addSubview:cancel];
    [NSLayoutConstraint activateConstraints:@[
        [cancel.centerXAnchor constraintEqualToAnchor:scanner.view.centerXAnchor],
        [cancel.bottomAnchor constraintEqualToAnchor:scanner.view.safeAreaLayoutGuide.bottomAnchor constant:-24],
    ]];

    scanner.modalPresentationStyle = UIModalPresentationFullScreen;
    self.session = session;
    self.scannerController = scanner;
    [self presentViewController:scanner animated:YES completion:^{
        // startRunning blocks while the camera spins up, so keep it off the main thread.
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
            [session startRunning];
        });
    }];
}

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    // Codes keep arriving until the session stops; only the first one counts.
    if (self.session == nil) return;

    for (AVMetadataObject *object in metadataObjects) {
        if (![object isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) continue;
        NSString *code = ((AVMetadataMachineReadableCodeObject *)object).stringValue;
        if (code.length == 0) continue;

        [self didReadCode:code];
        [self dismissScanner];
        return;
    }
}

- (void)didReadCode:(NSString *)code
{
    NSLog(@"BARCODE= %@", code);

    NSUserDefaults *storeData=[NSUserDefaults standardUserDefaults];
    [storeData setObject:code forKey:@"CONSUMERID"];
    resultTextView.hidden=NO;
    resultTextView.text=code;
}

- (void)dismissScanner
{
    AVCaptureSession *session = self.session;
    self.session = nil;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        [session stopRunning];
    });
    [self.scannerController dismissViewControllerAnimated:YES completion:nil];
    self.scannerController = nil;
}

- (void)offerSampleCode
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"No camera"
                                                                   message:@"This device has no camera, for example the iOS Simulator. Use a sample code instead?"
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Use sample" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self didReadCode:@"ANGEL-DEMO-0001"];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showMessage:(NSString *)title detail:(NSString *)detail
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:detail
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}
@end
