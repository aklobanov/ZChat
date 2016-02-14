//
//  ZChatUserCell.h
//  ZChat
//
//  Created by ALEXEY LOBANOV on 14.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZChatUserCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UISwitch *isConnected;

@end
