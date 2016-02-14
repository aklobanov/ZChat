//
//  MeViewController.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 04.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import "MeViewController.h"
#import "ModelData.h"
//#import "NXOAuth2.h"
#import "SWRevealViewController.h"
#import "PhotosCollectionController.h"

#define LOCAL_LEVEL_0 0
#define LOCAL_LEVEL_1 1
#define LOCAL_LEVEL_2 1

@interface MeViewController () <GetPhotoProtocol,UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *contentView;
@property (weak, nonatomic) IBOutlet UIImageView *image;
@property (weak, nonatomic) IBOutlet UITextField *name;
@end

@implementation MeViewController
{
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
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
//    {
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
//    }
    Me *me = [[ModelData sharedModelData] me];
    [_name setText:[me userName]];
    UIImage *photo = [me userAvatar];
    if (photo != nil)
    {
        [_image setImage:photo];
    }
}
- (void)dealloc
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
//    _profileUrl = nil;
}
- (void)didReceiveMemoryWarning
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super didReceiveMemoryWarning];
}
#pragma mark - STATUS BAR
- (UIStatusBarStyle)preferredStatusBarStyle
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return UIStatusBarStyleLightContent;
}
#pragma mark - ACTIONS
- (IBAction)doMyChat:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
//    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
//    {
        SWRevealViewController *revealViewController = [self revealViewController];
        if (revealViewController != nil)
        {
            [revealViewController revealToggleAnimated:YES];
        }
//    }
/*
    else
    {
        UISplitViewController *controller = (UISplitViewController *)[[[[UIApplication sharedApplication] delegate] window] rootViewController];
        if ([controller displayMode] == UISplitViewControllerDisplayModePrimaryOverlay)
        {
            [controller setPreferredDisplayMode:UISplitViewControllerDisplayModePrimaryHidden];
        }
    }
*/
}
- (IBAction)doSettings:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}
- (IBAction)doSignout:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
/*
    NXOAuth2Account *account = (NXOAuth2Account *)[[[NXOAuth2AccountStore sharedStore] accountsWithAccountType:@"MHD"] lastObject];
    if (account != nil)
    {
        [[NXOAuth2AccountStore sharedStore] removeAccount:account];
    }
*/
}
- (IBAction)doAvatar:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    PhotosCollectionController *controller = (PhotosCollectionController *)[[self storyboard] instantiateViewControllerWithIdentifier:@"PhotosLibrary"];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        controller.modalPresentationStyle = UIModalPresentationPopover;
    }
    else
    {
        [controller setModalPresentationStyle:UIModalPresentationOverFullScreen];
        [controller setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
    }
    [controller setTargetImageSize:[_image frame].size];
    [controller setDelegate:self];
    [self presentViewController:controller animated:YES completion:NULL];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        UIPopoverPresentationController *popover = [controller popoverPresentationController];
        [popover setPermittedArrowDirections:UIPopoverArrowDirectionLeft];
        [popover setBackgroundColor:[[controller view] backgroundColor]];
        [popover setSourceView:_image];
        CGRect rect = [_image bounds];
 /*
        if (rect.size.width > 768.0f)
        {
            rect.origin.y += 50.0f;
        }
*/
        [popover setSourceRect:rect];
    }
}
#pragma mark - DELEGATE: GetPhotoProtocol
- (void)collectionController:(PhotosCollectionController *)controller selectedPhoto:(UIImage *)photo
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if (photo != nil)
    {
        [_image setImage:photo];
        [[[ModelData sharedModelData] me] setUserAvatar:photo];
    }
    [controller dismissViewControllerAnimated:YES completion:NULL];
}
#pragma mark - DELEGATE: UITextField
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"TEXTFIELD=%@", [textField debugDescription]);
#endif
    if (![textField isFirstResponder]) [textField becomeFirstResponder];
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"TEXTFIELD= %@", [textField debugDescription]);
#endif
    if ([textField isFirstResponder]) [textField resignFirstResponder];
    [[[ModelData sharedModelData] me] setUserName:[textField text]];
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"TEXTFIELD=%@", [textField debugDescription]);
#endif
    [textField endEditing:YES];
    return YES;
}
@end
