//
//  CaptureVC.m
//  AssetLibPhotoKitDemo
//
//  Created by Chan on 2017/7/25.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import "CaptureVC.h"
#import <AVFoundation/AVFoundation.h>
#define CompressionVideoPaht [NSHomeDirectory() stringByAppendingFormat:@"/Documents/Compression"]

@interface CaptureVC () <AVCaptureFileOutputRecordingDelegate> {
    AVCaptureSession *_session;
    AVCaptureDeviceInput *_input;
    AVCaptureDevice *_device;
    AVCaptureStillImageOutput *_output;
    AVCaptureVideoPreviewLayer *_preView;
    
    AVCaptureDeviceInput *_audioInput;
    AVCaptureMovieFileOutput *_movieoutput;
}

@end

@implementation CaptureVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (![_session isRunning]) {
        [_session startRunning];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if ([_session isRunning]) {
        [_session stopRunning];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    _session  = [[AVCaptureSession alloc] init];
    if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
    }
    
    //设备
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //设置设备闪光灯模式
    [_device lockForConfiguration:nil];
    [_device setSmoothAutoFocusEnabled:YES];
    [_device setFlashMode:AVCaptureFlashModeAuto];
    [_device unlockForConfiguration];
    
    //输入
    NSError *error;
    _input = [AVCaptureDeviceInput  deviceInputWithDevice:_device error:&error];
    if (error) {
        NSLog(@"error = %@",error);
    }
    //输出设备
    _output = [AVCaptureStillImageOutput new];
    //设置输出参数
    [_output setOutputSettings:@{AVVideoCodecKey:AVVideoCodecJPEG}];
    
    //录制视频
    if (_isVideo) {
        _movieoutput = [[AVCaptureMovieFileOutput alloc] init];
        if ([_session canAddOutput:_movieoutput]) {
            [_session addOutput:_movieoutput];
        }
        //创建麦克风设备
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        _audioInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
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
    //预览层
    _preView = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preView.frame = self.view.bounds;
    [self.view.layer addSublayer:_preView];
    
}

#pragma mark --private Method
- (void)buttonAction:(id)sender {
    if ( [sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        if (button.tag ==3728372 ) {
            if (_isVideo) {
                if ([_movieoutput isRecording]) {
                    [_movieoutput stopRecording];
                }
                [_movieoutput  startRecordingToOutputFileURL:[NSURL fileURLWithPath:[[self class] getFilePathWithIsCompression:YES]] recordingDelegate:self];
            } else {
                AVCaptureConnection *connection = [_output connectionWithMediaType:AVMediaTypeVideo];
                if (connection) {
                    ////获取输出
                    [_output captureStillImageAsynchronouslyFromConnection:connection
                                                         completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                             if (!error) {
                                                                 //获取输出照片
                                                                 //+ (NSData *)jpegStillImageNSDataRepresentation:(CMSampleBufferRef)jpegSampleBuffer;
                                                                 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                                 if (imageData) {
                                                                     //转换为图片
                                                                     UIImage *resultImage = [[UIImage alloc] initWithData:imageData];
                                                                     if (resultImage) {
                                                                         //保存到系统相册
                                                                         UIImageWriteToSavedPhotosAlbum(resultImage, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
                                                                     }
                                                                 }
                                                                 
                                                             } else {
                                                                 NSLog(@"error = %@",error);
                                                             }
                                                         }];
                }
            }
        }
    }
}

#pragma mark --录制完成
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error {
    NSLog(@"outputFileURL = %@",outputFileURL);
    if (error) {
        NSLog(@"error = %@",error);
        return ;
    }
}

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
@end
