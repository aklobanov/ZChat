//
//  ModelData.h
//  ZChat
//
//  Created by ALEXEY LOBANOV on 04.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import <UIKit/UIKit.h>
//#import <CoreLocation/CoreLocation.h>
#import "JSQMessage.h"
#import "JSQMessageAvatarImageDataSource.h"

@interface ZChatUser : NSObject
@property (readonly, nonatomic) NSString  *userId;
@property (readonly, nonatomic) NSString  *userName;
@property (readonly, nonatomic) UIImage   *userAvatar;
@property (readonly, nonatomic) NSString  *address;
@property (readonly, nonatomic) NSInteger port;
@property (readonly, nonatomic) BOOL      isConnected;
- (void)setUserAvatar:(UIImage *)userAvatar;
@end

@interface Me : ZChatUser
- (void)setUserName:(NSString *)userName;
@end

@protocol ModelMessagesProtocol <NSObject>
@required
- (void)receiveMessage:(JSQMessage *)message;
@end
@protocol ModelUsersProtocol <NSObject>
@required
- (void)addUserAtIndexPath:(NSIndexPath *)indexPath;
- (void)updateUserAtIndexPath:(NSIndexPath *)indexPath;
@end

@interface ModelData : NSObject
/*
@property (strong, nonatomic) NSMutableArray *messages;

@property (strong, nonatomic) NSDictionary *avatars;

@property (strong, nonatomic) JSQMessagesBubbleImage *outgoingBubbleImageData;

@property (strong, nonatomic) JSQMessagesBubbleImage *incomingBubbleImageData;

@property (strong, nonatomic) NSDictionary *users;

- (void)addPhotoMediaMessage;

- (void)addLocationMediaMessageCompletion:(JSQLocationMediaItemCompletionBlock)completion;

- (void)addVideoMediaMessage;
*/
@property (strong, nonatomic) Me *me;
@property (weak, nonatomic) id <ModelMessagesProtocol> delegateMessages;
@property (weak, nonatomic) id <ModelUsersProtocol> delegateUsers;
+ (ModelData *)sharedModelData;
// Message Data Source
- (NSInteger)messagesCount;
- (JSQMessage *)messageAtIndexPath:(NSIndexPath *)indexPath;
- (JSQMessage *)previousMessageAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteMessageAtIndexPath:(NSIndexPath *)indexPath;
- (id<JSQMessageAvatarImageDataSource>)avatarForMessageSender:(JSQMessage *)message;
- (void)clearMessages;
// Users data source
- (void)clearUsers;
- (NSInteger)usersCount;
- (ZChatUser *)userAtIndexPath:(NSIndexPath *)indexPath;
- (void)connectUserAtIndexPath:(NSIndexPath *)indexPath withCompletion:(void (^)(BOOL success,NSError *error))completion;
- (void)disconnectUserAtIndexPath:(NSIndexPath *)indexPath withCompletion:(void (^)(BOOL success,NSError *error))completion;
// Communication
- (void)publishMyselfWithName:(NSString *)name;
- (void)publishMessage:(JSQMessage *)message withCompletion:(void (^)(BOOL success,NSError *error))completion;
- (void)sendMessage:(JSQMessage *)message withCompletion:(void (^)(BOOL success,NSError *error))completion;
- (void)stopReceiveMessages;
- (void)startReceiveMessages;
@end
