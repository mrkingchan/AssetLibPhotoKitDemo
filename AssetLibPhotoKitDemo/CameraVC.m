//
//  CameraVC.m
//  TestGit
//
//  Created by Chan on 2017/7/20.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import "CameraVC.h"
#import "PhotoManager.h"
#import <PhotosUI/PhotosUI.h>
#import <AssetsLibrary/AssetsLibrary.h>

#define CompressionVideoPaht [NSHomeDirectory() stringByAppendingFormat:@"/Documents/Compression"]
@interface CameraVC () <AVCaptureFileOutputRecordingDelegate> {
    UIButton *_toggle;
    UIButton *_shoot;
    UIButton *_flash;
    
    UIImageView *_currentImageView;
    AVCaptureMovieFileOutput *_movieOutput;
    AVCaptureDeviceInput *_audioInput;
    NSTimer *_timer;
    UILabel *_timeLabel;
}

@end

@implementation CameraVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (_session) {
        [_session startRunning];
    }
    [UIApplication sharedApplication].statusBarHidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (_session) {
        [_session stopRunning];
    }
    [UIApplication sharedApplication].statusBarHidden = NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _session = [AVCaptureSession new];
    
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //更改闪光灯的时候，必须先锁定设备 然后再解锁,否则这里会出现奔溃现象
    [_device lockForConfiguration:nil];
    [_device setFlashMode:AVCaptureFlashModeAuto];
    [_device unlockForConfiguration];
    
    //输入
    NSError *error;
    _input = [[AVCaptureDeviceInput alloc] initWithDevice:_device error:&error];
    if (error) {
        NSLog(@"error = %@",error);
    }
    
    //输出流
    _output = [AVCaptureStillImageOutput new];
    //设置参数(这是输出流的设置参数AVVideoCodecJPEG参数表示以JPEG的图片格式输出图片)
    [_output setOutputSettings:@{AVVideoCodecKey : AVVideoCodecJPEG}];
    //录制视频
    if (_isVideo) {
        _movieOutput = [AVCaptureMovieFileOutput new];
        _session.sessionPreset = AVCaptureSessionPresetHigh;
        if ([_session canAddOutput:_movieOutput]) {
            [_session addOutput:_movieOutput];
        }
        //创建麦克风设备
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        _audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:nil];
        if ([_session canAddInput:_audioInput]) {
            [_session addInput:_audioInput];
        }
    }
    
    if ([_session canAddInput:_input]) {
        [_session addInput:_input];
    }
    if ([_session canAddOutput:_output]) {
        [_session addOutput:_output];
    }
    
    //预览图层
    _preView = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    [_preView setVideoGravity:AVLayerVideoGravityResizeAspect];
    _preView.frame = self.view.frame;
    self.view.layer.masksToBounds = YES;
    [self.view.layer addSublayer:_preView];
    
    ///拍照
    _shoot = [UIButton buttonWithType:UIButtonTypeCustom];
    _shoot.tag = 32988;
    [_shoot setBackgroundColor:[UIColor redColor]];
    _shoot.frame = CGRectMake([UIScreen mainScreen].bounds.size.width / 2 - 15, [UIScreen mainScreen].bounds.size.height - 100, 30, 30);
    _shoot.clipsToBounds = YES;
    _shoot.layer.cornerRadius = 15;
    [_shoot addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_shoot];
    
    //最当初一张图片
    _currentImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, [UIScreen mainScreen].bounds.size.height - 130, 80, 80)];
    _currentImageView.backgroundColor = [UIColor clearColor];
    _currentImageView.clipsToBounds = YES;
    _currentImageView.layer.cornerRadius = 4.0;
    [self.view addSubview:_currentImageView];
    
    [[PhotoManager shareInstance] getLatestPhotoWithReturnType:ReturnTypeImage sourceType:SourcePhoto
                                      complete:^(id asset) {
                                          if ([asset isKindOfClass:[UIImage class]]) {
                                              UIImage *latestImage = (UIImage *)asset;
                                              _currentImageView.image = latestImage;
                                          }
                                      }];
    //最近一张图片
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonAction:)];
    _currentImageView.userInteractionEnabled = YES;
    [_currentImageView addGestureRecognizer:tap];
    
    //摄像头切换
    _toggle = [UIButton buttonWithType:UIButtonTypeCustom];
    _toggle.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 40 , 30, 30, 30);
    _toggle.tag = 32989;
    [_toggle addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    [_toggle setImage:[UIImage imageNamed:@"self"] forState:UIControlStateNormal];
    [_toggle setImage:[UIImage imageNamed:@"self"] forState:UIControlStateSelected];
    [self.view addSubview:_toggle];
    
    //闪光灯
    _flash = [UIButton buttonWithType:UIButtonTypeCustom];
    _flash.frame = CGRectMake([UIScreen mainScreen].bounds.size.width - 120, 30, 30, 30);
    [_flash addTarget:self action:@selector(switchFlash) forControlEvents:UIControlEventTouchUpInside];
    [_flash setImage:[UIImage imageNamed:@"auto"] forState:UIControlStateNormal];
    [self.view addSubview:_flash];
}

///切换前后摄像头
- (void)switchFlash {
   //直接控制系统的设备闪光灯模式
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [device lockForConfiguration:nil];
    //首先设备是否有闪光灯
    if ([device hasFlash]) {
        NSString *imageStr;
        if (device.flashMode == AVCaptureFlashModeOn) {
            device.flashMode = AVCaptureFlashModeOff;
            imageStr = @"off";
        } else if (device.flashMode == AVCaptureFlashModeOff) {
            device.flashMode = AVCaptureFlashModeAuto;
            imageStr = @"auto";
        } else if (device.flashMode == AVCaptureFlashModeAuto) {
            device.flashMode = AVCaptureFlashModeOn;
            imageStr = @"on";
        }
        [_flash setImage:[UIImage imageNamed:imageStr] forState:UIControlStateNormal];
        [device unlockForConfiguration];
    } else {
        NSLog(@"设备不支持闪光灯模式");
    }
}

#pragma mark --private Method
- (void)buttonAction:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        if (button.tag == 32988) {
            //拍照按钮点击
            if (_isVideo) {
                //录制视频
                [self startRecordVideo];
            } else  {
                //拿到AvCaptureConnection
                AVCaptureConnection *connection = [_output connectionWithMediaType:AVMediaTypeVideo];
                if (!connection) {
                    NSLog(@"take photo failed!");
                    return;
                }
                //输出得到的照片结果
                [_output captureStillImageAsynchronouslyFromConnection:connection
                                                     completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                         if (error) {
                                                             NSLog(@"phto failed and error = %@",error);
                                                             return ;
                                                         }
                                                         NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                         UIImage *resultImage = [UIImage imageWithData:imageData];
                                                         //保存相片到系统相册
                                                         UIImageWriteToSavedPhotosAlbum(resultImage, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
                                                         //添加动画
                                                         [self addAnnimationWithImage:resultImage];
                                                     }];
            }
        } else if (button.tag == 32989) {
            NSError *error;
            button.selected = !button.selected;
            AVCaptureDeviceInput *newInput = [[AVCaptureDeviceInput alloc] initWithDevice: [self deviceWithCameraPosition:button.selected ? AVCaptureDevicePositionFront:AVCaptureDevicePositionBack] error:&error];
            [_session  beginConfiguration];
            //开始提交配置信息
            [_session removeInput:[_session.inputs lastObject]];
            if ([_session canAddInput:newInput]) {
                [_session addInput:newInput];
            } else {
                [_session addInput:_input];
            }
            //提交配置信息
            [_session commitConfiguration];
        }
    }else if ([sender  isKindOfClass:[UITapGestureRecognizer class]]) {
        //进入相册
        UIImagePickerController *picker = [UIImagePickerController  new];
        picker.delegate = self;
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            NSLog(@"phtot not Avaliable!");
            return ;
        }
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:nil];
    }
}

///开始录制视频
- (void)startRecordVideo {
    if ([_movieOutput isRecording]) {
        [_movieOutput stopRecording];
    }
    _shoot.clipsToBounds = NO;
    //计时器
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                 repeats:YES
                                                   block:^(NSTimer * _Nonnull timer) {
                                                       
                                                   }];
        [[NSRunLoop currentRunLoop]  addTimer:_timer forMode:UITrackingRunLoopMode];
    }
    //开始录制视频
    [_movieOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:[[self class] getFilePathWithIsCompression:YES]] recordingDelegate:self];
}

///视频存储路径
+ (NSString *)getFilePathWithIsCompression:(BOOL)isCompression {
    //用时间给文件全名 保证其唯一性，以免重复，在测试的时候其实可以判断文件是否存在若存在，则删除，重新生成文件即可
    NSDateFormatter *formater = [NSDateFormatter new];
    [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    NSFileManager *manager = [NSFileManager defaultManager];
    BOOL isExists = [manager fileExistsAtPath:CompressionVideoPaht];
    if (!isExists) {
        //fileManager创建文件夹
        [manager createDirectoryAtPath:CompressionVideoPaht withIntermediateDirectories:YES attributes:nil error:nil];
    }
    //压缩的使用mp4做后缀，不压缩的使用mov做后缀
    NSString *fileName = [NSString stringWithFormat:@"video_%@.%@", [formater stringFromDate:[NSDate date]], isCompression ? @"mp4" : @"mov"];
    return [CompressionVideoPaht stringByAppendingPathComponent:fileName];
}

#pragma mark --录制完成
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    if ([_movieOutput isRecording]) {
        [_movieOutput stopRecording];
    }
    //保存视频到系统相册
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        //保存到系统相册
        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:outputFileURL];
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success) {
            NSLog(@"成功保存到系统相册!");
        } else {
            NSLog(@"save To PhotoLibrary Failed! error = %@",error);
        }
    }];
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
    if (error) {
        NSLog(@"error = %@",error);
    }
}

- (AVCaptureDevice *)deviceWithCameraPosition:(AVCaptureDevicePosition)position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}

///动画效果
- (void)addAnnimationWithImage:(UIImage *)image {
    _currentImageView.image = image;
    //缩小动画
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    scaleAnimation.fromValue = @(1);
    scaleAnimation.toValue = @(0.8);
    scaleAnimation.duration = 0.5;
    scaleAnimation.removedOnCompletion = NO;
    scaleAnimation.fillMode = kCAFillModeForwards;
    
    //移动路径动画
    UIBezierPath *path = [UIBezierPath new];
    [path addLineToPoint:CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2)];
    [path moveToPoint:_currentImageView.center];
    [path addQuadCurveToPoint:_currentImageView.center controlPoint:CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2)];
    //移动动画
    CAKeyframeAnimation *moveAnnimation = [CAKeyframeAnimation animation];
    moveAnnimation.path = path.CGPath;
    moveAnnimation.duration = 1.0;
    moveAnnimation.removedOnCompletion = YES;
    moveAnnimation.fillMode = kCAFillModeForwards;
    
    CAAnimationGroup *group = [CAAnimationGroup new];
    group.animations = @[scaleAnimation,moveAnnimation];
    group.duration = 1.0f;
    group.delegate = self;
    group.removedOnCompletion = YES;
    [_currentImageView.layer addAnimation:group forKey:@"group"];
}

@end
