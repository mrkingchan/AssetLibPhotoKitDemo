//
//  Cell.h
//  AssetLibPhotoKitDemo
//
//  Created by Chan on 2017/7/21.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

@interface Cell : UICollectionViewCell

- (void)setCellWithData:(id )image;

@property(nonatomic,strong) UIImageView * imageView;

@property(nonatomic,strong) id asset;

@property(nonatomic,copy)void (^complete)(NSString *videoUrlPath);


@end
