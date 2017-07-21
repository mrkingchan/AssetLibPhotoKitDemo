//
//  ViewController.m
//  AssetLibPhotoKitDemo
//
//  Created by Chan on 2017/7/21.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import "ViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Cell.h"
#define kcellID @"cell"
@interface ViewController () <UICollectionViewDelegate,UICollectionViewDataSource> {
    ALAssetsLibrary *_lib;
    NSMutableArray *_photos;
    UICollectionView *_collectionView;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.itemSize = CGSizeMake(([UIScreen mainScreen].bounds.size.width - 10) / 3.0, 120);
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) collectionViewLayout:layout];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[Cell class] forCellWithReuseIdentifier:kcellID];
    [self.view addSubview:_collectionView];
    [self loadAssetData];
}

- (void)loadAssetData {
    if ([ALAssetsLibrary authorizationStatus] == ALAuthorizationStatusDenied) {
        NSDictionary *mainInfoDictionary = [[NSBundle mainBundle] infoDictionary];
        NSString *appName = [mainInfoDictionary objectForKey:@"CFBundleDisplayName"];
        NSString *tipStr = [NSString stringWithFormat:@"请在设备的\"设置-隐私-照片\"选项中，允许%@访问你的手机相册", appName];
        NSLog(@"%@",tipStr);
        return ; 
    }
        _lib = [ALAssetsLibrary new];
        _photos = [NSMutableArray new];
        //枚举图片
        [_lib enumerateGroupsWithTypes:ALAssetsGroupAll
                            usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                                if (group) {
                                    /*
                                     + (ALAssetsFilter *)allPhotos;
                                     + (ALAssetsFilter *)allVideos;
                                     + (ALAssetsFilter *)allAssets;*/
                                    ALAssetsFilter *filter = [ALAssetsFilter allAssets];//包括照片和视频
                                    [group  setAssetsFilter:filter];
                                    if (group.numberOfAssets > 0) {
                                        //安全判断
                                        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                            //判断asset的类型(照片、视频)
//                                            if ([[result  valueForProperty:ALAssetPropertyType] isEqualToString: ALAssetTypePhoto ]) {
                                                /*ALAssetTypePhoto, ALAssetTypeVideo or ALAssetTypeUnknown*/
                                            if (result) {
                                                [_photos addObject:result];                                                
                                            }
//                                            }
                                        }];
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [_collectionView reloadData];
                                        });
                                    }
                                } else {
                                    if (_photos.count > 0) {
                                        //拿到了相册中的所有资源
                                        NSLog(@"photos = %@",_photos);
                                    } else {
                                        NSLog(@"相册资源为空!");
                                    }
                                }
                            } failureBlock:^(NSError *error) {
                                NSLog(@"Asset group not found,error = %@",error);
                            }];
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
