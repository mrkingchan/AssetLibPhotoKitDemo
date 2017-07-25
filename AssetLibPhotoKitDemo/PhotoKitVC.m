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

#import <MediaPlayer/MediaPlayer.h>
#import "CaptureVC.h"
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
    ///初始化CollectionView
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(([UIScreen mainScreen].bounds.size.width - 10) / 3.0, 120);
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor grayColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[Cell class] forCellWithReuseIdentifier:kcellID];
    [self.view addSubview:_collectionView];
    [self loadAllPhotoData];
    
    self.navigationItem.title = @"PhotoKit";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"CameraVC" style:UIBarButtonItemStylePlain target:self action:@selector(buttonAction:)];
    
}

#pragma mark --private Method
- (void)buttonAction:(id)sender {
    if ([sender isKindOfClass:[UIBarButtonItem class]]) {
        CaptureVC *VC = [CaptureVC new];
        [self.navigationController pushViewController:VC animated:YES];
    }
}

///加载图片数据
- (void)loadAllPhotoData {
    //获取相册相当于 group 分组结果
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                     subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchOptions *options = [PHFetchOptions new];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *results2 = [PHAsset fetchAssetsWithOptions:options];
    //遍历查找
    for (PHAsset *asset in results2) {
        if (asset ) {
            [_photos addObject:asset];
        }
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [_collectionView reloadData];
    });
}

#pragma mark --UICollectionViewDataSource&Delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photos.count;
}

- ( UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Cell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kcellID forIndexPath:indexPath];
    cell.backgroundColor = [UIColor orangeColor];
    [cell setCellWithData:_photos[indexPath.row]];
    cell.complete = ^(NSURL *videoUrl) {
        NSLog(@"videoUrlPath = %@",videoUrl);
        //注意这里要在主线程进行跳转操作
        dispatch_async(dispatch_get_main_queue(), ^{
            MPMoviePlayerViewController *moviePlayer =[[MPMoviePlayerViewController alloc] initWithContentURL:videoUrl];
            [self presentViewController:moviePlayer animated:YES completion:nil];
            [moviePlayer.moviePlayer prepareToPlay];
            [moviePlayer.moviePlayer setControlStyle:MPMovieControlStyleFullscreen];
            [moviePlayer.view setBackgroundColor:[UIColor clearColor]];
            [moviePlayer.view setFrame:self.view.bounds];
        });
    };
    return cell;
}

@end
