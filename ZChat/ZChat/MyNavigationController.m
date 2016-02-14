//
//  MyNavigationController.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 04.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import "MyNavigationController.h"

#define LOCAL_LEVEL_0 0
#define LOCAL_LEVEL_1 1
#define LOCAL_LEVEL_2 2

@implementation MyNavigationController
#pragma mark - INIT
/*
- (void)awakeFromNib
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super awakeFromNib];
    UIFont *font = [UIFont fontWithName:@"Oswald-Regular" size:20.0f];
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"FONT=%@", [font debugDescription]);
#endif
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName:font}];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName:font} forState:UIControlStateNormal];
}
*/
#pragma mark - KEYBOARD
- (BOOL)disablesAutomaticKeyboardDismissal
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return NO;
}
#pragma mark - ROTATION
/*
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return [[self topViewController] supportedInterfaceOrientations];
}
- (BOOL)shouldAutorotate
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return [[self topViewController] shouldAutorotate];
}
*/
@end
