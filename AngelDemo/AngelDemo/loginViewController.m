//
//  ViewController.m
//  AngelDemo
//
//  Created by Ugur Kirbac on 20/02/14.
//  Copyright (c) 2014 Ugur Kirbac. All rights reserved.
//

#import "loginViewController.h"

@interface loginViewController ()

@end

@implementation loginViewController
#pragma mark - UIViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
	self.title = NSLocalizedString(@"AngelApp Demo", nil);
    credentialsDictionary = [[NSDictionary alloc] initWithObjects:[NSArray arrayWithObjects:@"11", @"1234", nil] forKeys:[NSArray arrayWithObjects:@"aa",@"alex", nil]];
}

- (IBAction)enterCredentials
{
    if ([[credentialsDictionary objectForKey:usernameField.text]isEqualToString:passwordField.text]) {
        [self switchView];
    }
    else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Incorrect Password"
                                                                       message:@"This password is incorrect."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Dismiss" style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (IBAction)backgroundTouched
{
    [usernameField resignFirstResponder];
    [passwordField resignFirstResponder];

}

- (void)switchView{


    [self performSegueWithIdentifier:@"NextView" sender:self];
}



@end
