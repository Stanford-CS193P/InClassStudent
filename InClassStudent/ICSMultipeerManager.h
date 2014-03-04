//
//  ICSMultipeerManager.h
//  InClassStudent
//
//  Created by Brie Bunge on 3/3/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ICSMultipeerManager : NSObject

#define kDataReceivedFromServerNotification @"DataReceivedFromServer"
#define kServerPeerID @"ServerPeerID"
#define kDataKey @"Data"

// Returns the singleton instance
+ (id)sharedManager;

- (void)sendData:(NSData *)data;

@end
