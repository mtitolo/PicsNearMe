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
#import "MRTImageCollectionViewCell.h"

@interface MRTViewController () <DBCameraViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSMutableArray* images;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation MRTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataReceived:) name:@"DidReceiveDataNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveImages) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    MRTAppDelegate* appDelegate = (MRTAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    CFUUIDRef udid = CFUUIDCreate(NULL);
    [appDelegate.mpcHandler setupPeerWithDisplayName:(NSString *)CFBridgingRelease(CFUUIDCreateString(NULL, udid))];
    [appDelegate.mpcHandler setupSession];
    [appDelegate.mpcHandler setupBrowser];
    [appDelegate.mpcHandler advertiseSelf:YES];
    
    [self loadStoredImages];
    [self.collectionView reloadData];
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
- (void)sendImage:(NSString*)imageString
{
    MRTAppDelegate* appDelegate = (MRTAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    [appDelegate.mpcHandler sendMessageToPeers:imageString];
    
}

- (void)loadStoredImages
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    self.images = [[NSArray arrayWithContentsOfFile:[documentsDirectory stringByAppendingPathComponent:@"images.plist"]] mutableCopy];
    
    if (!self.images) {
        self.images = [NSMutableArray array];
    }
}

- (void)saveImages
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    [self.images writeToFile:[documentsDirectory stringByAppendingPathComponent:@"images.plist"] atomically:YES];
}

- (void)addImage:(NSString*)image
{
    [self.images insertObject:image atIndex:0];
    [self.collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:0 inSection:0]]];

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
            [self sendImage:imageFile.url];
//            [self addImage:imageFile.url];
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
    
    [self addImage:message];
}

#pragma mark - UICollectionViewDelegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.images.count;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    MRTImageCollectionViewCell* cell = (MRTImageCollectionViewCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"ImageCell" forIndexPath:indexPath];
    
    [cell setImageWithURLString:self.images[indexPath.row]];
    
    return cell;
}

@end
