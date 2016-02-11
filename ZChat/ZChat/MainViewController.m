//
//  MainViewController.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 04.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import "MainViewController.h"

#define LOCAL_LEVEL_0 0
#define LOCAL_LEVEL_1 1
#define LOCAL_LEVEL_2 2

@interface MainViewController ()
@end

@implementation MainViewController
#pragma mark - ROTATION
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return [[self frontViewController] supportedInterfaceOrientations];
}
- (BOOL)shouldAutorotate
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return [[self frontViewController] shouldAutorotate];
}
@end
