//
//  VideoView.m
//  AssetLibPhotoKitDemo
//
//  Created by Chan on 2017/7/27.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import "VideoView.h"
#import <Masonry.h>

static void *PlayViewCMTimeValue = &PlayViewCMTimeValue;
static void *PlayViewStatusObservationContext = &PlayViewStatusObservationContext;


@interface VideoView(){
    BOOL _isPlay;
    
}
@end
@implementation VideoView

///初始化化构造方法
- (instancetype)initWithFilePath:(id)filePath isRepeat:(BOOL)isRepeat frame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _isRepeat = isRepeat;
        _player = [AVPlayer new];
        _player.usesExternalPlaybackWhileExternalScreenIsActive = YES;
        //预览
        _AVPlayerLayer = [AVPlayerLayer new];
        _AVPlayerLayer.videoGravity = isRepeat ? AVLayerVideoGravityResizeAspectFill:AVLayerVideoGravityResizeAspect;
        [self.layer addSublayer:_AVPlayerLayer];
        self.backgroundColor = [UIColor blackColor];
        if (filePath) {
            //视频路径 (本地/网络)
            if (!_isRepeat) {
                [self setUI];
            }
            _filePath = filePath;
            _isPlay = YES;
            AVPlayerItem *currentItem;
            if ([filePath  isKindOfClass:[NSString class]]) {
                //网络
                if ([filePath rangeOfString:@"http"].length) {
                    AVAsset *movieAsset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:filePath] options:nil];
                    currentItem = [AVPlayerItem  playerItemWithAsset:movieAsset];
                } else {
                    //本地
                    currentItem = [AVPlayerItem playerItemWithURL:[NSURL fileURLWithPath:filePath]];
                }
            } else if ([filePath  isKindOfClass:[NSURL class]]) {
                currentItem = [AVPlayerItem playerItemWithURL:filePath];
            } else if ([filePath  isKindOfClass:[AVAsset class]]) {
                currentItem = [AVPlayerItem playerItemWithAsset:filePath];
            }
            //设置item
            [self setPlayerWithAVplayerItem:currentItem];
        }
    }
    return self;
}

#pragma mark --setState
- (void)setState:(PlayerState)state {
    if (state == PlayerStateBuffering) {
        [_loadingView startAnimating];
    } else {
        [_loadingView stopAnimating];
    }
}

#pragma mark --前后台
- (void)appDidEnterBackground:(NSNotification *)noti {
    if (_isPlay) {
        //继续播放
        NSArray *tracks = [_currentItem tracks];
        for (AVPlayerItemTrack *track in tracks) {
            if ([track.assetTrack  hasMediaCharacteristic:AVMediaCharacteristicVisual]) {
                track.enabled = YES;
            }
        }
        _AVPlayerLayer.player = nil;
        [_player play];
        _state = PlayerStatePlaying;
    } else {
        _state = PlayerStateStopped;
    }
}

- (void)appWillEnterForeground:(NSNotification *)noti {
    if (_isPlay) {
        //如果是播放中，则继续播放
        NSArray *tracks = [self.currentItem tracks];
        for (AVPlayerItemTrack *playerItemTrack in tracks) {
            if ([playerItemTrack.assetTrack hasMediaCharacteristic:AVMediaCharacteristicVisual]) {
                playerItemTrack.enabled = YES;
            }
        }
        _AVPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        _AVPlayerLayer.frame = self.bounds;
        _AVPlayerLayer.videoGravity = AVLayerVideoGravityResize;
        [self.layer insertSublayer:_AVPlayerLayer atIndex:0];
        [self.player play];
        self.state = PlayerStatePlaying;
    }else{
        self.state = PlayerStateStopped;
    }
}

#pragma mark --播放完成
- (void)playDidFinished:(NSNotification *)noti {
}

#pragma mark --setUI
- (void)setUI {
    _seetTime = 0.0;
    self.backgroundColor = [UIColor blackColor];
    //小菊花
    // WhiteLarge 的尺寸是（37，37）,White 的尺寸是（22，22）
    _loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self addSubview:_loadingView];
    //autolaytout loadingView
    [_loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
    }];
    [_loadingView startAnimating];
    
    _topView = [UIView new];
    _topView.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    [self addSubview:_topView];
    //autolayout topView
     [_topView mas_makeConstraints:^(MASConstraintMaker *make) {
         make.left.equalTo(self).with.offset(0);
         make.right.equalTo(self).with.offset(0);
         make.height.mas_equalTo(40);
         make.top.equalTo(self).with.offset(0);
     }];
    
    //加载失败提示tip
    _loadFailedLabel = [UILabel new];
    _loadFailedLabel.textColor = [UIColor whiteColor];
    _loadFailedLabel.textAlignment = 1;
    _loadFailedLabel.text = @"视屏加载失败!";
    _loadFailedLabel.hidden = YES;
    [self addSubview:_loadFailedLabel];
    
    //autolayout loadFailedLabel
    [_loadFailedLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.equalTo(self);
        make.height.equalTo(@30);
    }];
    
    //bottomView 底部操作工具栏
    _bottomView = [UIView new];
    _bottomView.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1.0];
    [self addSubview:_bottomView];
    //autolayout bottomview
    [_bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).with.offset(0);
        make.right.equalTo(self).with.offset(0);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self).with.offset(0);
    }];
    self.autoresizesSubviews = NO;
    //播放、暂停按钮
    _playOrPause = [UIButton buttonWithType:UIButtonTypeCustom];
    _playOrPause.showsTouchWhenHighlighted = YES;
    _playOrPause.tag = 32894;
    [_playOrPause setImage:[UIImage imageNamed:@"video_pause"] forState:UIControlStateNormal];
    [_playOrPause setImage:[UIImage imageNamed:@"video_play"] forState:UIControlStateSelected];
    [_playOrPause addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_playOrPause];
    //autolayout playorpause
    [_playOrPause mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(0);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self.bottomView).with.offset(0);
        make.width.mas_equalTo(40);
    }];
}

- (void)setPlayerWithAVplayerItem:(AVPlayerItem *)item {
    if (_currentItem == item) {
        return ;
    }
    if (_currentItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_currentItem];
        [_currentItem removeObserver:self forKeyPath:@"status"];
        [_currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        _currentItem = nil;
    }
    _currentItem = item;
    if (_currentItem) {
        //添加观察者
        [_currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
        [_currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
        //缓冲区空了 需要继续等待数据
        [_currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
        //缓冲区数据充足 可以播放了
        [_currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
        
        //播放结束通知
        [[NSNotificationCenter defaultCenter]  addObserver:self selector:@selector(playDidFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:_currentItem];
        _AVPlayerLayer.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        [_player replaceCurrentItemWithPlayerItem:_currentItem];
        _AVPlayerLayer.player = _player;
        //播放
        [_player play];
        self.state = PlayerStateBuffering;
        //前后台播放
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
}
#pragma mark --重置播放器
- (void)resetPlayer {
    _currentItem  = nil;
    _seetTime = 0.0;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //销毁定时器
    [_autoDismissTimer invalidate];
    _autoDismissTimer = nil;
    [_player pause];
    [_AVPlayerLayer removeFromSuperlayer];
    [_player  replaceCurrentItemWithPlayerItem:nil];
    _player = nil;
}

#pragma mark --内存管理
- (void)dealloc {
    if (_AVPlayerLayer) {
        [self  stopPlay];
    }
}

- (void)stopPlay {
    if (_currentItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        //移除观察者
        [_currentItem removeObserver:self forKeyPath:@"status"];
        [_currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
        [_currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [_currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    }
    [_player pause];
    [_AVPlayerLayer removeFromSuperlayer];
    [_player  replaceCurrentItemWithPlayerItem:nil];
    _player = nil;
    _currentItem = nil;
    _AVPlayerLayer = nil;
    _isPlay = NO;
    [self removeFromSuperview];
}
@end
