//
//  ICSMultipeerManager.h
//  InClassStudent
//
//  Created by Brie Bunge on 3/3/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ICSRemoteClient : NSObject

#define kServer @"107.170.218.132"
// Dev is 1337, Prod is 80
#define kServerPort 80
#define kConceptReceivedFromServerNotification @"ConceptReceivedFromServer"
#define kServerDisconnected @"ServerDisconnected"
#define kServerConnected @"ServerConnected"
#define kDataKey @"Data"
#define kMaxNumRetries 3
#define kRetryIntervalInSecs 10

// Returns the singleton instance
+ (id)sharedManager;

- (void)sendEvent:(NSString *)event withData:(NSDictionary *)dict;
- (void)connect;
- (void)disconnect;

@property (nonatomic) BOOL serverIsConnected;

@end
