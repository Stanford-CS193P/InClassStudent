//
//  ICSAuthViewController.m
//  InClassStudent
//
//  Created by Brie Bunge on 4/4/14.
//  Copyright (c) 2014 CS193P. All rights reserved.
//

#import "ICSAuthViewController.h"
#import "ICSRemoteClient.h"

#define AUTH_URL @"https://www.stanford.edu/class/cs193p/cgi-bin/app_auth/index.php?identifierForVendor="

@interface ICSAuthViewController () <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation ICSAuthViewController

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
    
    self.webView.delegate = self;
    
    NSURL *url = [NSURL URLWithString:[AUTH_URL stringByAppendingString:self.identifierForVendor]];
    NSLog(@"url %@", [AUTH_URL stringByAppendingString:self.identifierForVendor]);
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    NSString *currentURL = [[webView.request URL] absoluteString];
    
    NSLog(@"current url %@", currentURL);
    if ([currentURL hasPrefix:AUTH_URL]) {
        webView.hidden = YES;
        NSString *responseStr = [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.textContent"];
        NSError *e;
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding]
                                                                 options:NSJSONReadingMutableContainers
                                                                   error:&e];
        NSLog(@"response %@", response);
        [[ICSRemoteClient sharedManager] setUserSUNetID:[response objectForKey:@"sunetid"]];
        
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
