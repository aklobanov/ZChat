//
//  PhotoCell.h
//  ZChat
//
//  Created by ALEXEY LOBANOV on 13.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotoCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *checkMark;
@property (weak, nonatomic) IBOutlet UIButton *addButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (nonatomic, copy) NSString *representedAssetIdentifier;
@end
