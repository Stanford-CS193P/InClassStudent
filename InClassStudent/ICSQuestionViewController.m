//
//  ICSQuestionViewController.m
//  InClassStudent
//
//  Created by Brie Bunge on 3/31/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSQuestionViewController.h"
#import "ICSRemoteClient.h"

#define kQuestionTypeMultipleChoice @"MULTIPLE_CHOICE"
#define kQuestionTypeFreeResponse @"FREE_RESPONSE"
#define kQuestionTypeTrueFalse @"TRUE_FALSE"

@interface ICSQuestionViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *questionTextLabel;
@property (weak, nonatomic) IBOutlet UIView *contentRegion;

@property (strong, nonatomic) NSString *questionID;
@property (strong, nonatomic) NSString *questionText;
@property (strong, nonatomic) NSString *questionType;
@property (strong, nonatomic) NSArray *questionChoices;

@end

@implementation ICSQuestionViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.questionID = [self.questionData objectForKey:@"id"];
    self.questionText = [self.questionData objectForKey:@"text"];
    self.questionType = [self.questionData objectForKey:@"type"];
    
    self.questionTextLabel.text = self.questionText;
    
    if ([self.questionType isEqualToString:kQuestionTypeMultipleChoice]) {
        [self setUpMulipleChoiceQuestion:[self.questionData objectForKey:@"choices"]];
    } else if ([self.questionType isEqualToString:kQuestionTypeTrueFalse]) {
        [self setUpTrueFalseQuestion];
    } else if ([self.questionType isEqualToString:kQuestionTypeFreeResponse]) {
        [self setUpFreeResponseQuestion];
    }
}

- (void)setUpMulipleChoiceQuestion:(NSArray *)choices
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(4,4,4,4);
    UIImage *bgNormal = [[UIImage imageNamed:@"BlueButton"] resizableImageWithCapInsets:edgeInsets];
    UIImage *bgHighlighted = [[UIImage imageNamed:@"BlueButtonHighlighted"] resizableImageWithCapInsets:edgeInsets];
    
    UIButton *prevButton = nil;
    for (NSString *choice in choices) {
        UIButton *button = [[UIButton alloc] init];
        [button setBackgroundImage:bgNormal forState:UIControlStateNormal];
        [button setBackgroundImage:bgHighlighted forState:UIControlStateHighlighted];
        [button setTitle:choice forState:UIControlStateNormal];
        [self setUpButtonTapHandler:button];
        
        [self.contentRegion addSubview:button];
        
        [button setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                                       attribute:NSLayoutAttributeWidth
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.contentRegion
                                                                       attribute:NSLayoutAttributeWidth
                                                                      multiplier:1
                                                                        constant:0]];
        [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                                       attribute:NSLayoutAttributeHeight
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:nil
                                                                       attribute:NSLayoutAttributeNotAnAttribute
                                                                      multiplier:1
                                                                        constant:50]];
        [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                                       attribute:NSLayoutAttributeLeading
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.contentRegion
                                                                       attribute:NSLayoutAttributeLeading
                                                                      multiplier:1
                                                                        constant:0]];
        [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                                       attribute:NSLayoutAttributeTrailing
                                                                       relatedBy:NSLayoutRelationEqual
                                                                          toItem:self.contentRegion
                                                                       attribute:NSLayoutAttributeTrailing
                                                                      multiplier:1
                                                                        constant:0]];
        if (!prevButton) {
            [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:self.contentRegion
                                                                           attribute:NSLayoutAttributeTop
                                                                          multiplier:1
                                                                            constant:0]];
        } else {
            [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:button
                                                                           attribute:NSLayoutAttributeTop
                                                                           relatedBy:NSLayoutRelationEqual
                                                                              toItem:prevButton
                                                                           attribute:NSLayoutAttributeBottom
                                                                          multiplier:1
                                                                            constant:20]];
        }
        
        prevButton = button;
    }
}

- (void)setUpTrueFalseQuestion
{
    UIEdgeInsets edgeInsets = UIEdgeInsetsMake(4,4,4,4);
    
    UIButton *trueButton = [[UIButton alloc] init];
    [trueButton setBackgroundImage:[[UIImage imageNamed:@"GreenButton"] resizableImageWithCapInsets:edgeInsets]
                          forState:UIControlStateNormal];
    [trueButton setBackgroundImage:[[UIImage imageNamed:@"GreenButtonHighlighted"] resizableImageWithCapInsets:edgeInsets]
                          forState:UIControlStateHighlighted];
    [trueButton setTitle:@"True" forState:UIControlStateNormal];
    [self setUpButtonTapHandler:trueButton];
    
    UIButton *falseButton = [[UIButton alloc] init];
    [falseButton setBackgroundImage:[[UIImage imageNamed:@"RedButton"] resizableImageWithCapInsets:edgeInsets]
                           forState:UIControlStateNormal];
    [falseButton setBackgroundImage:[[UIImage imageNamed:@"RedButtonHighlighted"] resizableImageWithCapInsets:edgeInsets]
                           forState:UIControlStateHighlighted];
    [falseButton setTitle:@"False" forState:UIControlStateNormal];
    [self setUpButtonTapHandler:falseButton];
    
    [self.contentRegion addSubview:trueButton];
    [self.contentRegion addSubview:falseButton];
    
    [trueButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [falseButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:trueButton
                                                                   attribute:NSLayoutAttributeWidth
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentRegion
                                                                   attribute:NSLayoutAttributeWidth
                                                                  multiplier:1
                                                                    constant:0]];
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:trueButton
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                  multiplier:1
                                                                    constant:50]];
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:trueButton
                                                                   attribute:NSLayoutAttributeLeading
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentRegion
                                                                   attribute:NSLayoutAttributeLeading
                                                                  multiplier:1
                                                                    constant:0]];
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:trueButton
                                                                   attribute:NSLayoutAttributeTrailing
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentRegion
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1
                                                                    constant:0]];
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:trueButton
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentRegion
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1
                                                                    constant:0]];
    
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:falseButton
                                                                   attribute:NSLayoutAttributeWidth
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentRegion
                                                                   attribute:NSLayoutAttributeWidth
                                                                  multiplier:1
                                                                    constant:0]];
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:falseButton
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                  multiplier:1
                                                                    constant:50]];
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:falseButton
                                                                   attribute:NSLayoutAttributeLeading
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentRegion
                                                                   attribute:NSLayoutAttributeLeading
                                                                  multiplier:1
                                                                    constant:0]];
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:falseButton
                                                                   attribute:NSLayoutAttributeTrailing
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentRegion
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1
                                                                    constant:0]];
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:falseButton
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:trueButton
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1
                                                                    constant:40]];
}

- (void)setUpFreeResponseQuestion
{
    UITextView *textView = [[UITextView alloc] init];
    
    textView.backgroundColor = [[UIColor alloc] initWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    [textView setFont:[UIFont fontWithName:@"Avenir Next" size:16]];
    textView.returnKeyType = UIReturnKeyDone;
    
    textView.delegate = self;
    
    [self.contentRegion addSubview:textView];
    
    [textView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:textView
                                                                   attribute:NSLayoutAttributeLeading
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentRegion
                                                                   attribute:NSLayoutAttributeLeading
                                                                  multiplier:1
                                                                    constant:0]];
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:textView
                                                                   attribute:NSLayoutAttributeTrailing
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentRegion
                                                                   attribute:NSLayoutAttributeTrailing
                                                                  multiplier:1
                                                                    constant:0]];
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:textView
                                                                   attribute:NSLayoutAttributeTop
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentRegion
                                                                   attribute:NSLayoutAttributeTop
                                                                  multiplier:1
                                                                    constant:0]];
    // TODO: fix this size hack (purpose is to handle for keyboard obscuring the text view)
    [self.contentRegion addConstraint:[NSLayoutConstraint constraintWithItem:textView
                                                                   attribute:NSLayoutAttributeBottom
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self.contentRegion
                                                                   attribute:NSLayoutAttributeBottom
                                                                  multiplier:1
                                                                    constant:-216]];
    
    [textView becomeFirstResponder];
}

- (void)setUpButtonTapHandler:(UIButton *)button
{
    [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)buttonTapped:(UIButton *)sender
{
    NSLog(@"%@", sender.currentTitle);
    [self sendQuestionResponse:sender.currentTitle];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (textView.returnKeyType == UIReturnKeyDone && [text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
        return NO;
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    [self sendQuestionResponse:textView.text];
}

- (void)sendQuestionResponse:(NSString *)response
{
    [[ICSRemoteClient sharedManager] sendEvent:@"CreateQuestionResponse"
                                      withData:@{ @"questionID": self.questionID,
                                                  @"questionText": self.questionText,
                                                  @"response": response }
                                   andCallback:NULL];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end