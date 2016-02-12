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
@protocol ModelDataProtocol <NSObject>
@required
- (void)receiveMessage:(JSQMessage *)message;
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
@property (weak, nonatomic) id <ModelDataProtocol> delegate;
+ (ModelData *)sharedModelData;
// Data Source
- (NSInteger)messagesCount;
- (JSQMessage *)messageAtIndexPath:(NSIndexPath *)indexPath;
- (JSQMessage *)previousMessageAtIndexPath:(NSIndexPath *)indexPath;
- (void)deleteMessageAtIndexPath:(NSIndexPath *)indexPath;
- (id<JSQMessageAvatarImageDataSource>)avatarForMessageSender:(JSQMessage *)message;
// Communication
- (void)sendMessage:(JSQMessage *)message withCompletion:(void (^)(BOOL success,NSError *error))completion;
@end
