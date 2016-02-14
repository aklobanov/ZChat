//
//  PhotoCell.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 13.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import "PhotoCell.h"

@implementation PhotoCell
@synthesize imageView = _imageView;
@synthesize checkMark = _checkMark;
@synthesize addButton = _addButton;
@synthesize editButton = _editButton;
@synthesize representedAssetIdentifier = _representedAssetIdentifier;
- (void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    [_checkMark setHidden:!selected];
}
- (void)prepareForReuse
{
    [super prepareForReuse];
    [_imageView setImage:nil];
    [_checkMark setHidden:YES];
    [_editButton setHidden:YES];
    [_editButton setUserInteractionEnabled:NO];
}
@end
