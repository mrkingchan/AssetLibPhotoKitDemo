//
//  VideoView.h
//  AssetLibPhotoKitDemo
//
//  Created by Chan on 2017/7/27.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
typedef NS_ENUM(NSUInteger, PlayerState) {
    PlayerStateFailed,   //播放失败
    PlayerStateBuffering,  //缓冲中
    PlayerStateReadyToPlay,  //将要播放
    PlayerStatePlaying,  //正在播放
    PlayerStateStopped,  //暂停播放
    PlayerStateFinished   //播放完毕
 };

@interface VideoView : UIView

@property(nonatomic,strong) UIView *bottomView;   //底部操作工具栏
@property(nonatomic,strong) UILabel *titleLabel;   //显示视频title
@property(nonatomic,strong) UIButton *leftTopCloseButton;  //左上角关闭按钮
@property(nonatomic,strong) UIButton *screenButton;  //全屏按钮

@property(nonatomic,strong) UIButton *playOrPause;  //播放或者暂停
@property(nonatomic,strong) UILabel  *loadFailedLabel;
@property(nonatomic,strong) UIActivityIndicatorView *loadingView;

@property(nonatomic,strong) UIView  *topView;


@property(nonatomic, assign) PlayerState state;
@property(nonatomic,strong) AVPlayer *player;
@property(nonatomic,strong) AVPlayerLayer *AVPlayerLayer;
@property(nonatomic,strong) AVPlayerItem *currentItem;

@property(nonatomic, assign) double seetTime;  //跳转到某个时间点
@property(nonatomic,strong) NSTimer *autoDismissTimer;  //自动隐藏定时器
@property(nonatomic, assign) BOOL isRepeat;  //是否重复
@property(nonatomic, assign) BOOL isFullScreen;  //是否全屏
@property(nonatomic, assign) BOOL isPlaying;  //是否正在播放

@property(nonatomic,strong) id filePath;


- (instancetype)initWithFilePath:(id)filePath isRepeat:(BOOL)isRepeat frame:(CGRect)frame;

- (double)currentTime;

- (void)stopPlay;

- (void)resetPlayer;

+ (NSString *)getVideoDurationWithAsset:(id)asset;

- (void)adjustImageView:(UIImageView *)imageView;
@end
