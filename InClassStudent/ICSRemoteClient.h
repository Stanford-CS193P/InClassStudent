//
//  ICSMultipeerManager.h
//  InClassStudent
//
//  Created by Brie Bunge on 3/3/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ICSRemoteClient : NSObject

#define kServer @"cs193p.herokuapp.com"
#define kServerPort 80

#define kConceptReceivedFromServerNotification @"ConceptReceivedFromServer"
#define kQuestionReceivedFromServerNotification @"QuestionReceivedFromServer"
#define kQuestionUpdatedNotification @"QuestionUpdated"
#define kAuthRequiredNotification @"AuthRequired"
#define kServerDisconnected @"ServerDisconnected"
#define kServerConnected @"ServerConnected"
#define kDataKey @"Data"
#define kMaxNumRetries 3
#define kRetryIntervalInSecs 10

// Returns the singleton instance
+ (id)sharedManager;

- (void)sendEvent:(NSString *)event withData:(NSDictionary *)dict andCallback:(void (^)(id response))callback;
- (void)connect;
- (void)disconnect;

@property (nonatomic) BOOL serverIsConnected;
@property (nonatomic, strong) NSString *userSUNetID;

@end
