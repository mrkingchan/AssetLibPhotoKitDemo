//
//  Cell.m
//  AssetLibPhotoKitDemo
//
//  Created by Chan on 2017/7/21.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import "Cell.h"
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
        [self addSubview:_imageView];
        
        _des = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, self.frame.size.width, 30)];
        _des.numberOfLines = 0;
        _des.textColor = [UIColor blueColor];
        _des.font = [UIFont systemFontOfSize:11];
        [self addSubview:_des];
        
        _video = [[UIImageView alloc]initWithFrame:CGRectMake(_imageView.frame.size.width/2 -10, _imageView.frame.size.height/2 -10 , 20, 20)];
        _video.image = [UIImage imageNamed:@"video"];
        [_imageView addSubview:_video];
    }
    return self;
}

///setCellWithData
- (void)setCellWithData:(id)image {
    if ([image isKindOfClass:[ALAsset class]]) {
        CGImageRef  thumbnailRef = [image thumbnail];
        UIImage *thumbnailImg = [[UIImage alloc]initWithCGImage:thumbnailRef];
        [_imageView setImage:thumbnailImg];
        id type = [image valueForProperty:ALAssetPropertyType];  //这里的type是Str类型
        if ([type isEqualToString:ALAssetTypeVideo]) {
            _video.hidden = NO;
        } else {
            _video.hidden = YES;
        }
        
        if ([[image  valueForProperty:ALAssetPropertyType] isEqualToString: ALAssetTypeVideo]) {
            _des.textColor = [UIColor redColor];
            _des.text = [NSString stringWithFormat:@"Video:%@\n%@\n%@",[image valueForProperty:ALAssetPropertyDate],[image valueForProperty:ALAssetPropertyLocation],[image valueForProperty:ALAssetsGroupPropertyName]];
        } else {
            _des.textColor = [UIColor blueColor];
            _des.text = [NSString stringWithFormat:@"photo:%@\n%@\n%@",[image valueForProperty:ALAssetPropertyDate],[image valueForProperty:ALAssetPropertyLocation],[image valueForProperty:ALAssetsGroupPropertyName]];
        }
        //获取内容图片
        /*ALAssetRepresentation *representation = [image defaultRepresentation];
        UIImage *contentImage = [UIImage imageWithCGImage:[representation fullScreenImage]];*/
    } else if ([image isKindOfClass:[UIImage class]]) {
        //存储的是image
        [_imageView setImage:image];
        _video.hidden = YES;
    }
}
@end
