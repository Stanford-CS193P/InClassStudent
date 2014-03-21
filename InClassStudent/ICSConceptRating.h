//
//  ICSConceptRating.h
//  InClassStudent
//
//  Created by Brie Bunge on 3/20/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ICSConceptRating : NSObject

- (id)initWithConceptName:(NSString *)conceptName andLabel:(UILabel *)label;

@property (nonatomic, strong) NSString *conceptName;
@property (nonatomic, weak) UILabel *label;
@property (nonatomic) NSInteger rating;
@property (nonatomic, weak) NSLayoutConstraint *levelConstraint;

@end
