//
//  ICSQuestionResponse.h
//  InClassStudent
//
//  Created by Brie Bunge on 4/7/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ICSRemoteObject.h"

@interface ICSQuestionResponse : NSObject <ICSRemoteObject>

- (instancetype)initWithQuestionID:(NSString *)questionID
                           andText:(NSString *)questionText;

@property (strong, nonatomic, readonly) NSString *questionID;
@property (strong, nonatomic, readonly) NSString *questionText;

@property (strong, nonatomic, readwrite) NSString *response;

@end
