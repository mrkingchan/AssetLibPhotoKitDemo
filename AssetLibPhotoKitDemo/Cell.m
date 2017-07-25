//
//  Cell.m
//  AssetLibPhotoKitDemo
//
//  Created by Chan on 2017/7/21.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import "Cell.h"
#import <Photos/Photos.h>

@interface Cell(){
    UIImageView *_imageView;
    UILabel *_des;
    UIImageView *_video;
}

@end

@implementation Cell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.userInteractionEnabled = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonAction:)];
        [_imageView addGestureRecognizer:tap];
        [self addSubview:_imageView];
        
        _des = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.frame.size.width, 30)];
        _des.numberOfLines = 0;
        _des.textColor = [UIColor blueColor];
        _des.font = [UIFont systemFontOfSize:11];
        [self addSubview:_des];
        
        _video = [[UIImageView alloc]initWithFrame:CGRectMake(_imageView.frame.size.width/2 -20, _imageView.frame.size.height/2 - 20 , 40, 40)];
        _video.image = [UIImage imageNamed:@"video"];
        [_imageView addSubview:_video];
    }
    return self;
}

///setCellWithData
- (void)setCellWithData:(id)image {
    _asset = image;
    if ([image isKindOfClass:[ALAsset class]]) {
        //ALAsset
        CGImageRef  thumbnailRef = [image thumbnail];
        UIImage *thumbnailImg = [[UIImage alloc]initWithCGImage:thumbnailRef];
        [_imageView setImage:thumbnailImg];
        id type = [image valueForProperty:ALAssetPropertyType];
        if ([type isEqualToString:ALAssetTypeVideo]) {
            //视频
            _video.hidden = NO;
        } else {
            _video.hidden = YES;
        }
        if ([[image  valueForProperty:ALAssetPropertyType] isEqualToString: ALAssetTypeVideo]) {
            //视频
            _des.textColor = [UIColor redColor];
            _des.text = [NSString stringWithFormat:@"Video:%@\n%@\n%@",[image valueForProperty:ALAssetPropertyDate],[image valueForProperty:ALAssetPropertyLocation],[image valueForProperty:ALAssetsGroupPropertyName]];
        } else {
            //照片
            _des.textColor = [UIColor blueColor];
            _des.text = [NSString stringWithFormat:@"photo:%@\n%@\n%@",[image valueForProperty:ALAssetPropertyDate],[image valueForProperty:ALAssetPropertyLocation],[image valueForProperty:ALAssetsGroupPropertyName]];
        }
        //获取内容图片
        /*ALAssetRepresentation *representation = [image defaultRepresentation];
        UIImage *contentImage = [UIImage imageWithCGImage:[representation fullScreenImage]];*/
    } else if ([image isKindOfClass:[UIImage class]]) {
        //UIImage
        [_imageView setImage:image];
        _video.hidden = YES;
    } else if ([image isKindOfClass:[AVAsset class]]) {
        //视频
         _video.hidden = YES;
        AVAsset *asset = (AVAsset *)image;
    } else if ([image isKindOfClass:[NSDictionary class]]) {
        //视频
        _video.hidden = NO;
        NSDictionary *info = (NSDictionary *)image;
        NSString *pathStr = info[@"PHImageFileSandboxExtensionTokenKey"];
        NSString *urlStr = [[pathStr componentsSeparatedByString:@":"] lastObject];
        [_imageView setImage:[self getImage:urlStr]];
    } else if ([image isKindOfClass:[PHAsset class]]) {
        //PHAsset
        PHAsset *asset = (PHAsset *)image;
        NSInteger mediaType = asset.mediaType;
        PHCachingImageManager *manager = [PHCachingImageManager new];
        if (mediaType == PHAssetMediaTypeImage) {
            //照片
            _video.hidden = YES;
            [manager requestImageForAsset:asset
                               targetSize:CGSizeMake(200, 200)
                              contentMode:PHImageContentModeDefault
                                  options:nil
                            resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                if (result) {
                                    dispatch_async(dispatch_get_main_queue(), ^{
                                        [_imageView setImage:result];
                                    });
                                }
                            }];
        } else if (mediaType == PHAssetMediaTypeVideo) {
            //视频
            _video.hidden = NO;
            [manager requestAVAssetForVideo:asset
                                    options:nil
                              resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                  NSString *pathStr = info[@"PHImageFileSandboxExtensionTokenKey"];
                                  NSString *urlStr = [[pathStr componentsSeparatedByString:@";"] lastObject];
                                  //主线程刷新UI
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [_imageView setImage:[self getImage:urlStr]];
                                  });
                              }];
        }
    }
}

///获取视频的第一帧图片,根据视频路径
-(UIImage *)getImage:(NSString *)videoURL{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoURL] options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumb;
}

#pragma mark --private Method
- (void)buttonAction:(id)sender {
    if ([sender isKindOfClass:[UITapGestureRecognizer class]]) {
        //PHAsset类
        PHCachingImageManager *manager = [PHCachingImageManager new];
        if ([_asset isKindOfClass:[PHAsset class]]) {
            PHAsset *source = (PHAsset *)_asset;
            if (source.mediaType == PHAssetMediaTypeVideo) {
                //是视频
                [manager requestAVAssetForVideo:source
                                        options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                            //视频路径 存放在info里面,可以通过键值取到值
                                            NSString *pathStr = info[@"PHImageFileSandboxExtensionTokenKey"];
                                            NSString *urlStr = [[pathStr componentsSeparatedByString:@";"] lastObject];
                                            if (_complete) {
                                                _complete([NSURL fileURLWithPath:urlStr]);
                                            }
                                        }];
            }
        } else if ([_asset isKindOfClass:[ALAsset class]]) {
            //ALAsset类
            //视频
            ALAsset *source = (ALAsset *)_asset;
            if ([[source valueForProperty:ALAssetPropertyType] isEqualToString:ALAssetTypeVideo]) {
                //视频
                NSURL *url = [source valueForProperty:ALAssetPropertyAssetURL];
                if (_complete) {
                    _complete(url);
                }
            }
        }
    }
}
@end
