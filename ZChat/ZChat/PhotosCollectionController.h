//
//  PhotosCollectionController.h
//  ZChat
//
//  Created by ALEXEY LOBANOV on 13.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PhotosCollectionController;
@protocol GetPhotoProtocol <NSObject>
@required
- (void)collectionController:(PhotosCollectionController *)controller selectedPhoto:(UIImage *)photo;
@end

@interface PhotosCollectionController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>
@property (assign,nonatomic) CGSize targetImageSize;
@property (weak,nonatomic) id <GetPhotoProtocol> delegate;
@end
