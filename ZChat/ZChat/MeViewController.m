//
//  MeViewController.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 04.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import "MeViewController.h"
#import "DataModel.h"
#import "NXOAuth2.h"
#import "SWRevealViewController.h"

#define LOCAL_LEVEL_0 0
#define LOCAL_LEVEL_1 1
#define LOCAL_LEVEL_2 1

@interface MeViewController ()
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UILabel *name;
@end

@implementation MeViewController
{
    NSString *_profileUrl;
}
@synthesize contentView = _contentView;
@synthesize image = _image;
@synthesize name = _name;
#pragma mark - VIEW
- (void)updateHeight:(CGFloat)height
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
}
- (void)viewDidLoad
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super viewDidLoad];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        CGRect screenBounds = [[UIScreen mainScreen] bounds];
        CGFloat height = screenBounds.size.height > screenBounds.size.width ? screenBounds.size.height : screenBounds.size.width;
        NSArray *contstraints = [_contentView constraints];
        for (NSLayoutConstraint *contstraint in contstraints)
        {
#if DEBUG >= LOCAL_LEVEL_2
            NSLog(@"CONSTRAINT=%@", [contstraint debugDescription]);
#endif
            if ([[contstraint identifier] isEqualToString:@"MeHeight"])
            {
                [_contentView removeConstraint:contstraint];
                NSLayoutConstraint *newConstrain = [NSLayoutConstraint constraintWithItem:_contentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:height];
                [newConstrain setIdentifier:@"MeHeight"];
                [_contentView addConstraint:newConstrain];
                [newConstrain setActive:YES];
                break;
            }
        }
        CGRect contentFrame = [_contentView frame];
        contentFrame.size.height = height;
        [_contentView setFrame:contentFrame];
        [(UIScrollView *)[self view] setContentSize:contentFrame.size];
#if DEBUG >= LOCAL_LEVEL_2
        NSLog(@"SCROLL VIEW=%@\nCONTENT VIEW=%@",[[self view] debugDescription],[_contentView debugDescription]);
#endif
    }
    __weak typeof(self) weakSelf = self;
    [DataModel fetchMe:_image completion:^(NSString *userName, NSString *profileUrl, NSString *billingUrl) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf->_profileUrl = profileUrl;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf->_name setText:[userName uppercaseStringWithLocale:[NSLocale currentLocale]]];
        });
    }];
}
- (void)dealloc
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    _profileUrl = nil;
}
#pragma mark - STATUS BAR
- (UIStatusBarStyle)preferredStatusBarStyle
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return UIStatusBarStyleLightContent;
}
- (void)didReceiveMemoryWarning
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super didReceiveMemoryWarning];
}
#pragma mark - ACTIONS
- (IBAction)doMyLibrary:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        SWRevealViewController *revealViewController = [self revealViewController];
        if (revealViewController != nil)
        {
            [revealViewController revealToggleAnimated:YES];
        }
    }
    else
    {
        UISplitViewController *controller = (UISplitViewController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
        if ([controller displayMode] == UISplitViewControllerDisplayModePrimaryOverlay)
        {
            [controller setPreferredDisplayMode:UISplitViewControllerDisplayModePrimaryHidden];
        }
    }
}
- (IBAction)doMHD:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    NSURL *url = [DataModel urlForGotTo:_profileUrl];
    if (url != nil)
    {
        [[UIApplication sharedApplication] openURL:url];
    }
}
- (IBAction)doSignout:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    NXOAuth2Account *account = (NXOAuth2Account *)[[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"MHD"] lastObject];
    if (account != nil)
    {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    }
}
@end
