//
//  MRTMPCHandler.m
//  PicsNearMe
//
//  Created by Michele Titolo on 5/16/14.
//  Copyright (c) 2014 Michele Titolo. All rights reserved.
//

#import "MRTMPCHandler.h"

static NSString * const kServiceType = @"mrt-picsnearme";

@implementation MRTMPCHandler

- (void)setupPeerWithDisplayName:(NSString *)displayName {
    self.peerID = [[MCPeerID alloc] initWithDisplayName:displayName];
}

- (void)setupSession {
    self.session = [[MCSession alloc] initWithPeer:self.peerID];
    self.session.delegate = self;
}

- (void)setupBrowser {
    self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.peerID serviceType:kServiceType];
    self.browser.delegate = self;
    [self.browser startBrowsingForPeers];
}

- (void)advertiseSelf:(BOOL)advertise {
    if (advertise) {
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.peerID discoveryInfo:nil serviceType:kServiceType];
        self.advertiser.delegate = self;
        [self.advertiser startAdvertisingPeer];
        
        
    } else {
        [self.advertiser stopAdvertisingPeer];
        self.advertiser = nil;
    }
}

- (void)addPeerWithID:(MCPeerID*)peerID
{
    if (!self.peers) {
        self.peers = [NSMutableSet set];
    }

    NSSet* matching = [self.peers filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"%@ == %@", @"displayName", peerID.displayName]];
    
    if (matching.count > 0) {
        [self.peers minusSet:matching];
    }
    
    [self.peers addObject:peerID];
}

- (void)sendMessageToPeers:(NSString *)message
{
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    if (![self.session sendData:data
                        toPeers:[self.peers allObjects]
                       withMode:MCSessionSendDataReliable
                          error:&error]) {
        NSLog(@"[Error] %@", error);
    }
}

- (BOOL)alreadyPeers:(MCPeerID*)peerID
{
    NSSet* matching = [self.peers filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"%@ == %@", @"displayName", peerID.displayName]];
    
    return (matching > 0);
}

#pragma mark - MCSessionDelegate

- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    NSDictionary *userInfo = @{ @"peerID": peerID,
                                @"state" : @(state) };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MPCDemo_DidChangeStateNotification"
                                                            object:nil
                                                          userInfo:userInfo];
    });
}

- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    NSDictionary *userInfo = @{ @"data": data,
                                @"peerID": peerID };
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DidReceiveDataNotification"
                                                            object:nil
                                                          userInfo:userInfo];
    });
}


- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    
}

- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    
}

- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
}

- (void) session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void (^)(BOOL accept))certificateHandler
{
    certificateHandler(YES);
}

#pragma mark - MCNearbyServicesBrowserDelegate

- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info
{
    if (![self alreadyPeers:peerID]) {
        [self addPeerWithID:peerID];
        [browser invitePeer:peerID toSession:self.session withContext:nil timeout:0];
    }

}

- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID
{
    if ([self.peers containsObject:peerID]) {
        [self.peers removeObject:peerID];
    }
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void (^)(BOOL, MCSession *))invitationHandler
{
    [self addPeerWithID:peerID];
    invitationHandler(YES, self.session);
}
@end
