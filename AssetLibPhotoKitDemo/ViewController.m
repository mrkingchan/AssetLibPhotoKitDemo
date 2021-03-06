//
//  ViewController.m
//  AssetLibPhotoKitDemo
//
//  Created by Chan on 2017/7/21.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import "ViewController.h"
#import "PhotoKitVC.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "Cell.h"
#define kcellID @"cell"

#import <MediaPlayer/MediaPlayer.h>

#import <AVFoundation/AVFoundation.h>

#import "MWPhoto.h"
#import "MWPhotoBrowser.h"


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
    
    ///初始化UI
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height) collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor grayColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [_collectionView registerClass:[Cell class] forCellWithReuseIdentifier:kcellID];
    [self.view addSubview:_collectionView];
    [self loadAssetData];
    
//    self.navigationItem.title = @"AlassetLibrary";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"PushToPhotoKit" style:UIBarButtonItemStylePlain target:self action:@selector(pushAction)];
}

///pushAction
- (void)pushAction {
    PhotoKitVC *VC = [PhotoKitVC new];
    [self.navigationController pushViewController:VC animated:YES];
}

////loadAssetData
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
                                            NSLog(@"result URL = %@\nDate = %@\n Location = %@",[result valueForProperty:ALAssetPropertyAssetURL],[result valueForProperty:ALAssetPropertyDate],[result valueForProperty:ALAssetPropertyLocation]);
                                            if (result) {
                                                [_photos addObject:result];                                                
                                            }
                                        }];
                                        //异步拉取，刷新UI的时候要在主线程中刷新
                                        dispatch_async(dispatch_get_main_queue(), ^{
                                            [_collectionView reloadData];
                                        });
                                    }
                                } else {
                                    if (_photos.count > 0) {
                                        NSLog(@"photos = %@",_photos);
                                    } else {
                                        NSLog(@"相册资源为空!");
                                    }
                                }
                            } failureBlock:^(NSError *error) {
                                NSLog(@"Asset group not found,error = %@",error);
                            }];
}

#pragma mark --UICollectionViewDataSource&Delegate
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photos.count;
}

- ( UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    Cell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kcellID forIndexPath:indexPath];
    cell.backgroundColor = [UIColor orangeColor];
    [cell setCellWithData:_photos[indexPath.row]];
    cell.complete = ^(NSURL *videoUrl) {
        NSLog(@"videoUrlPath = %@",videoUrl);
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

- (void)prectise {
    _lib = [ALAssetsLibrary new];
    [_lib  enumerateGroupsWithTypes:ALAssetsGroupAll
                         usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
                             if (group.numberOfAssets > 0) {
                                 //分组设置过滤器
                                 ALAssetsFilter *fliter = [ALAssetsFilter allAssets];
                                 [group setAssetsFilter:fliter];
                                 [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                                     if (result) {
                                         if ([[result valueForProperty:ALAssetPropertyType]  isEqualToString:ALAssetTypePhoto]) {
                                             UIImage *resultImage = [UIImage imageWithCGImage:[result thumbnail]];
                                             [_photos addObject:resultImage];
                                         }
                                     }
                                 }];
                             }
                         } failureBlock:^(NSError *error) {
                             NSLog(@"error = %@",error);
                         }];
}

//#pragma mark --UICollectionViewDelegate
//- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
//    Cell *cell = (Cell *)[_collectionView cellForItemAtIndexPath:indexPath];
//    ALAsset *source = _photos[indexPath.row];
//    NSMutableArray *temPhotots = [NSMutableArray new];
//    NSString *typeStr = [source valueForProperty:ALAssetPropertyType];
//    if ([typeStr isEqualToString:ALAssetTypePhoto]) {
//        //照片
//        [temPhotots addObject:[UIImage imageWithCGImage:[source thumbnail]]];
//        //照片查看器
//        /*NSMutableArray *temArray = [NSMutableArray new];
//        for (UIImage *image in temPhotots) {
//            MWPhoto *photot = [MWPhoto photoWithImage:image];
//            [temArray addObject:photot];
//        }
//        MWPhotoBrowser *browser = [[MWPhotoBrowser alloc] initWithPhotos:temPhotots];
//        browser.displayActionButton = YES;
//        browser.displayNavArrows = NO;
//        browser.displaySelectionButtons = NO;
//        browser.zoomPhotosToFill = YES;
//        browser.alwaysShowControls = NO;
//        browser.enableGrid = YES;
//        browser.startOnGrid = NO;
//        browser.autoPlayOnAppear = NO;
//        [browser setCurrentPhotoIndex:1];
//        [self.navigationController pushViewController:browser animated:YES];
//        [browser showNextPhotoAnimated:YES];
//        [browser showPreviousPhotoAnimated:YES];
//        [browser setCurrentPhotoIndex:10];*/
//    } else if ([typeStr isEqualToString:ALAssetTypeVideo]) {
//        //视频
//        NSURL *url = [source valueForProperty:ALAssetPropertyAssetURL];
//        MPMoviePlayerViewController *moviePlayer =[[MPMoviePlayerViewController alloc] initWithContentURL:url];
//        [moviePlayer.moviePlayer prepareToPlay];
//        [self presentViewController:moviePlayer animated:YES completion:nil];
//        [moviePlayer.moviePlayer setControlStyle:MPMovieControlStyleFullscreen];
//        [moviePlayer.view setBackgroundColor:[UIColor clearColor]];
//        [moviePlayer.view setFrame:self.view.bounds];
//        [[NSNotificationCenter defaultCenter] addObserver:self
//                                                selector:@selector(movieFinishedCallback:)
//                                                    name:MPMoviePlayerPlaybackDidFinishNotification
//                                                  object:moviePlayer.moviePlayer];
//        
//        /*AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:url options:nil];
//        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
//        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
//        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
//        playerLayer.frame = self.view.layer.bounds;
//        playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
//        [self.view.layer addSublayer:playerLayer];
//        [player play];*/
//    }
//}

///视频播放完成以后
- (void)movieFinishedCallback:(NSNotification *)noti {
    MPMoviePlayerController *player = noti.object;
    [player stop];
}
@end
