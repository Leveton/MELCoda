//
//  ViewController.m
//  MELCoda
//
//  Created by Mike Leveton on 3/2/15.
//  Copyright (c) 2015 MEL. All rights reserved.
//

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "Post.h"
#import "PostsTableViewController.h"

#define MessageHandler @"didGetPosts"

@interface ViewController ()<UITextFieldDelegate, WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) WKWebView *postsWebView;
@property (nonatomic, strong) NSMutableArray *posts;

@property (nonatomic, weak) IBOutlet UIView *barView;
@property (nonatomic, weak) IBOutlet UITextField *urlField;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *backButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *forwardButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *reloadButton;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *recentPostsButton;
@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@end

@implementation ViewController

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        self.posts = [NSMutableArray array];
        
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]
                                          init];
        
        NSString *scriptURL = [[NSBundle mainBundle] pathForResource:@"hideSections" ofType:@"js"];
        
        if (scriptURL)
        {
            NSString *scriptContent = [NSString stringWithContentsOfFile:scriptURL encoding:NSUTF8StringEncoding error:nil];
            
            if (scriptContent)
            {
                WKUserScript *script = [[WKUserScript alloc]initWithSource:scriptContent injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];
                
                [config.userContentController addUserScript:script];
            }
        }
        
        self.webView = [[WKWebView alloc]initWithFrame:CGRectZero];
        self.webView.navigationDelegate = self;
        
    }
    return self;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.barView setFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    
    self.backButton.enabled = NO;
    self.forwardButton.enabled = NO;
    self.recentPostsButton.enabled = NO;
    
    [self.progressView.layer setZPosition:2];
    [self.webView.layer setZPosition:1];
    [self.view addSubview:self.webView];
    
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSLayoutConstraint *height = [NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1 constant:-44];
    
    NSLayoutConstraint *width = [NSLayoutConstraint constraintWithItem:self.webView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:1 constant:0];
    
    [self.view addConstraint:height];
    [self.view addConstraint:width];
    
    
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    
    NSURL *webViewURL = [NSURL URLWithString:@"http://www.appcoda.com"];
    NSURLRequest *webViewRequest = [NSURLRequest requestWithURL:webViewURL];
    [self.webView loadRequest:webViewRequest];
    
    WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]
                                      init];
    
    NSString *scriptURL = [[NSBundle mainBundle] pathForResource:@"getPosts" ofType:@"js"];
    
    if (scriptURL)
    {
        NSString *scriptContent = [NSString stringWithContentsOfFile:scriptURL encoding:NSUTF8StringEncoding error:nil];
        
        if (scriptContent)
        {
            WKUserScript *script = [[WKUserScript alloc]initWithSource:scriptContent injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
            
            [config.userContentController addUserScript:script];
            [config.userContentController addScriptMessageHandler:self name:MessageHandler];
        }
    }
    
    self.postsWebView = [[WKWebView alloc]initWithFrame:CGRectZero];
    NSURL *postsURL = [NSURL URLWithString:@"http://www.appcoda.com"];
    NSURLRequest *postsRequest = [NSURLRequest requestWithURL:postsURL];
    [self.postsWebView loadRequest:postsRequest];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postSelected:) name:@"postSelected" object:nil];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"recentPosts"])
    {
        PostsTableViewController *vc = [segue destinationViewController];
        vc.posts = self.posts;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [self.barView setFrame:CGRectMake(0, 0, size.width, 30)];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"loading"]) {
        self.backButton.enabled = self.webView.canGoBack;
        self.forwardButton.enabled = self.webView.canGoForward;
    }
    if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progressView.hidden = self.webView.estimatedProgress == 1;
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
    }
    if ([keyPath isEqualToString:@"title"]) {
        self.title = self.webView.title;
    }
}

- (IBAction)back:(UIBarButtonItem *)sender
{
    [self.webView goBack];
}

- (IBAction)forward:(UIBarButtonItem *)sender
{
    [self.webView goForward];
}

- (IBAction)reload:(UIBarButtonItem *)sender
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.webView.URL];
    [self.webView loadRequest:request];
}

- (void)postSelected:(NSNotification *)note
{
    Post *post = [note object];
    
    if (post)
    {
        NSString *postURL = post.postURL;
        if (postURL && ![postURL isEqualToString:@""])
        {
            NSURL *url = [NSURL URLWithString:postURL];
            NSURLRequest *request = [NSURLRequest requestWithURL:url];
            [self.webView loadRequest:request];
        }
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSString *request = [navigationAction.request.URL.host lowercaseString];
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated && ![request hasPrefix:@"www.appcoda.com"])
    {
        [[UIApplication sharedApplication] openURL:navigationAction.request.URL];
        decisionHandler(WKNavigationActionPolicyCancel);
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }


}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    if (error)
    {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:nil]];
        
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    [self.progressView setProgress:0.0 animated:NO];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:MessageHandler]) {
        
        id postList = message.body;
        
        NSLog(@"postList class: %@", [postList class]);
        
        if ([postList respondsToSelector:@selector(objectEnumerator)])
        {
            [self.posts removeAllObjects];
            
            for (NSDictionary *ps in postList)
            {
               Post *post = [[Post alloc]init];
               post.postTitle = [ps objectForKey:@"postTitle"];
               post.postURL = [ps objectForKey:@"postURL"];
               [self.posts addObject:post];
            }
            
            self.recentPostsButton.enabled = YES;
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.urlField isFirstResponder])
    {
        [self.urlField resignFirstResponder];
    }
    
    NSURL *url = [NSURL URLWithString:self.urlField.text];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:request];
    
    return NO;
}

@end
