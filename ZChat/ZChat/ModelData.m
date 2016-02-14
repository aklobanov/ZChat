//
//  ModelData.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 04.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import "ModelData.h"
#import <Realm/Realm.h>
#import <CoreLocation/CoreLocation.h>
#import "JSQMediaItem.h"
#import "JSQPhotoMediaItem.h"
#import "JSQVideoMediaItem.h"
#import "JSQLocationMediaItem.h"
#import <ObjCZMQiOS/ObjCZMQ.h>
#import <libkern/OSAtomic.h>
#include <arpa/inet.h>
#import "NSError+Report.h"

#define LOCAL_LEVEL_0 0
#define LOCAL_LEVEL_1 1
#define LOCAL_LEVEL_2 1

@interface Message : RLMObject
@property NSString          *senderId;
@property NSDate            *date;
@property NSString          *text;
@property NSData            *photo;
@property NSString          *video;
@property CLLocationDegrees latitude;
@property CLLocationDegrees longitude;
@property BOOL              isOutgoing;
@end
// This protocol enables typed collections. i.e.:
// RLMArray<Message>
RLM_ARRAY_TYPE(Message)
@implementation Message
+ (nonnull NSArray<NSString *> *)indexedProperties
{
    return @[@"senderId",@"date"];
}
@end

@interface User : RLMObject
@property NSString    *userId;
@property NSString    *name;
@property NSData      *avatar;
@property NSString    *address;
@property NSInteger   port;
@property BOOL        connected;
@end
RLM_ARRAY_TYPE(User)

@implementation User
+ (nullable NSString *)primaryKey
{
    return @"userId";
}
+ (nonnull NSArray<NSString *> *)indexedProperties
{
    return @[@"name",@"connected"];
}
@end

@interface ZChatUser()
{
@public
    NSString    *_userId;
    NSString    *_userName;
    UIImage     *_userAvatar;
    NSString    *_address;
    NSInteger   _port;
    BOOL        _isConnected;
}
@end
@implementation ZChatUser
@synthesize userId      = _userId;
@synthesize userName    = _userName;
@synthesize userAvatar  = _userAvatar;
@synthesize address     = _address;
@synthesize port        = _port;
@synthesize isConnected = _isConnected;
- (instancetype)initWithUser:(User *)user
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    self = [super init];
    if (self != nil)
    {
        _userId = [user userId];
        _userName = [user name];
        NSData *data = [user avatar];
        _userAvatar = [UIImage imageWithData:data];
        _address = [user address];
        _port = [user port];
        _isConnected = [user connected];
    }
    return self;
}
- (void)setUserAvatar:(UIImage *)userAvatar
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    _userAvatar = userAvatar;
    User *user = [User objectForPrimaryKey:_userId];
    NSData *data = UIImagePNGRepresentation(userAvatar);
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    [user setAvatar:data];
//    [realm addOrUpdateObject:user];
    [realm commitWriteTransaction];
}
@end
@implementation Me
- (instancetype)init
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    self = [super init];
    if (self != nil)
    {
        NSString *uuid = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
        User *user = [User objectForPrimaryKey:uuid];
        if (user != nil)
        {
            self = [super initWithUser:user];
        }
        else
        {
            _userId = uuid;
            _userName = nil;
            _userAvatar = nil;
            _address = @"*";
            _port = 5555;
            _isConnected = NO;
            user = [User new];
            [user setUserId:uuid];
            [user setAddress:_address];
            [user setPort:_port];
            [user setConnected:_isConnected];
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            [realm addObject:user];
            [realm commitWriteTransaction];
        }
    }
    return self;
}
- (void)setUserName:(NSString *)userName
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if ((_userName == nil) || ![_userName isEqualToString:userName])
    {
        _userName = userName;
        User *user = [User objectForPrimaryKey:_userId];
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [user setName:userName];
//        [realm addOrUpdateObject:user];
        [realm commitWriteTransaction];
    }
}
@end

@interface ModelData() <NSNetServiceBrowserDelegate,NSNetServiceDelegate>
@end
@implementation ModelData
{
    RLMRealm                        *_realm;
    NSNetService                    *_netService;
    NSNetServiceBrowser             *_netServiceBrowser;
    NSMutableArray <NSNetService *> *_zchats;
    ZMQContext                      *_context;
    dispatch_queue_t                _inqueue;
    dispatch_queue_t                _outqueue;
    ZMQSocket                       *_inSocket;
    ZMQSocket                       *_outSocket;
    __block volatile uint32_t       _stopReceiveMessages;
}
@synthesize delegateMessages = _delegateMessages;
@synthesize delegateUsers = _delegateUsers;
@synthesize me = _me;

static NSString *txtUserIdKey = @"UUID";
//static NSString *txtUserAvatarKey = @"AVATAR";

#pragma mark - INIT
+ (ModelData *)sharedModelData
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    static ModelData *_modelData;
    static dispatch_once_t onceModelData;
    dispatch_once(&onceModelData, ^{
        _modelData = [ModelData new];
    });
    return _modelData;
}
- (instancetype)init
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    self = [super init];
    if (self != nil)
    {
        _realm = [RLMRealm defaultRealm];
        _me = [Me new];
        _zchats = [NSMutableArray new];
        _netServiceBrowser = [NSNetServiceBrowser new];
        [_netServiceBrowser setDelegate:self];
        [_netServiceBrowser searchForServicesOfType:@"_zchat._tcp." inDomain:@""];
        _context = [ZMQContext new];
        _stopReceiveMessages = 0;
    }
    return self;
}
- (void)dealloc
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if (_netService != nil)
    {
        [_netService stop];
        _netService = nil;
    }
    if (_netServiceBrowser != nil)
    {
        [_netServiceBrowser stop];
        _netServiceBrowser = nil;
    }
    if (_inSocket != nil)
    {
        [_inSocket closeSyncWithError:NULL];
        _inSocket = nil;
    }
    _inqueue = NULL;
    if (_outSocket != nil)
    {
        [_outSocket closeSyncWithError:NULL];
        _outSocket = nil;
    }
    _outqueue = NULL;
    if (_context != nil)
    {
        [_context terminate];
    }
    _realm = nil;
    _zchats = nil;
}
#pragma mark - DATASOURCE: JSQMessageViewController
- (void)clearMessages
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [_realm beginWriteTransaction];
    [_realm deleteObjects:[Message allObjects]];
    [_realm commitWriteTransaction];
}
- (NSInteger)messagesCount
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    RLMResults<Message *> *messages = [Message allObjects];
    return [messages count];
}
- (JSQMessage *)messageWithRealmMessage:(Message *)msg
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    JSQMessage *message = nil;
    User *user = [User objectForPrimaryKey:[msg senderId]];
    NSString *senderDisplayName = [user name];
    if ([msg text] != nil)
    {
        message = [[JSQMessage alloc] initWithSenderId:[msg senderId] senderDisplayName:senderDisplayName date:[msg date] text:[msg text]];
    }
    else
    {
        JSQMediaItem *item;
        if ([msg photo] != nil)
        {
            UIImage *image = [UIImage imageWithData:[msg photo]];
            item = [[JSQPhotoMediaItem alloc] initWithImage:image];
            [item setAppliesMediaViewMaskAsOutgoing:[msg isOutgoing]];
        }
        else
        {
            if ([msg video] != nil)
            {
                NSURL *url = [NSURL URLWithString:[msg video]];
                item = [[JSQVideoMediaItem alloc] initWithFileURL:url isReadyToPlay:NO];
                [item setAppliesMediaViewMaskAsOutgoing:[msg isOutgoing]];
            }
            else
            {
                CLLocation *location = [[CLLocation alloc] initWithLatitude:[msg latitude] longitude:[msg longitude]];
                item = [[JSQLocationMediaItem alloc] initWithLocation:location];
                [item setAppliesMediaViewMaskAsOutgoing:[msg isOutgoing]];
            }
        }
        message = [[JSQMessage alloc] initWithSenderId:[msg senderId] senderDisplayName:senderDisplayName date:[msg date] media:item];
    }
    return message;
}
- (JSQMessage *)messageAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    RLMResults<Message *> *messages = [Message allObjects];
    JSQMessage *message = nil;
    if ([indexPath item] < [messages count])
    {
        Message *msg = [messages objectAtIndex:[indexPath item]];
        if (msg != nil)
        {
            message = [self messageWithRealmMessage:msg];
        }
    }
    return message;
}
- (JSQMessage *)previousMessageAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    RLMResults<Message *> *messages = [Message allObjects];
    JSQMessage *message = nil;
    NSInteger i = [indexPath item] - 1;
    if ((i < [messages count]) && (i >= 0))
    {
        Message *msg = [messages objectAtIndex:i];
        if (msg != nil)
        {
            message = [self messageWithRealmMessage:msg];
        }
    }
    return message;
}
- (void)deleteMessageAtIndexPath:(NSIndexPath *)indexPath;
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    RLMResults<Message *> *messages = [Message allObjects];
    Message *msg = [messages objectAtIndex:[indexPath item]];
    [_realm beginWriteTransaction];
    [_realm deleteObject:msg];
    [_realm commitWriteTransaction];
}
- (id<JSQMessageAvatarImageDataSource>)avatarForMessageSender:(JSQMessage *)message
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return nil;
}
- (Message *)realmMessageWithMessage:(JSQMessage *)message isOutgoing:(BOOL)outgoing
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    Message *msg = [Message new];
    [msg setSenderId:[message senderId]];
    [msg setDate:[message date]];
    [msg setText:[message text]];
    [msg setIsOutgoing:outgoing];
    if ([message isMediaMessage])
    {
        if ([[message media] isKindOfClass:[JSQPhotoMediaItem class]])
        {
            [msg setPhoto:UIImageJPEGRepresentation([(JSQPhotoMediaItem *)[message media] image], 1.0f)];
        }
        else
        {
            if ([[message media] isKindOfClass:[JSQVideoMediaItem class]])
            {
                [msg setVideo:[[(JSQVideoMediaItem *)[message media] fileURL] absoluteString]];
            }
            else
            {
                [msg setLatitude:[(JSQLocationMediaItem *)[message media] coordinate].latitude];
                [msg setLongitude:[(JSQLocationMediaItem *)[message media] coordinate].longitude];
            }
        }
    }
    return msg;
}
#pragma mark - DATASOURCE: ZChat Users
- (void)clearUsers
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [_realm beginWriteTransaction];
    [_realm deleteObjects:[User objectsWhere:@"userId != %@",[_me userId]]];
    [_realm commitWriteTransaction];
}
- (NSInteger)usersCount
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    RLMResults<User *> *users = [User objectsWhere:@"userId != %@",[_me userId]];
    return [users count];
}
- (ZChatUser *)userAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    RLMResults<User *> *users = [User objectsWhere:@"userId != %@",[_me userId]];
    ZChatUser *zchatUser = nil;
    if ([indexPath row] < [users count])
    {
        User *user = [users objectAtIndex:[indexPath row]];
        if (user != nil)
        {
            zchatUser = [[ZChatUser alloc] initWithUser:user];
        }
    }
    return zchatUser;
}
- (NSIndexPath *)indexPathForUser:(User *)user
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    RLMResults<User *> *users = [User objectsWhere:@"userId != %@",[_me userId]];
    NSInteger i = [users indexOfObject:user];
    if (i == NSNotFound) return nil;
    return [NSIndexPath indexPathForRow:i inSection:0];
}
- (void)connectUserAtIndexPath:(NSIndexPath *)indexPath withCompletion:(void (^)(BOOL, NSError *))completion
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
}
- (void)disconnectUserAtIndexPath:(NSIndexPath *)indexPath withCompletion:(void (^)(BOOL, NSError *))completion
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
}
#pragma mark - Communication
- (void)stopReceiveMessages
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    OSAtomicOr32(1, &(_stopReceiveMessages));
}
- (void)startReceiveMessages
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if (_inqueue == nil)
    {
        _inqueue = dispatch_queue_create("_zmq_in_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    if (_inSocket == nil)
    {
        ZMQError *error = nil;
        _inSocket = [_context socketWithType:kZMQSocketRep onQueue:_inqueue];
        if (![_inSocket bindSyncWithEndPoint:[ZMQEndPoint tcpEndPointWithAddress:@"*" withPort:5555] withError:&error])
        {
            @throw [ZMQException exceptionWithError:error];
        }
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        __strong typeof(self) strongSelf = weakSelf;
        ZMQError *error = nil;
        BOOL ret;
        while ((ret = [strongSelf->_inSocket pollWithTimeout:-1 withError:&error]))
        {
            if (OSAtomicOr32(0, &(strongSelf->_stopReceiveMessages)) != 0)
            {
                break;
            }
            [strongSelf->_inSocket receiveAsyncWithCompletion:^(NSData *data, ZMQError *error) {
                if (data != nil)
                {
#if DEBUG >= LOCAL_LEVEL_2
                    NSLog(@"RECEIVED DATA=%@", [data debugDescription]);
#endif
                    JSQMessage *message = [NSKeyedUnarchiver unarchiveObjectWithData:data];
#if DEBUG >= LOCAL_LEVEL_2
                    NSLog(@"RECEIVED MESSAGE=%@", [message debugDescription]);
#endif
                    if ((message != nil) && ![[message senderId] isEqualToString:[[[UIDevice currentDevice] identifierForVendor] UUIDString]])
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            __strong typeof(self) strongSelf = weakSelf;
                            Message *msg = [strongSelf realmMessageWithMessage:message isOutgoing:NO];
                            NSError *error = nil;
                            if (![strongSelf->_realm transactionWithBlock:^{
                                [strongSelf->_realm addObject:msg];
                                if (strongSelf->_delegateMessages != nil)
                                {
                                    [strongSelf->_delegateMessages receiveMessage:message];
                                }
                            } error:&error])
                            {
                                [error report];
                            }
                        });
                    }
                }
            }];
        }
        if (!ret)
        {
            [error report];
        }
        if (_inSocket != nil)
        {
            if ([_inSocket closeSyncWithError:&error])
            {
                _inSocket = nil;
                _inqueue = nil;
            }
            else
            {
                [error report];
            }
        }
    });
}
typedef NS_ENUM(char,MessageType)
{
    kMessageAcknowlegment = -1,
    kMessageSystem = 0,
    kMessageText,
    kMessagePhoto,
    kMessageVideo,
    kMessageLocation,
    kMessageOther
};
- (NSData *)zmqDataFromMessage:(JSQMessage *)message
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    uuid_t _uuid;
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:[message senderId]];
    [uuid getUUIDBytes:_uuid];
    NSMutableData *data = [NSMutableData dataWithBytes:_uuid length:sizeof(uuid_t)];
    NSTimeInterval _date = [[message date] timeIntervalSince1970];
    [data appendBytes:&_date length:sizeof(NSTimeInterval)];
    char messageType = kMessageOther;
    if ([message isMediaMessage])
    {
        if ([[message media] isKindOfClass:[JSQPhotoMediaItem class]])
        {
            messageType = kMessagePhoto;
            [data appendBytes:&messageType length:1];
            [data appendData:UIImageJPEGRepresentation([(JSQPhotoMediaItem *)[message media] image], 1.0f)];
        }
        else
        {
            if ([[message media] isKindOfClass:[JSQVideoMediaItem class]])
            {
                messageType = kMessageVideo;
                [data appendBytes:&messageType length:1];
                const char *str = [[[(JSQVideoMediaItem *)[message media] fileURL] absoluteString] cStringUsingEncoding:NSUTF8StringEncoding];
                [data appendBytes:str length:strlen(str)];
            }
            else
            {
                if ([[message media] isKindOfClass:[JSQLocationMediaItem class]])
                {
                    messageType = kMessageLocation;
                    [data appendBytes:&messageType length:1];
                    CLLocationCoordinate2D coordinate = [(JSQLocationMediaItem *)[message media] coordinate];
                    [data appendBytes:&coordinate length:sizeof(CLLocationCoordinate2D)];
                }
                else
                {
                    messageType = kMessageOther;
                    [data appendBytes:&messageType length:1];
                    NSData *mediaData = [NSKeyedArchiver archivedDataWithRootObject:[message media]];
                    [data appendData:mediaData];
                }
            }
        }
    }
    else
    {
        messageType = kMessageText;
        [data appendBytes:&messageType length:1];
        const char *str = [[message text] cStringUsingEncoding:NSUTF8StringEncoding];
        [data appendBytes:str length:strlen(str)];
    }
    return data;
}
- (void)sendMessage:(JSQMessage *)message withCompletion:(void (^)(BOOL success,NSError *error))completion
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if (_outqueue == nil)
    {
        _outqueue = dispatch_queue_create("_zmq_out_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    if (_outSocket == nil)
    {
        _outSocket = [_context socketWithType:kZMQSocketReq onQueue:_outqueue];
        ZMQError *error = nil;
        if (![_outSocket connectSyncWithEndPoint:[ZMQEndPoint tcpEndPointWithAddress:@"192.168.1.3" withPort:5556] withError:&error])
        {
            [error report];
            return;
        }
    }
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:message];
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"DATA TO SEND=%@", [data debugDescription]);
#endif
    __weak typeof(self) weakSelf = self;
    [_outSocket sendAsyncData:data withPartSize:1024 withCompletion:^(BOOL success, ZMQError *error) {
        if (success)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(self) strongSelf = weakSelf;
                Message *msg = [strongSelf realmMessageWithMessage:message isOutgoing:YES];
                NSError *error = nil;
                if (![strongSelf->_realm transactionWithBlock:^{
                    [strongSelf->_realm addObject:msg];
                    if (completion != NULL)
                    {
                        completion(YES,nil);
                    }
                } error:&error])
                {
                    if (completion != NULL)
                    {
                        completion(NO,error);
                    }
                }
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion != NULL)
                {
                    completion(NO,error);
                }
            });
        }
    }];
}
- (void)publishMessage:(JSQMessage *)message withCompletion:(void (^)(BOOL success,NSError *error))completion
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if (_outqueue == nil)
    {
        _outqueue = dispatch_queue_create("_zmq_out_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    if (_outSocket == nil)
    {
        _outSocket = [_context socketWithType:kZMQSocketReq onQueue:_outqueue];
        ZMQError *error = nil;
        if (![_outSocket bindSyncWithEndPoint:[ZMQEndPoint tcpEndPointWithAddress:@"*" withPort:[_me port]] withError:&error])
        {
            [error report];
            return;
        }
    }
//    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:message];
    NSData *data = [self zmqDataFromMessage:message];
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"DATA TO SEND=%@", [data debugDescription]);
#endif
    __weak typeof(self) weakSelf = self;
    [_outSocket sendAsyncData:data withPartSize:1024 withCompletion:^(BOOL success, ZMQError *error) {
        if (success)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(self) strongSelf = weakSelf;
                Message *msg = [strongSelf realmMessageWithMessage:message isOutgoing:YES];
                NSError *error = nil;
                if (![strongSelf->_realm transactionWithBlock:^{
                    [strongSelf->_realm addObject:msg];
                    if (completion != NULL)
                    {
                        completion(YES,nil);
                    }
                } error:&error])
                {
                    if (completion != NULL)
                    {
                        completion(NO,error);
                    }
                }
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (completion != NULL)
                {
                    completion(NO,error);
                }
            });
        }
    }];
}
- (void)publishMyselfWithName:(NSString *)name
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    _netService = [[NSNetService alloc] initWithDomain:@"" type:@"_zchat._tcp." name:name port:(int)[_me port]];
    [_netService setDelegate:self];
    uuid_t uuid;
    [[[UIDevice currentDevice] identifierForVendor] getUUIDBytes:uuid];
    NSDictionary *dic = @{txtUserIdKey:[NSData dataWithBytes:uuid length:sizeof(uuid_t)]};
/*
    if ([_me userAvatar] != nil)
    {
        CGSize size = CGSizeMake(25.0f, 25.0f);
        UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
        CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
        [[_me userAvatar] drawInRect:rect];
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        NSData *imageData = [UIImageJPEGRepresentation(image, 0.5f) base64EncodedDataWithOptions:0];
        dic = @{txtUserIdKey:[NSData dataWithBytes:uuid length:sizeof(uuid_t)],txtUserAvatarKey:imageData};
    }
    else
    {
        dic = @{txtUserIdKey:[NSData dataWithBytes:uuid length:sizeof(uuid_t)]};
    }
*/
    NSData *data = [NSNetService dataFromTXTRecordDictionary:dic];
    if ([_netService setTXTRecordData:data])
        [_netService publish];
}
#pragma mark - DELEGATE: NetServiceBrowser
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"FOUND DOMAIN=%@ IS MORE=%li",domainString,(long)moreComing);
#endif
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveDomain:(NSString *)domainString moreComing:(BOOL)moreComing
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"REMOVE DOMAIN=%@ IS MORE=%li",domainString,(long)moreComing);
#endif
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary<NSString *,NSNumber *> *)errorDict
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"NOT SEARCH=%@",[errorDict debugDescription]);
#endif
    [browser stop];
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"FOUND SERVICE=(%@ %@.%@%@:%li) IS MORE=%li",[[service addresses] debugDescription],[service name],[service type],[service domain],(long)[service port],(long)moreComing);
#endif
    if (![[service name] isEqualToString:[_me userName]])
    {
        [_zchats addObject:service];
        [service setDelegate:self];
        [service resolveWithTimeout:0.0];
    }
}
- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"REMOVE SERVICE=(%@ %@.%@%@:%li) IS MORE=%li",[[service addresses] debugDescription],[service name],[service type],[service domain],(long)[service port],(long)moreComing);
#endif
    [_zchats removeObject:service];
    NSData *txtRecord = [service TXTRecordData];
    if (txtRecord != nil)
    {
        NSDictionary *dic = [NSNetService dictionaryFromTXTRecordData:txtRecord];
        if (dic != nil)
        {
            NSData *txtData = dic[txtUserIdKey];
            if (txtData != nil)
            {
                NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:[txtData bytes]];
                NSString *userId = [uuid UUIDString];
#if DEBUG >= LOCAL_LEVEL_2
                NSLog(@"SERVICE UUID=%@", userId);
#endif
                __weak typeof(self) weaskSelf = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(self) strongSelf = weaskSelf;
                    User *user = [User objectForPrimaryKey:userId];
                    if (user != nil)
                    {
                        NSIndexPath *indexPath = [strongSelf indexPathForUser:user];
                        if (indexPath != nil)
                        {
                            [strongSelf disconnectUserAtIndexPath:indexPath withCompletion:^(BOOL success, NSError *error) {
                                if (success)
                                {
                                    if (strongSelf->_delegateUsers != nil)
                                    {
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [strongSelf->_delegateUsers updateUserAtIndexPath:indexPath];
                                        });
                                   }
                                }
                                else
                                {
                                    [error report];
                                }
                            }];
                        }
                    }
                });
            }
        }
    }
}
- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
}
/*
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)browser
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
}
- (void)netServiceWillResolve:(NSNetService *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
}
*/
- (void)netServiceDidResolveAddress:(NSNetService *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [sender stop];
    for (NSData* data in [sender addresses])
    {
        struct sockaddr_in* socketAddress = (struct sockaddr_in*) [data bytes];
        if (socketAddress->sin_family == AF_INET)
        {
            const char* addressStr = inet_ntoa(socketAddress->sin_addr);
            if (addressStr != NULL)
            {
                NSString *address = [NSString stringWithUTF8String:addressStr];
#if DEBUG >= LOCAL_LEVEL_2
                NSLog(@"SERVICE ADDRESS=%@:%li", address, (long)[sender port]);
#endif
                NSData *txtRecord = [sender TXTRecordData];
                if (txtRecord != nil)
                {
                    NSDictionary *dic = [NSNetService dictionaryFromTXTRecordData:txtRecord];
                    if (dic != nil)
                    {
                        NSData *txtData = dic[txtUserIdKey];
                        if (txtData != nil)
                        {
                            NSUUID *uuid = [[NSUUID alloc] initWithUUIDBytes:[txtData bytes]];
                            NSString *userId = [uuid UUIDString];
#if DEBUG >= LOCAL_LEVEL_2
                            NSLog(@"SERVICE UUID=%@", userId);
#endif
/*
                            NSData *avatarData = nil;
                            txtData = dic[txtUserAvatarKey];
                            if (txtData != nil)
                            {
                                avatarData = [[NSData alloc] initWithBase64EncodedData:txtData options:0];
                            }
*/
                            User *user = [User objectForPrimaryKey:userId];
                            if (user == nil)
                            {
                                user = [User new];
                                [user setUserId:userId];
                                [user setName:[sender name]];
                                [user setAddress:address];
                                [user setPort:[sender port]];
//                                [user setAvatar:avatarData];
                                [user setConnected:NO];
                                [_realm beginWriteTransaction];
                                [_realm addObject:user];
                                [_realm commitWriteTransaction];
                                if (_delegateUsers != nil)
                                {
                                    __weak typeof(self) weaskSelf = self;
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        __strong typeof(self) strongSelf = weaskSelf;
                                        NSIndexPath *indexPath = [strongSelf indexPathForUser:user];
                                        if (indexPath != nil)
                                        {
                                            [strongSelf->_delegateUsers addUserAtIndexPath:indexPath];
                                        }
                                    });
                                }
                            }
                            else
                            {
                                [_realm beginWriteTransaction];
                                [user setName:[sender name]];
                                [user setAddress:address];
                                [user setPort:[sender port]];
/*
                                if (avatarData != nil)
                                {
                                    [user setAvatar:avatarData];
                                }
*/
//                                [_realm addOrUpdateObject:user];
                                [_realm commitWriteTransaction];
                                if (_delegateUsers != nil)
                                {
                                    __weak typeof(self) weaskSelf = self;
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        __strong typeof(self) strongSelf = weaskSelf;
                                        NSIndexPath *indexPath = [strongSelf indexPathForUser:user];
                                        if (indexPath != nil)
                                        {
                                            [strongSelf->_delegateUsers updateUserAtIndexPath:indexPath];
                                        }
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary<NSString *,NSNumber *> *)errorDict
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"NOT RESOLVE=%@",[errorDict debugDescription]);
#endif
    [sender stop];
}
- (void)netServiceDidStop:(NSNetService *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
}
- (void)netServiceWillPublish:(NSNetService *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
}
- (void)netServiceDidPublish:(NSNetService *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
}
- (void)netService:(NSNetService *)sender didNotPublish:(NSDictionary<NSString *,NSNumber *> *)errorDict
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"NOT PUBLISH=%@",[errorDict debugDescription]);
#endif
}
- (void)netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *)data
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
}
@end
