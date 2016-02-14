//
//  ZChatUserCell.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 14.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import "ZChatUserCell.h"

@implementation ZChatUserCell
@synthesize avatar      = _avatar;
@synthesize name        = _name;
@synthesize isConnected = _isConnected;
- (void)prepareForReuse
{
    [super prepareForReuse];
    [_avatar setImage:[UIImage imageNamed:@"avatar"]];
    [_name   setText:nil];
    [_isConnected setOn:NO];
}
@end
