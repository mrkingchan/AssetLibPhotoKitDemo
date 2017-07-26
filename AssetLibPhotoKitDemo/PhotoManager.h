//
//  PhotoManager.h
//  TestGit
//
//  Created by Chan on 2017/7/20.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSUInteger, ReturnType) {
    ReturnTypeURL = 0,   // URL
    ReturnTypeAsset,
    ReturnTypeImage,
};


typedef NS_ENUM(NSInteger, SourceType) {
    SourcePhoto = 0,  //图片
    SourceVideo,      //视频
    SourceAudio,      //声音
    SourceOthers,     //其他类型
    SourceAll         //混合类型，包括所有类型
};

@interface PhotoManager : NSObject

+ (PhotoManager *)shareInstance;

- (void)getLatestPhotoWithReturnType:(ReturnType)returnType
                          sourceType:(SourceType)sourceType
                            complete:(void (^) (id asset))complete;


@end
