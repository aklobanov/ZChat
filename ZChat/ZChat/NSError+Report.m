//
//  NSError+Report.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 13.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NSError+Report.h"

@implementation NSError (Report)
- (NSString *)message
{
    NSString *c = [NSString stringWithFormat:@"%li",(long)[self code]];
    NSString *s = NSLocalizedString(c,nil);
    if ([s integerValue] == [self code])
    {
        s = [self localizedDescription];
    }
    NSError *error = [self userInfo][NSUnderlyingErrorKey];
    if (error != nil)
    {
        NSString *u = [error message];
        if (u != nil)
        {
            s = [[s stringByAppendingString:@" "] stringByAppendingString:u];
        }
    }
    return s;
}
- (NSString *)extraMessage
{
    NSString *c = [NSString stringWithFormat:@"%li",(long)[self code]];
    NSString *s = NSLocalizedString(c,nil);
    if ([s integerValue] == [self code])
    {
        s = [self localizedDescription];
    }
    NSString *msg;
    NSURL *url = [self userInfo][NSURLErrorFailingURLErrorKey];
    if (url != nil)
    {
        msg = [NSString stringWithFormat:@"ERROR: %@ URL: %@ CODE: %li",s,[url debugDescription], (long)[self code]];
    }
    else
    {
        msg = [NSString stringWithFormat:@"ERROR: %@ CODE: %li",s, (long)[self code]];
    }
    NSError *error = [self userInfo][NSUnderlyingErrorKey];
    if (error != nil)
    {
        NSString *underlyingMsg = [error extraMessage];
        if (underlyingMsg != nil)
        {
            msg = [[msg stringByAppendingString:@" "] stringByAppendingString:underlyingMsg];
        }
    }
    return msg;
}
- (void)report
{
    NSString *msg = [self extraMessage];
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"%@",msg);
#endif
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *str = [self message];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"E0", nil)
                                                                       message:str
                                                                preferredStyle:UIAlertControllerStyleAlert];
//        UIFont *font = [UIFont fontWithName:@"Oswald-Regular" size:18.0f];
//        NSAttributedString *title = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"E0", nil) attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor blackColor]}];
//        [alert setValue:title forKey:@"attributedTitle"];
//        font = [UIFont fontWithName:@"Lato-Regular" size:16.0f];
//        NSAttributedString *message = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor colorWithRed:0.0f green:122.0f/255.0f blue:1.0f alpha:1.0f]}];
//        [alert setValue:message forKey:@"attributedMessage"];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        [[[[[UIApplication sharedApplication] delegate] window] rootViewController] presentViewController:alert animated:YES completion:nil];
    });
}
@end
