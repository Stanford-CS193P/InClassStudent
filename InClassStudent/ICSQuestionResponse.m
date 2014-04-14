//
//  ICSQuestionResponse.m
//  InClassStudent
//
//  Created by Brie Bunge on 4/7/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSQuestionResponse.h"
#import "ICSRemoteClient.h"

@implementation ICSQuestionResponse

- (instancetype)initWithQuestionID:(NSString *)questionID
                           andText:(NSString *)questionText
{
    self = [super init];
    if (self) {
        _questionID = questionID;
        _questionText = questionText;
    }
    return self;
}

- (void)send
{
    [[ICSRemoteClient sharedManager] sendEvent:@"CreateQuestionResponse"
                                      withData:@{ @"questionID": self.questionID,
                                                  @"questionText": self.questionText,
                                                  @"response": self.response }
                                   andCallback:NULL];
}

@end
