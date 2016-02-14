//
//  UsersViewController.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 14.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import "UsersViewController.h"
#import "ModelData.h"
#import "SWRevealViewController.h"
#import "ZChatUserCell.h"

#define LOCAL_LEVEL_0 0
#define LOCAL_LEVEL_1 1
#define LOCAL_LEVEL_2 1

@interface UsersViewController () <ModelUsersProtocol>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation UsersViewController
{
    ModelData *_modelData;
}
static NSString *cellId = @"ZChatUser";
#pragma mark - VIEW
- (void)awakeFromNib
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super awakeFromNib];
    _modelData = [ModelData sharedModelData];
}
- (void)viewDidLoad
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super viewDidLoad];
    [_modelData setDelegateUsers:self];
}
- (void)didReceiveMemoryWarning
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super didReceiveMemoryWarning];
}
- (void)dealloc
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    _modelData = nil;
}
#pragma mark - STATUS BAR
- (UIStatusBarStyle)preferredStatusBarStyle
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return UIStatusBarStyleLightContent;
}
#pragma mark - DATASOURCE: UITableViewController
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return 1;
}
/*
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return NSLocalizedString(@"U2", nil);
}
*/
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return 80.0f;
}
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    CGRect frame = [tableView frame];
    frame.size.height = 80.0f;
    frame.origin.x = 0.0f;
    frame.origin.y = 0.0f;
    UILabel *view = [[UILabel alloc] initWithFrame:frame];
    [view setBackgroundColor:[UIColor clearColor]];
    [view setTextColor:[UIColor whiteColor]];
    [view setFont:[UIFont systemFontOfSize:16.0f]];
    [view setTextAlignment:NSTextAlignmentCenter];
    [view setBaselineAdjustment:UIBaselineAdjustmentAlignCenters];
    [view setText:NSLocalizedString(@"U2", nil)];
    return view;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return [_modelData usersCount];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    ZChatUserCell *cell = (ZChatUserCell *)[tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    ZChatUser *user = [_modelData userAtIndexPath:indexPath];
    [[cell name] setText:[user userName]];
    UIImage *image = [user userAvatar];
    if (image != nil)
    {
        [[cell avatar] setImage:image];
    }
    [[cell isConnected] setOn:[user isConnected]];
    return cell;
}
#pragma mark - DELEGATE: Model Data
- (void)addUserAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [_tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}
- (void)updateUserAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    NSArray *visibleRows = [_tableView indexPathsForVisibleRows];
    if ([visibleRows containsObject:indexPath])
    {
        [_tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}
@end
