//
//  MessageViewController.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 04.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import "MessageViewController.h"
#import "SWRevealViewController.h"
#import "ModelData.h"

#define LOCAL_LEVEL_0 0
#define LOCAL_LEVEL_1 1
#define LOCAL_LEVEL_2 2

@interface MessageViewController () <SWRevealViewControllerDelegate,ModelDataProtocol>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *revealButton;
@end

@implementation MessageViewController
{
    ModelData               *_modelData;
    JSQMessagesBubbleImage  *_outgoingBubbleImageData;
    JSQMessagesBubbleImage  *_incomingBubbleImageData;
}
#pragma mark - VIEW
- (void)awakeFromNib
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super awakeFromNib];
    _modelData = [ModelData sharedModelData];
    JSQMessagesBubbleImageFactory *bubbleFactory = [[JSQMessagesBubbleImageFactory alloc] init];
    _outgoingBubbleImageData = [bubbleFactory outgoingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleLightGrayColor]];
    _incomingBubbleImageData = [bubbleFactory incomingMessagesBubbleImageWithColor:[UIColor jsq_messageBubbleBlueColor]];
}
- (void)viewDidLoad
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super viewDidLoad];
    SWRevealViewController *revealViewController = [self revealViewController];
    if (revealViewController != nil)
    {
        [_revealButton setTarget: revealViewController];
        [_revealButton setAction: @selector(revealToggle:)];
        [[[self navigationController] navigationBar] addGestureRecognizer:[revealViewController panGestureRecognizer]];
        [[[self navigationController] navigationBar] addGestureRecognizer:[revealViewController tapGestureRecognizer]];
        [revealViewController setDelegate:self];
    }
    [_modelData setDelegate:self];
}
- (void)dealloc
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    _modelData = nil;
}
- (void)didReceiveMemoryWarning
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super didReceiveMemoryWarning];
}
#pragma mark - ROTATION
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskLandscape);
}
- (BOOL)shouldAutorotate
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return YES;
}
#pragma mark - DELEGATE: SWRevealViewController
- (void)revealController:(SWRevealViewController *)revealController willMoveToPosition:(FrontViewPosition)position
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if (position == FrontViewPositionRight)
    {
//        [self searchBarCancelButtonClicked:_searchBar];
    }
}
#pragma mark - JSQMessagesViewController method overrides
- (void)didPressSendButton:(UIButton *)button
           withMessageText:(NSString *)text
                  senderId:(NSString *)senderId
         senderDisplayName:(NSString *)senderDisplayName
                      date:(NSDate *)date
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    JSQMessage *message = [[JSQMessage alloc] initWithSenderId:senderId
                                             senderDisplayName:senderDisplayName
                                                          date:date
                                                          text:text];
    __weak typeof(self) weakSelf = self;
    [_modelData sendMessage:message withCompletion:^(BOOL success, NSError *error) {
        if (success)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf finishSendingMessageAnimated:YES];
            });
        }
    }];
}
- (void)didPressAccessoryButton:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [[[[self inputToolbar] contentView] textView] resignFirstResponder];
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"S0", nil)
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
//    UIFont *font = [UIFont fontWithName:@"Oswald-Regular" size:18.0f];
//    NSAttributedString *title = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"S0", nil) attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor blackColor]}];
//    [alert setValue:title forKey:@"attributedTitle"];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
    {
        UIPopoverPresentationController *popover = [alert popoverPresentationController];
        [popover setSourceView:[self inputToolbar]];
        [popover setSourceRect:[[self inputToolbar] bounds]];
    }
    UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"CANCEL", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {}];
    [defaultAction setValue:[UIColor redColor] forKey:@"titleTextColor"];
    [alert addAction:defaultAction];
//    __weak typeof(self) weakSelf = self;
//    UIColor *color = [UIColor colorWithRed:0.0f green:122.0f/255.0f blue:1.0f alpha:1.0f];
/*
    for (NSString *str in [[sortBy allKeys] reverseObjectEnumerator])
    {
        UIAlertAction* _action = [UIAlertAction actionWithTitle:str style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
#if DEBUG >= LOCAL_LEVEL_1
            NSLog(@"ACTION=%@",[action debugDescription]);
#endif
            __strong typeof(self) strongSelf = weakSelf;
            if (![[strongSelf->_sortByButton titleForState:UIControlStateNormal] isEqualToString:[action title]])
            {
                [strongSelf->_sortByButton setTitle:[action title] forState:UIControlStateNormal];
                [strongSelf fetchVideos:YES isFirstFetch:NO];
            }
        }];
        [_action setValue:color forKey:@"titleTextColor"];
        [alert addAction:_action];
    }
*/
    [self presentViewController:alert animated:YES completion:nil];
/*
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Media messages"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                         destructiveButtonTitle:nil
                                              otherButtonTitles:@"Send photo", @"Send location", @"Send video", nil];
    
    [sheet showFromToolbar:[self inputToolbar]];
*/
}
/*
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        [self.inputToolbar.contentView.textView becomeFirstResponder];
        return;
    }
    
    switch (buttonIndex) {
        case 0:
            [self.demoData addPhotoMediaMessage];
            break;
            
        case 1:
        {
            __weak UICollectionView *weakView = self.collectionView;
            
            [self.demoData addLocationMediaMessageCompletion:^{
                [weakView reloadData];
            }];
        }
            break;
            
        case 2:
            [self.demoData addVideoMediaMessage];
            break;
    }
    
    [JSQSystemSoundPlayer jsq_playMessageSentSound];
    
    [self finishSendingMessageAnimated:YES];
}
*/

#pragma mark - DATA SOURCE: JSQMessages CollectionView

- (id<JSQMessageData>)collectionView:(JSQMessagesCollectionView *)collectionView messageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return [_modelData messageAtIndexPath:indexPath];
}
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didDeleteMessageAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [_modelData deleteMessageAtIndexPath:indexPath];
}

- (id<JSQMessageBubbleImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView messageBubbleImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    JSQMessage *message = [_modelData messageAtIndexPath:indexPath];
    if ((message != nil) && [[message senderId] isEqualToString:[self senderId]])
    {
        return _outgoingBubbleImageData;
    }
    else
    {
        return _incomingBubbleImageData;
    }
}
- (id<JSQMessageAvatarImageDataSource>)collectionView:(JSQMessagesCollectionView *)collectionView avatarImageDataForItemAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    /**
     *  Return `nil` here if you do not want avatars.
     *  If you do return `nil`, be sure to do the following in `viewDidLoad`:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero;
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero;
     *
     *  It is possible to have only outgoing avatars or only incoming avatars, too.
     */
    
    /**
     *  Return your previously created avatar image data objects.
     *
     *  Note: these the avatars will be sized according to these values:
     *
     *  self.collectionView.collectionViewLayout.incomingAvatarViewSize
     *  self.collectionView.collectionViewLayout.outgoingAvatarViewSize
     *
     *  Override the defaults in `viewDidLoad`
     */
    JSQMessage *message = [_modelData messageAtIndexPath:indexPath];
    if (message == nil)
    {
        return nil;
    }
/*
    if ([[message senderId] isEqualToString:[self senderId]])
    {
        if (![NSUserDefaults outgoingAvatarSetting]) {
            return nil;
        }
    }
    else {
        if (![NSUserDefaults incomingAvatarSetting]) {
            return nil;
        }
    }
    return [self.demoData.avatars objectForKey:message.senderId];
*/
    return [_modelData avatarForMessageSender:message];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    JSQMessage *message = [_modelData messageAtIndexPath:indexPath];
    if (message == nil)
    {
        return nil;
    }
    return [[JSQMessagesTimestampFormatter sharedFormatter] attributedTimestampForDate:[message date]];
}

- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    JSQMessage *message = [_modelData messageAtIndexPath:indexPath];
    if ((message != nil) && [[message senderId] isEqualToString:[self senderId]])
    {
        return nil;
    }
    JSQMessage *previousMessage = [_modelData previousMessageAtIndexPath:indexPath];
    if ((previousMessage != nil) && (message != nil) && [[previousMessage senderId] isEqualToString:[message senderId]])
    {
        return nil;
    }
    return [[NSAttributedString alloc] initWithString:message.senderDisplayName];
}
- (NSAttributedString *)collectionView:(JSQMessagesCollectionView *)collectionView attributedTextForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return nil;
}
#pragma mark - DATASOURCE: UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return [_modelData messagesCount];
}
- (UICollectionViewCell *)collectionView:(JSQMessagesCollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    /**
     *  Configure almost *anything* on the cell
     *
     *  Text colors, label text, label colors, etc.
     *
     *
     *  DO NOT set `cell.textView.font` !
     *  Instead, you need to set `self.collectionView.collectionViewLayout.messageBubbleFont` to the font you want in `viewDidLoad`
     *
     *
     *  DO NOT manipulate cell layout information!
     *  Instead, override the properties you want on `self.collectionView.collectionViewLayout` from `viewDidLoad`
     */
    
    JSQMessage *message = [_modelData messageAtIndexPath:indexPath];
    if ((message != nil) && ![message isMediaMessage])
    {
        if ([[message senderId] isEqualToString:[self senderId]])
        {
            [[cell textView] setTextColor:[UIColor blackColor]];
        }
        else
        {
            [[cell textView] setTextColor:[UIColor whiteColor]];
        }
        [[cell textView] setLinkTextAttributes:@{ NSForegroundColorAttributeName : [[cell textView] textColor],
                                              NSUnderlineStyleAttributeName : @(NSUnderlineStyleSingle | NSUnderlinePatternSolid) }];
    }
    return cell;
}
#pragma mark - DELEGATE: UICollectionView
#pragma mark - Custom menu items
- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if (action == @selector(customAction:))
    {
        return YES;
    }
    
    return [super collectionView:collectionView canPerformAction:action forItemAtIndexPath:indexPath withSender:sender];
}
- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if (action == @selector(customAction:))
    {
        [self customAction:sender];
        return;
    }
    [super collectionView:collectionView performAction:action forItemAtIndexPath:indexPath withSender:sender];
}
- (void)customAction:(id)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"Custom action received! Sender: %@", sender);
#endif
}
#pragma mark - DELEGATE: JSQMessages collection view flow layout
#pragma mark - Adjusting cell label heights
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForMessageBubbleTopLabelAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    JSQMessage *message = [_modelData messageAtIndexPath:indexPath];
    if ((message == nil) || [[message senderId] isEqualToString:[self senderId]])
    {
        return 0.0f;
    }
    JSQMessage *previousMessage = [_modelData previousMessageAtIndexPath:indexPath];
    if ((previousMessage != nil) && [[previousMessage senderId] isEqualToString:[message senderId]])
    {
        return 0.0f;
    }
    return kJSQMessagesCollectionViewCellLabelHeightDefault;
}
- (CGFloat)collectionView:(JSQMessagesCollectionView *)collectionView
                   layout:(JSQMessagesCollectionViewFlowLayout *)collectionViewLayout heightForCellBottomLabelAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return 0.0f;
}
#pragma mark - Responding to collection view tap events
- (void)collectionView:(JSQMessagesCollectionView *)collectionView
                header:(JSQMessagesLoadEarlierHeaderView *)headerView didTapLoadEarlierMessagesButton:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"Load earlier messages!");
#endif
}
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapAvatarImageView:(UIImageView *)avatarImageView atIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"Tapped avatar!");
#endif
}
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapMessageBubbleAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"Tapped message bubble!");
#endif
}
- (void)collectionView:(JSQMessagesCollectionView *)collectionView didTapCellAtIndexPath:(NSIndexPath *)indexPath touchLocation:(CGPoint)touchLocation
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"Tapped cell at %@!", NSStringFromCGPoint(touchLocation));
#endif
}
#pragma mark - JSQMessagesComposerTextViewPasteDelegate methods
- (BOOL)composerTextView:(JSQMessagesComposerTextView *)textView shouldPasteWithSender:(id)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if ([[UIPasteboard generalPasteboard] image])
    {
// If there's an image in the pasteboard, construct a media item with that image and `send` it.
        JSQPhotoMediaItem *item = [[JSQPhotoMediaItem alloc] initWithImage:[[UIPasteboard generalPasteboard] image]];
        JSQMessage *message = [[JSQMessage alloc] initWithSenderId:[self senderId]
                                                 senderDisplayName:[self senderDisplayName]
                                                              date:[NSDate date]
                                                             media:item];
        __weak typeof(self) weakSelf = self;
        [_modelData sendMessage:message withCompletion:^(BOOL success, NSError *error) {
            if (success)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf finishSendingMessageAnimated:YES];
                });
            }
        }];
        return NO;
    }
    return YES;
}
#pragma mark - DELEGATE: ModelData
- (void)receiveMessage:(JSQMessage *)message
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
}
@end
