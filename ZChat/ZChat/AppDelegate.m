//
//  AppDelegate.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 04.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import "AppDelegate.h"
#import "ModelData.h"

#define LOCAL_LEVEL_0 0
#define LOCAL_LEVEL_1 1
#define LOCAL_LEVEL_2 2

@interface AppDelegate ()
@end

@implementation AppDelegate
@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [self registerDefaultsFromSettingsBundle];
    Me *me = [[ModelData sharedModelData] me];
    if ([[me userName] length] == 0)
    {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *str = [NSLocalizedString(@"U0", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:str
                                                                       message:NSLocalizedString(@"U1", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
            UIFont *font = [UIFont systemFontOfSize:22.0f];
            NSAttributedString *title = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor blueColor]}];
            [alert setValue:title forKey:@"attributedTitle"];
            font = [UIFont systemFontOfSize:16.0f];
            NSAttributedString *message = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"U1", nil) attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor grayColor]}];
            [alert setValue:message forKey:@"attributedMessage"];
            __weak UIAlertController* weakAlert = alert;
            __weak Me *weakMe = me;
            UIAlertAction* okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
                __strong UIAlertController* strongAlert = weakAlert;
                __strong Me *strongMe = weakMe;
                [strongMe setUserName:[[[strongAlert textFields] lastObject] text]];
                NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
                BOOL clearUsers = [defs boolForKey:@"clearUsers"];
                if (clearUsers)
                {
                    [[ModelData sharedModelData] clearUsers];
                }
                [[ModelData sharedModelData] publishMyselfWithName:[strongMe userName]];
            }];
            [okAction setValue:[UIColor blueColor] forKey:@"titleTextColor"];
            [alert addAction:okAction];
            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                [textField setFont:[UIFont systemFontOfSize:20.0f]];
                [textField setTextColor:[UIColor blueColor]];
            }];
            __strong typeof (self) strongSelf = weakSelf;
            [[strongSelf->_window rootViewController] presentViewController:alert animated:YES completion:nil];
        });
    }
    else
    {
        NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
        BOOL clearUsers = [defs boolForKey:@"clearUsers"];
        if (clearUsers)
        {
            [[ModelData sharedModelData] clearUsers];
        }
        [[ModelData sharedModelData] publishMyselfWithName:[me userName]];
    }
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}
- (void)applicationDidEnterBackground:(UIApplication *)application
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}
- (void)applicationWillEnterForeground:(UIApplication *)application
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}
- (void)applicationDidBecomeActive:(UIApplication *)application
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}
- (void)applicationWillTerminate:(UIApplication *)application
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    BOOL clearHistory = [defs boolForKey:@"clearHistory"];
    if (clearHistory)
    {
        [[ModelData sharedModelData] clearMessages];
    }
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}
- (void)registerDefaultsFromSettingsBundle
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
    [defs synchronize];
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    if (settingsBundle == nil)
    {
#if DEBUG >= LOCAL_LEVEL_0
        NSLog(@"Could not find Settings.bundle");
#endif
        return;
    }
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for (NSDictionary *prefSpecification in preferences)
    {
        NSString *key = [prefSpecification objectForKey:@"Key"];
        if (key != nil)
        {
            // check if value readable in userDefaults
            id currentObject = [defs objectForKey:key];
            if (currentObject == nil)
            {
                // not readable: set value from Settings.bundle
                id objectToSet = [prefSpecification objectForKey:@"DefaultValue"];
                [defaultsToRegister setObject:objectToSet forKey:key];
#if DEBUG >= LOCAL_LEVEL_2
                NSLog(@"Setting object %@ for key %@", objectToSet, key);
#endif
            }
#if DEBUG >= LOCAL_LEVEL_2
            else
            {
                // already readable: don't touch
                NSLog(@"Key %@ is readable (value: %@), nothing written to defaults.", key, currentObject);
            }
#endif
        }
    }
    [defs registerDefaults:defaultsToRegister];
    [defs synchronize];
}
@end
