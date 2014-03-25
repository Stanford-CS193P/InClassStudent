//
//  ICSUnderstandingIndicator.h
//  InClassStudent
//
//  Created by Brie Bunge on 3/24/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ICSUnderstandingIndicator : UIView

@property (nonatomic) CGPoint touchLocation;
@property (nonatomic) CGFloat touchFraction;

- (void)viewHasSuperView;

@end
