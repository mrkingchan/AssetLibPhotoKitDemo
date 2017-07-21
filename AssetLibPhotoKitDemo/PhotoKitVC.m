//
//  PhotoKitVC.m
//  AssetLibPhotoKitDemo
//
//  Created by Chan on 2017/7/21.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import <Photos/Photos.h>
#import "PhotoKitVC.h"
#import "Cell.h"
#define kcellID @"cell"

@interface PhotoKitVC () <UICollectionViewDataSource,UICollectionViewDelegate> {
    UICollectionView *_collectionView;
    NSMutableArray *_photos;
}

@end

@implementation PhotoKitVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = @"PhotoKit";
    _photos = [NSMutableArray new];
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(([UIScreen mainScreen].bounds.size.width - 10) / 3.0, 120);
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
 
    ///初始化CollectionView
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor grayColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[Cell class] forCellWithReuseIdentifier:kcellID];
    [self.view addSubview:_collectionView];
    [self loadAllPhotoData];
}

///加载图片数据
- (void)loadAllPhotoData {
    //获取相册相当于 group 分组结果
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                     subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *results2 = [PHAsset fetchAssetsWithOptions:options];
    PHCachingImageManager *manager = [PHCachingImageManager new];
    //遍历查找
    for (PHAsset *asset in results2) {
        if (asset.mediaType == PHAssetMediaTypeImage) {
            //照片
            [manager requestImageForAsset:asset
                               targetSize:CGSizeMake(200, 200)
                              contentMode:PHImageContentModeDefault
                                  options:[PHImageRequestOptions new]
                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                NSLog(@"result = %@,info = %@",result,info);
                                if (result) {
                                    [_photos addObject:result];
                                }
                            }];
        } else if (asset.mediaType == PHAssetMediaTypeVideo) {
            //视频
            [manager requestAVAssetForVideo:asset
                                    options:nil
                              resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                 
                              }];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
    });

}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photos.count;
}

- ( UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Cell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kcellID forIndexPath:indexPath];
    cell.backgroundColor = [UIColor orangeColor];
    [cell setCellWithData:_photos[indexPath.row]];
    return cell;
    
}

@end
