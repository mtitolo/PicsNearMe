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
#import <SVProgressHUD.h>
#import "MRTAppDelegate.h"
#import "MRTSessionController.h"
#import "MRTImageCollectionViewCell.h"
#import <JTSImageViewController/JTSImageViewController.h>
#import <SDWebImage/SDImageCache.h>

@interface MRTViewController () <DBCameraViewControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) NSMutableArray* images;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *connectionsLabel;

@property (nonatomic, weak) UIView* statusView;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;

@end

@implementation MRTViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataReceived:) name:@"DidReceiveDataNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(saveImages) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"cream_pixels"]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadStoredImages];
    [self.collectionView reloadData];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
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

- (void)updateState
{
    if (self.images.count == 0) {
        
        UIImageView* waitingView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"waiting"]];
        UIView* waitingContainer = [[UIView alloc] initWithFrame:CGRectInset(waitingView.frame, -10, -15)];
        
        [waitingContainer addSubview:waitingView];
        
        UILabel* waitingLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(waitingView.frame), waitingContainer.frame.size.width, 30)];
        
        waitingLabel.text = @"No one's around! Check back later";
    }
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
            [self addImage:imageFile.url];
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

#pragma mark - UICollectionViewDataSource

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
    imageInfo.image = [[SDImageCache sharedImageCache] imageFromMemoryCacheForKey:self.images[indexPath.row]];
    UICollectionViewLayoutAttributes *attributes = [self.collectionView layoutAttributesForItemAtIndexPath:indexPath];
    imageInfo.referenceRect = attributes.frame;
    imageInfo.referenceView = collectionView;
    
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                           initWithImageInfo:imageInfo
                                           mode:JTSImageViewControllerMode_Image
                                           backgroundStyle:JTSImageViewControllerBackgroundStyle_ScaledDimmedBlurred];
    
    [imageViewer showFromViewController:self transition:JTSImageViewControllerTransition_FromOriginalPosition];
    
}

@end
