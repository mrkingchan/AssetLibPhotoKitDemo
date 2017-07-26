//
//  PhotoManager.m
//  TestGit
//
//  Created by Chan on 2017/7/20.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import "PhotoManager.h"
#import <UIKit/UIKit.h>

#import <Photos/Photos.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation PhotoManager

+ (PhotoManager *)shareInstance {
    static PhotoManager *shareInnstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInnstance = [PhotoManager new];
    });
    return shareInnstance;
}

 -(void)getLatestPhotoWithReturnType:(ReturnType)returnType sourceType:(SourceType)sourceType complete:(void (^)(id))complete {
    if ([UIDevice currentDevice].systemVersion.floatValue>=8.0) {
        //获取所有的资源集合
        PHFetchOptions *options = [PHFetchOptions new];
        options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:NO]];
        PHAssetMediaType mediaType;
        if (sourceType == SourceVideo) {
            mediaType = PHAssetMediaTypeVideo;
        } else if (sourceType == SourcePhoto) {
            mediaType =PHAssetMediaTypeImage;
        } else if (sourceType == SourceAudio) {
            mediaType = PHAssetMediaTypeAudio;
        } else {
            mediaType = PHAssetMediaTypeUnknown;
        }
        //结果集(拿到相册中的所有资源)
        //获取制定类型的results
        PHFetchResult *results = [PHAsset fetchAssetsWithMediaType:mediaType
                                                           options:options];
        //返回类型
        if (returnType == ReturnTypeAsset){
            complete([results firstObject]);
        }else if (returnType == ReturnTypeImage) {
            //Image
            [self getThumbImageWithAsset:[results firstObject] complete:^(UIImage *thumbImage) {
                complete(thumbImage);
            }];
        } else if (returnType == ReturnTypeURL) {
            //URL
        }
    }
}

/// 传入asset获取缩略图
- (void)getThumbImageWithAsset:(id)asset complete:(void(^)(UIImage *thumbImage))complete {
    [self getThumbImageWithGifAsset:asset gifCare:NO complete:complete];
}

// 传入asset获取缩略图(若是gif格式&&gifCare则返回imageData, 若是普通格式图片则返回image)
- (void)getThumbImageWithGifAsset:(id)asset gifCare:(BOOL)gifCare complete:(void(^)(id thumbImage))complete {
    if ([UIDevice currentDevice].systemVersion.floatValue >=8.0) {
        //获取制定Size的图片
        [self requestImageWitGifForAsset:asset gifCare:gifCare size:CGSizeMake(200, 200) resizeMode:PHImageRequestOptionsResizeModeFast completion:^(id image, NSDictionary *info) {
            complete(image);
        }];
    } else {
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        Byte *buffer = (Byte *)malloc((unsigned long)rep.size);
        NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:((unsigned long)rep.size) error:nil];
        NSData *imageData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
        SourceType type = [self getSourceTypeWithAsset:asset];
        if (gifCare && [self isGifAsset:asset]) {
            complete(imageData);
        } else if (type == SourceVideo) {
            complete([UIImage imageWithCGImage:[asset thumbnail]]);
        } else {
            complete([UIImage imageWithData:imageData]);
        }
    }
}

/// 传入asset获取文件类型
- (SourceType)getSourceTypeWithAsset:(id)asset {
    SourceType sourceType;
    if ([UIDevice currentDevice].systemVersion.floatValue >=8.0) {
        PHAssetMediaType type = ((PHAsset *)asset).mediaType;
        if (type == PHAssetMediaTypeImage) {
            sourceType = SourcePhoto;
        } else if (type == PHAssetMediaTypeVideo) {
            sourceType = SourceVideo;
        } else if (type == PHAssetMediaTypeAudio) {
            sourceType = SourceAudio;
        } else {
            sourceType = SourceOthers;
        }
    } else {
        NSString *type = (NSString *)[asset valueForProperty:ALAssetPropertyType];
        if ([type isEqualToString:ALAssetTypeVideo]) {
            sourceType = SourceVideo;
        } else if ([type isEqualToString:ALAssetTypePhoto]) {
            sourceType = SourcePhoto;
        } else {
            sourceType = SourceAudio;
        }
    }
    return sourceType;
}

/// 传入相册集取到相册第一张缩略图
- (void)getFirstThumbWithAssetGroup:(id)assetGroup sourceType:(SourceType)sourceType complete:(void(^)(UIImage *thumbImage))complete {
    if ([UIDevice currentDevice].systemVersion.floatValue >=8.0) {
        PHFetchResult *result = [self fetchAssetsInAssetCollection:assetGroup ascending:YES];
        if (result.count > 0) {
            [self requestImageForAsset:result.lastObject size:CGSizeMake(200, 200) resizeMode:PHImageRequestOptionsResizeModeExact completion:^(UIImage *image, NSDictionary *info) {
                complete(image);
            }];
        }
    } else {
        complete([UIImage imageWithCGImage:[((ALAssetsGroup *)assetGroup) posterImage]]);
    }
}

- (PHFetchResult *)fetchAssetsInAssetCollection:(PHAssetCollection *)assetCollection ascending:(BOOL)ascending {
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:ascending]];
    PHFetchResult *result = [PHAsset fetchAssetsInAssetCollection:assetCollection options:option];
    return result;
}

/// 获取asset对应的图片
- (void)requestImageForAsset:(PHAsset *)asset size:(CGSize)size resizeMode:(PHImageRequestOptionsResizeMode)resizeMode completion:(void (^)(UIImage *image, NSDictionary *info))completion {
    [self requestImageWitGifForAsset:asset gifCare:NO size:size resizeMode:resizeMode completion:completion];
}

/// 获取asset对应的图片(若是gif格式&&gifCare则返回imageData, 若是普通格式图片则返回image)
- (void)requestImageWitGifForAsset:(PHAsset *)asset gifCare:(BOOL)gifCare size:(CGSize)size resizeMode:(PHImageRequestOptionsResizeMode)resizeMode completion:(void (^)(id image, NSDictionary *info))completion {
    /**
     resizeMode：对请求的图像怎样缩放。有三种选择：None，默认加载方式；Fast，尽快地提供接近或稍微大于要求的尺寸；Exact，精准提供要求的尺寸。
     deliveryMode：图像质量。有三种值：Opportunistic，在速度与质量中均衡；HighQualityFormat，不管花费多长时间，提供高质量图像；FastFormat，以最快速度提供好的质量。
     这个属性只有在 synchronous 为 true 时有效。
     */
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = resizeMode;//控制照片尺寸
    //option.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;//控制照片质量
    //option.synchronous = YES;
    option.networkAccessAllowed = YES;
    if (gifCare && [self isGifAsset:asset]) {
        [[PHCachingImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            completion(imageData, info);
        }];
    } else {
        //param：targetSize 即你想要的图片尺寸，若想要原尺寸则可输入PHImageManagerMaximumSize
        //contetModel
        [[PHCachingImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage *image, NSDictionary *info) {
            completion(image, info);
        }];
    }
}

/// 判断gif资源图片
- (BOOL)isGifAsset:(id)asset {
    //iOS8以后通过后缀名判断是否是gif
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
        // gif后缀or图片名检测
        NSString *suffixStr = [asset valueForKey:@"uniformTypeIdentifier"];
        NSString *nameStr = [asset valueForKey:@"filename"];
        if ([nameStr rangeOfString:@".GIF"].length || [suffixStr rangeOfString:@".gif"].length) {
            return YES;
        }
    } else {
        // iOS7通过图片张数来判断是否为gif图片
        ALAssetRepresentation *rep = [asset defaultRepresentation];
        Byte *buffer = (Byte*)malloc((unsigned long)rep.size);
        NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:((unsigned long)rep.size) error:nil];
        NSData *imageData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
        CGImageSourceRef gifSourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)(imageData), NULL);
        NSInteger imageCount = CGImageSourceGetCount(gifSourceRef);
        return imageCount > 1 ? YES : NO;
    }
    return NO;
}

@end
