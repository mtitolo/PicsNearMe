//
//  MRTViewController.m
//  PicsNearMe
//
//  Created by Michele Titolo on 5/16/14.
//  Copyright (c) 2014 Michele Titolo. All rights reserved.
//

#import "MRTViewController.h"
#import <DBCamera/DBCameraDelegate.h>
#import <DBCamera/DBCameraViewController.h>
#import <DBCamera/DBCameraContainerViewController.h>
#import <Parse/Parse.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import "MRTAppDelegate.h"
#import "MRTMPCHandler.h"

@interface MRTViewController () <DBCameraViewControllerDelegate>

@end

@implementation MRTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataReceived:) name:@"DidReceiveDataNotification" object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    MRTAppDelegate* appDelegate = (MRTAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appDelegate.mpcHandler setupPeerWithDisplayName:[UIDevice currentDevice].name];
    [appDelegate.mpcHandler setupSession];
    [appDelegate.mpcHandler advertiseSelf:YES];
}

- (IBAction)takePhotoTapped:(id)sender
{
    DBCameraContainerViewController *container = [[DBCameraContainerViewController alloc] initWithDelegate:self];
    DBCameraViewController *cameraController = [DBCameraViewController initWithDelegate:self];
    [cameraController setUseCameraSegue:NO];
    [container setCameraViewController:cameraController];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:container];
    [nav setNavigationBarHidden:YES];
    [self presentViewController:nav animated:YES completion:nil];
}
#pragma mark - DBCameraViewControllerDelegate

- (void) dismissCamera
{
    [self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) captureImageDidFinish:(UIImage *)image withMetadata:(NSDictionary *)metadata
{
    NSData *imageData = UIImageJPEGRepresentation(image, 0.05f);
    PFFile *imageFile = [PFFile fileWithName:@"Image.jpg" data:imageData];
    
    [SVProgressHUD show];
    [imageFile saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (!error) {
            [SVProgressHUD dismiss];
            DLog(@"Saved photo to URL: %@", imageFile.url);
            [self dismissCamera];
        }
        else{
            [SVProgressHUD dismiss];
            DLog(@"Error: %@ %@", error, [error userInfo]);
        }
    } progressBlock:^(int percentDone) {
        [SVProgressHUD showProgress:percentDone/100];
    }];
}

#pragma mark - Notifications

- (void)dataReceived:(NSNotification*)notification
{
    NSString* message = [[NSString  alloc] initWithData:notification.userInfo[@"data"] encoding:NSUTF8StringEncoding];
    
    MCPeerID* peer = notification.userInfo[@"peerID"];
    
    DLog(@"Received message %@ from %@", message, peer.displayName);
}

@end
