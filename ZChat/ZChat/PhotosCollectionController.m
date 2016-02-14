//
//  PhotosCollectionController.m
//  ZChat
//
//  Created by ALEXEY LOBANOV on 13.02.16.
//  Copyright © 2016 Blue Skies Software. All rights reserved.
//
#import <Photos/Photos.h>
#import "PhotosCollectionController.h"
#import "PhotoCell.h"
#import "NSError+Report.h"
#import "MobileCoreServices/MobileCoreServices.h"
#import "NSIndexSet+MY.h"
#import "UIImage+Orientation.h"
#include <libkern/OSAtomic.h>

#define LOCAL_LEVEL_0 0
#define LOCAL_LEVEL_1 1
#define LOCAL_LEVEL_2 1

@interface PhotosCollectionController () <UIImagePickerControllerDelegate,UINavigationControllerDelegate,PHPhotoLibraryChangeObserver>
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *send;
@property (weak, nonatomic) IBOutlet UIButton *take;
@property (weak, nonatomic) IBOutlet UIButton *cancel;
@property (weak, nonatomic) IBOutlet UIView *contentView;
@end

@implementation PhotosCollectionController
{
    PHFetchResult               *_photos;
    PHCachingImageManager       *_imageManager;
    UIImagePickerController     *_camera;
}
static NSString * const cellId = @"PhotoCell";
static CGSize assetGridThumbnailSize;

@synthesize collectionView = _collectionView;
@synthesize send = _send;
@synthesize take = _take;
@synthesize cancel = _cancel;
@synthesize contentView = _contentView;
@synthesize delegate = _delegate;
@synthesize targetImageSize = _targetImageSize;
#pragma mark - VIEW
- (void)viewDidLoad
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super viewDidLoad];
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    if ((status != PHAuthorizationStatusAuthorized) && (status != PHAuthorizationStatusNotDetermined))
    {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
        NSString *str = [NSLocalizedString(@"P0", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:str
                                                                       message:NSLocalizedString(@"P6", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIFont *font = [UIFont systemFontOfSize:22.0f];
        NSAttributedString *title = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor blueColor]}];
        [alert setValue:title forKey:@"attributedTitle"];
        font = [UIFont systemFontOfSize:16.0f];
        NSAttributedString *message = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"P6", nil) attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor grayColor]}];
        [alert setValue:message forKey:@"attributedMessage"];
        UIAlertAction* yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"YES",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf doCancel:nil];
             dispatch_async(dispatch_get_main_queue(), ^{
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            });
        }];
        [yesAction setValue:[UIColor blueColor] forKey:@"titleTextColor"];
        [alert addAction:yesAction];
        UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"NO",nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf doCancel:nil];
        }];
        [cancelAction setValue:[UIColor redColor] forKey:@"titleTextColor"];
        [alert addAction:cancelAction];
            __strong typeof(self) strongSelf = weakSelf;
        [strongSelf presentViewController:alert animated:YES completion:NULL];
        });
    }
    else
    {
        _imageManager = [PHCachingImageManager new];
        PHFetchOptions *options = [PHFetchOptions new];
        [options setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]]];
        [options setPredicate:[NSPredicate predicateWithFormat:@"mediaType = %i",PHAssetMediaTypeImage]];
        _photos = [PHAsset fetchAssetsWithOptions:options];
        [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
    }
    [_collectionView setAllowsMultipleSelection:YES];
    [[_contentView layer] setCornerRadius:2.0f];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        CGRect rect = [[UIScreen mainScreen] bounds];
        CGFloat f = rect.size.width - 320.0f;
        UIEdgeInsets insets = [_cancel imageEdgeInsets];
        insets.left += f;
        [_cancel setImageEdgeInsets:insets];
    }
    [[_cancel layer] setCornerRadius:2.0f];
}
- (void)viewWillAppear:(BOOL)animated
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super viewWillAppear:animated];
    if ([[UIDevice currentDevice] orientation] !=  UIDeviceOrientationPortrait)
    {
        NSNumber *value = [NSNumber numberWithInt:UIDeviceOrientationPortrait];
        [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
    }
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGSize cellSize = [(UICollectionViewFlowLayout *)[_collectionView collectionViewLayout] itemSize];
    assetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
    [_imageManager startCachingImagesForAssets:[_photos objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [_photos count])]]
                                    targetSize:assetGridThumbnailSize
                                   contentMode:PHImageContentModeAspectFit
                                       options:nil];
}
- (void)dealloc
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    _camera = nil;
    if (_imageManager != nil)
    {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
    _imageManager = nil;
    _photos = nil;
}
- (void)didReceiveMemoryWarning
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    [super didReceiveMemoryWarning];
}
#pragma mark - DATA SOURCE: UICollectionView
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    return 1;
}
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_2
    NSLog(@"SECTION=%li",(long)section);
#endif
    return [_photos count];
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    PHAsset *asset = _photos[[indexPath item]];
    PhotoCell *cell = (PhotoCell *)[collectionView dequeueReusableCellWithReuseIdentifier:cellId forIndexPath:indexPath];
    [cell setRepresentedAssetIdentifier:[asset localIdentifier]];
    __weak PhotoCell *weakCell = cell;
    [_imageManager requestImageForAsset:asset
                             targetSize:assetGridThumbnailSize
                            contentMode:PHImageContentModeAspectFill
                                options:nil
                          resultHandler:^(UIImage *result, NSDictionary *info) {
                                  __strong PhotoCell *strongCell = weakCell;
                                  if ([[strongCell representedAssetIdentifier] isEqualToString:[asset localIdentifier]]) {
                                      [[strongCell imageView] setImage:result];
                                  }
                              }];
    return cell;
}
#pragma mark - DELEGATE: UICollectionView
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    NSArray *selectedItems = [collectionView indexPathsForSelectedItems];
    NSUInteger n = [selectedItems count];
    if (n > 0)
    {
        [collectionView deselectItemAtIndexPath:[selectedItems lastObject] animated:YES];
    }
    return YES;
}
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    NSArray *selectedItems = [collectionView indexPathsForSelectedItems];
    NSUInteger n = [selectedItems count];
    if (n == 0)
    {
        [_send setTitle:NSLocalizedString(@"P1", nil) forState:UIControlStateNormal];
    }
    else
    {
        [_send setTitle:[NSString stringWithFormat:NSLocalizedString(@"P2", nil),n] forState:UIControlStateNormal];
    }
}
- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(nonnull NSIndexPath *)indexPath
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    NSArray *selectedItems = [collectionView indexPathsForSelectedItems];
    NSUInteger n = [selectedItems count];
    if (n == 0)
    {
        [_send setTitle:NSLocalizedString(@"P1", nil) forState:UIControlStateNormal];
    }
    else
    {
        [_send setTitle:[NSString stringWithFormat:NSLocalizedString(@"P2", nil),n] forState:UIControlStateNormal];
    }
}
#pragma mark - OBSERVER: PHPhotoLibrary

- (void)photoLibraryDidChange:(PHChange *)changeInfo
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    PHFetchResultChangeDetails *collectionChanges = [changeInfo changeDetailsForFetchResult:_photos];
    if (collectionChanges != nil)
    {
        __weak typeof(self) weakSelf = self;
        _photos = [collectionChanges fetchResultAfterChanges];
        if (![collectionChanges hasIncrementalChanges])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf->_collectionView reloadData];
            });
        }
        else
        {
            NSIndexSet *removedIndexes = [collectionChanges removedIndexes];
            if ([removedIndexes count] > 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(self) strongSelf = weakSelf;
                    [strongSelf->_collectionView performBatchUpdates:^{
                        __strong typeof(self) strongSelf = weakSelf;
                        [strongSelf->_collectionView deleteItemsAtIndexPaths:[removedIndexes indexPathsFromIndexesWithSection:0]];
                    } completion:NULL];
                });
            }
            NSIndexSet *insertedIndexes = [collectionChanges insertedIndexes];
            if ([insertedIndexes count] > 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(self) strongSelf = weakSelf;
                    [strongSelf->_collectionView performBatchUpdates:^{
                        __strong typeof(self) strongSelf = weakSelf;
                        [strongSelf->_collectionView insertItemsAtIndexPaths:[insertedIndexes indexPathsFromIndexesWithSection:0]];
                    } completion:NULL];
                });
            }
            NSIndexSet *changedIndexes = [collectionChanges changedIndexes];
            if ([changedIndexes count] > 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(self) strongSelf = weakSelf;
                    [strongSelf->_collectionView performBatchUpdates:^{
                        __strong typeof(self) strongSelf = weakSelf;
                        [strongSelf->_collectionView reloadItemsAtIndexPaths:[changedIndexes indexPathsFromIndexesWithSection:0]];
                    } completion:NULL];
                });
            }
            if ([collectionChanges hasMoves])
            {
                [collectionChanges enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        __strong typeof(self) strongSelf = weakSelf;
                        NSIndexPath *fromIndexPath = [NSIndexPath indexPathForItem:fromIndex inSection:0];
                        NSIndexPath *toIndexPath = [NSIndexPath indexPathForItem:toIndex inSection:0];
                        [strongSelf->_collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                    });
                }];
            }
        }
    }
}
#pragma mark - ACTIONS
- (IBAction)doCancel:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if (_delegate != nil)
    {
        [_delegate collectionController:self selectedPhoto:nil];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:NULL];
    }
}
- (IBAction)doSend:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    NSArray *indexPathes = [_collectionView indexPathsForSelectedItems];
    if ([indexPathes count] > 0)
    {
        NSIndexPath *indexPath = [indexPathes lastObject];
        PHAsset *asset = _photos[[indexPath item]];
        if ((_targetImageSize.width == 0.0f) || (_targetImageSize.height == 0.0f))
        {
            _targetImageSize.width = [asset pixelWidth];
            _targetImageSize.height = [asset pixelHeight];
        }
#if DEBUG >= LOCAL_LEVEL_2
        NSLog(@"TARGET IMAGE SIZE=(%f,%f)", _targetImageSize.width,_targetImageSize.height);
#endif
        __weak typeof(self) weakSelf = self;
        [_imageManager requestImageForAsset:asset targetSize:_targetImageSize contentMode:PHImageContentModeAspectFit options:nil resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
#if DEBUG >= LOCAL_LEVEL_2
            NSLog(@"IMAGE=%@ ORIENTATION=%li", [result debugDescription],(long)[result imageOrientation]);
#endif
            UIImage *image = [result imageByNormalizingOrientation];
#if DEBUG >= LOCAL_LEVEL_2
            NSLog(@"NORMALIZED IMAGE=%@ ORIENTATION=%li", [image debugDescription],(long)[image imageOrientation]);
#endif
            __strong typeof(self) strongSelf = weakSelf;
            if (strongSelf->_delegate != nil)
            {
                [strongSelf->_delegate collectionController:strongSelf selectedPhoto:image];
            }
            else
            {
                [strongSelf dismissViewControllerAnimated:YES completion:NULL];
            }
        }];
    }
}
- (IBAction)doTakePhoto:(UIButton *)sender
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    if ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear] && [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
    {
        AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        
        if ((status != AVAuthorizationStatusAuthorized) && (status != AVAuthorizationStatusNotDetermined))
        {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *str = [NSLocalizedString(@"P0", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
                UIAlertController* alert = [UIAlertController alertControllerWithTitle:str
                                                                               message:NSLocalizedString(@"P7", nil)
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                UIFont *font = [UIFont systemFontOfSize:22.0f];
                NSAttributedString *title = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor blueColor]}];
                [alert setValue:title forKey:@"attributedTitle"];
                font = [UIFont systemFontOfSize:16.0f];
                NSAttributedString *message = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"P7", nil) attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor grayColor]}];
                [alert setValue:message forKey:@"attributedMessage"];
                UIAlertAction* yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"YES",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
                    __strong typeof(self) strongSelf = weakSelf;
                    [strongSelf doCancel:nil];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    });
                }];
                [yesAction setValue:[UIColor blueColor] forKey:@"titleTextColor"];
                [alert addAction:yesAction];
                UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"NO",nil) style:UIAlertActionStyleCancel handler:NULL];
                [cancelAction setValue:[UIColor redColor] forKey:@"titleTextColor"];
                [alert addAction:cancelAction];
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf presentViewController:alert animated:YES completion:NULL];
            });
        }
        else
        {
            if (_camera == nil)
            {
                _camera = [UIImagePickerController new];
            }
            [_camera setSourceType:UIImagePickerControllerSourceTypeCamera];
            NSArray *media = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
            if ((media != nil) && [media containsObject:(NSString *)kUTTypeImage])
            {
                [_camera setMediaTypes:@[(NSString *)kUTTypeImage]];
                [_camera setCameraCaptureMode:UIImagePickerControllerCameraCaptureModePhoto];
                [_camera setCameraFlashMode:UIImagePickerControllerCameraFlashModeAuto];
                [_camera setAllowsEditing:NO];
                [_camera setShowsCameraControls:YES];
                [_camera setDelegate:self];
                [_camera setModalPresentationStyle:UIModalPresentationFullScreen];
                [_camera setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
                [self presentViewController:_camera animated:YES completion:NULL];
            }
        }
    }
    else
    {
        NSString *str = [NSLocalizedString(@"P0", nil) uppercaseStringWithLocale:[NSLocale currentLocale]];
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:str
                                                                       message:NSLocalizedString(@"P3", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIFont *font = [UIFont systemFontOfSize:22.0f];
        NSAttributedString *title = [[NSAttributedString alloc] initWithString:str attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor blueColor]}];
        [alert setValue:title forKey:@"attributedTitle"];
        font = [UIFont systemFontOfSize:16.0f];
        NSAttributedString *message = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"P3", nil) attributes:@{NSFontAttributeName:font,NSForegroundColorAttributeName:[UIColor grayColor]}];
        [alert setValue:message forKey:@"attributedMessage"];
        UIAlertAction* okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleCancel handler:nil];
        [okAction setValue:[UIColor blueColor] forKey:@"titleTextColor"];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}
#pragma mark - DELEGATE: UIImagePickerController
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
    dispatch_async(dispatch_get_main_queue(), ^{
        [picker dismissViewControllerAnimated:YES completion:^{
        }];
    });
}
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"Running %@ '%@'", self.class, NSStringFromSelector(_cmd));
#endif
#if DEBUG >= LOCAL_LEVEL_1
    NSLog(@"INFO=%@",[info debugDescription]);
#endif
    NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType];
    if (CFStringCompare ((CFStringRef) mediaType, kUTTypeImage, 0) == kCFCompareEqualTo)
    {
        UIImage *imageToSave = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
        if (imageToSave != nil)
        {
            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                __unused PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:imageToSave];
            } completionHandler:^(BOOL success, NSError *error) {
                if (!success && (error != nil))
                {
                    [error report];
                }
            }];
        }
    }
    [self imagePickerControllerDidCancel:picker];
}
@end
