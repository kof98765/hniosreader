//
//  SVWebViewController.m
//
//  Created by Sam Vermette on 08.11.10.
//  Copyright 2010 Sam Vermette. All rights reserved.
//
//  https://github.com/samvermette/SVWebViewController

#import "SVWebViewControllerActivityChrome.h"
#import "SVWebViewControllerActivitySafari.h"
#import "SVWebViewControllerCustomForModal.h"
#import "NJKWebViewProgressView.h"
#import "NJKWebViewProgress.h"
#import "UIButton+Extension.h"
#import "UIButtonCustomHighlight.h"

@interface SVWebViewControllerCustomForModal () <UIWebViewDelegate, UIScrollViewDelegate, NJKWebViewProgressDelegate>

@property (nonatomic, strong) UIBarButtonItem *backBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *forwardBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *refreshBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *stopBarButtonItem;
@property (nonatomic, strong) UIBarButtonItem *actionBarButtonItem;

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSURLRequest *request;

@property (nonatomic, strong) UIButtonCustomHighlight *closeButton;

@property CGFloat lastOffsetY;

@end


@implementation SVWebViewControllerCustomForModal{
    NJKWebViewProgressView *_progressView;
    NJKWebViewProgress *_progressProxy;
}

#pragma mark - Initialization

- (void)dealloc {
    [self.webView stopLoading];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.webView.delegate = nil;
}

- (instancetype)initWithAddress:(NSString *)urlString {
    return [self initWithURL:[NSURL URLWithString:urlString]];
}

- (instancetype)initWithURL:(NSURL*)pageURL {
    return [self initWithURLRequest:[NSURLRequest requestWithURL:pageURL]];
}

- (instancetype)initWithURLRequest:(NSURLRequest*)request {
    self = [super init];
    if (self) {
        self.request = request;
    }
    return self;
}

- (void)loadRequest:(NSURLRequest*)request {
    [self.webView loadRequest:request];
}

#pragma mark - View lifecycle

- (void)loadView {
    self.view = self.webView;
    [self loadRequest:self.request];
    
    UIView *statusBarBackground = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)];
    [statusBarBackground setBackgroundColor:[UIColor whiteColor]];
    [self.view addSubview:statusBarBackground];
    
    
    //Autolayout constraints for status bar background
    statusBarBackground.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:statusBarBackground attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    
    [self.view addConstraint:topConstraint];
    
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:statusBarBackground attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    
    [self.view addConstraint:leftConstraint];
    
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:statusBarBackground attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
    
    [self.view addConstraint:rightConstraint];
    
    [statusBarBackground addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[statusBarBackground(==20)]"
                                                                                options:0
                                                                                metrics:nil
                                                                                  views:NSDictionaryOfVariableBindings(statusBarBackground)]];
    
    
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    
    [self prefersStatusBarHidden];
    [self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
    
    [self updateToolbarItems];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    self.closeButton = [[UIButtonCustomHighlight alloc] initWithFrame:CGRectMake(screenWidth - 30, 33, 12, 12)];
    
    [self.closeButton setHitTestEdgeInsets:UIEdgeInsetsMake(-20.0, -20.0, -20.0, -20.0)];
    
    UIImage *image = [UIImage imageNamed:@"xButton.png"];
    
    [self.closeButton setBackgroundImage:image forState:UIControlStateNormal];
    [self.view addSubview:self.closeButton];
    [self.closeButton addTarget:self
                        action:@selector(closeButtonPressed)
              forControlEvents:UIControlEventTouchUpInside];
    
    _progressProxy = [[NJKWebViewProgress alloc] init]; // instance variable
    self.webView.delegate = _progressProxy;
    _progressProxy.webViewProxyDelegate = self;
    _progressProxy.progressDelegate = self;
    
    CGFloat progressBarHeight = 3.f;
    CGRect navigaitonBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigaitonBarBounds.size.height - progressBarHeight, navigaitonBarBounds.size.width, progressBarHeight);
    _progressView = [[NJKWebViewProgressView alloc] initWithFrame:barFrame];
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    
    CGRect frame = _progressView.frame;
    frame.origin.y = 20;
    _progressView.frame = frame;
    
}

- (void)closeButtonPressed{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    self.webView.scrollView.delegate = self;
    
    // Enable swipe to go back gesture
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.lastOffsetY = scrollView.contentOffset.y;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    bool hide = (scrollView.contentOffset.y > self.lastOffsetY);
    
    [UIView animateWithDuration:0.5 animations:^{
        self.closeButton.alpha = !hide;
    }];
    
    [self.navigationController setToolbarHidden:hide animated:YES];
    
}

- (void)viewDidUnload {
    [super viewDidUnload];
    self.webView = nil;
    _backBarButtonItem = nil;
    _forwardBarButtonItem = nil;
    _refreshBarButtonItem = nil;
    _stopBarButtonItem = nil;
    _actionBarButtonItem = nil;
}



- (void)viewWillAppear:(BOOL)animated {
    NSAssert(self.navigationController, @"SVWebViewController needs to be contained in a UINavigationController. If you are presenting SVWebViewController modally, use SVModalWebViewController instead.");
    
    [super viewWillAppear:animated];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:NO animated:animated];
    }
    else if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
    
    
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    [self.view addSubview:_progressView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
    
    [_progressView removeFromSuperview];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        return YES;
    
    return toInterfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

#pragma mark - Getters

- (UIWebView*)webView {
    if(!_webView) {
        _webView = [[UIWebView alloc] initWithFrame:[UIScreen mainScreen].bounds];
        _webView.delegate = self;
        _webView.scalesPageToFit = YES;
    }
    return _webView;
}

- (UIBarButtonItem *)backBarButtonItem {
    if (!_backBarButtonItem) {
        _backBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/SVWebViewControllerBack"]
                                                              style:UIBarButtonItemStylePlain
                                                             target:self
                                                             action:@selector(goBackTapped:)];
        _backBarButtonItem.width = 18.0f;
    }
    return _backBarButtonItem;
}

- (UIBarButtonItem *)forwardBarButtonItem {
    if (!_forwardBarButtonItem) {
        _forwardBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"SVWebViewController.bundle/SVWebViewControllerNext"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(goForwardTapped:)];
        _forwardBarButtonItem.width = 18.0f;
    }
    return _forwardBarButtonItem;
}

- (UIBarButtonItem *)refreshBarButtonItem {
    if (!_refreshBarButtonItem) {
        _refreshBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadTapped:)];
    }
    return _refreshBarButtonItem;
}

- (UIBarButtonItem *)stopBarButtonItem {
    if (!_stopBarButtonItem) {
        _stopBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopTapped:)];
    }
    return _stopBarButtonItem;
}

- (UIBarButtonItem *)actionBarButtonItem {
    if (!_actionBarButtonItem) {
        _actionBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonTapped:)];
    }
    return _actionBarButtonItem;
}

#pragma mark - Toolbar

- (void)updateToolbarItems {
    self.backBarButtonItem.enabled = self.self.webView.canGoBack;
    self.forwardBarButtonItem.enabled = self.self.webView.canGoForward;
    
    UIBarButtonItem *refreshStopBarButtonItem = self.self.webView.isLoading ? self.stopBarButtonItem : self.refreshBarButtonItem;
    
    UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        CGFloat toolbarWidth = 250.0f;
        fixedSpace.width = 35.0f;
        
        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          refreshStopBarButtonItem,
                          fixedSpace,
                          self.backBarButtonItem,
                          fixedSpace,
                          self.forwardBarButtonItem,
                          fixedSpace,
                          self.actionBarButtonItem,
                          nil];
        
        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, toolbarWidth, 44.0f)];
        toolbar.items = items;
        toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.navigationItem.rightBarButtonItems = items.reverseObjectEnumerator.allObjects;
    }
    
    else {
        NSArray *items = [NSArray arrayWithObjects:
                          fixedSpace,
                          self.backBarButtonItem,
                          flexibleSpace,
                          self.forwardBarButtonItem,
                          flexibleSpace,
                          refreshStopBarButtonItem,
                          flexibleSpace,
                          self.actionBarButtonItem,
                          fixedSpace,
                          nil];
        
        // self.navigationController.toolbar.barStyle = self.navigationController.navigationBar.barStyle;
        // self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
        self.toolbarItems = items;
    }
}

#pragma mark - UIWebViewDelegate


- (void)webViewDidStartLoad:(UIWebView *)webView {
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [self updateToolbarItems];
    
    
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
    
    
    [self updateToolbarItems];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self updateToolbarItems];
}

#pragma mark - Target actions

- (void)goBackTapped:(UIBarButtonItem *)sender {
    [self.webView goBack];
}

- (void)goForwardTapped:(UIBarButtonItem *)sender {
    [self.webView goForward];
}

- (void)reloadTapped:(UIBarButtonItem *)sender {
    [self.webView reload];
}

- (void)stopTapped:(UIBarButtonItem *)sender {
    [self.webView stopLoading];
    [self updateToolbarItems];
}

- (void)actionButtonTapped:(id)sender {
    NSURL *url = self.webView.request.URL ? self.webView.request.URL : self.request.URL;
    if (url != nil) {
        NSArray *activities = @[[SVWebViewControllerActivitySafari new], [SVWebViewControllerActivityChrome new]];
        
        if ([[url absoluteString] hasPrefix:@"file:///"]) {
            UIDocumentInteractionController *dc = [UIDocumentInteractionController interactionControllerWithURL:url];
            [dc presentOptionsMenuFromRect:self.view.bounds inView:self.view animated:YES];
        } else {
            UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:activities];
            
#ifdef __IPHONE_8_0
            if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1 &&
                UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            {
                UIPopoverPresentationController *ctrl = activityController.popoverPresentationController;
                ctrl.sourceView = self.view;
                ctrl.barButtonItem = sender;
            }
#endif
            
            [self presentViewController:activityController animated:YES completion:nil];
        }
    }
}

- (void)doneButtonTapped:(id)sùender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - NJKWebViewProgressDelegate

-(void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    [_progressView setProgress:progress animated:NO];
}



@end
