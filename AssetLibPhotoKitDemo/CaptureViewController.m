//
//  CaptureViewController.m
//  AssetLibPhotoKitDemo
//
//  Created by Chan on 2017/7/26.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import "CaptureViewController.h"
#import <AVFoundation/AVFoundation.h>
#define CompressionVideoPaht [NSHomeDirectory() stringByAppendingFormat:@"/Documents/Compression"]

@interface CaptureViewController () {
    AVCaptureSession *_session;
    AVCaptureDevice *_device;
    AVCaptureDeviceInput *_input;
    AVCaptureStillImageOutput  *_output;
    AVCaptureVideoPreviewLayer *_preView;
    
    UIImage *_resultImage;
    
    AVCaptureMovieFileOutput *_movieoutput;
}

@end

@implementation CaptureViewController

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
    _session = [AVCaptureSession new];
    if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [_session canSetSessionPreset:AVCaptureSessionPresetHigh];
    }
    //设备
    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    [_device lockForConfiguration:nil];
    [_device setFlashMode:AVCaptureFlashModeAuto];
    [_device unlockForConfiguration];
    
    //输入
    NSError *error;
    _input = [AVCaptureDeviceInput deviceInputWithDevice:_device error:&error];
    if (error) {
        NSLog(@"error = %@",error);
    }
    //输出
    _output = [AVCaptureStillImageOutput new];
    [_output setOutputSettings:@{AVVideoCodecKey:AVVideoCodecJPEG}];
    
    if ([_session canAddInput:_input]) {
        [_session addInput:_input];
    }
    if ([_session canAddOutput:_output]) {
        [_session addOutput:_output];
    }
    
    //预览
    _preView = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    _preView.frame = self.view.bounds;
    [self.view.layer addSublayer:_preView];
}

#pragma mark --private Method
- (void)buttonAction:(id)sender {
    if ( [sender isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)sender;
        if (button.tag ==3273343 ) {
            if (!_isVideo) {
                AVCaptureConnection *connection = [_output connectionWithMediaType:AVMediaTypeVideo];
                if (connection) {
                    [_output captureStillImageAsynchronouslyFromConnection:connection
                                                         completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                             if (imageDataSampleBuffer) {
                                                                 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                                 if (imageData) {
                                                                     _resultImage = [UIImage imageWithData:imageData];
                                                                    UIImageWriteToSavedPhotosAlbum(_resultImage, self, @selector(image:didFinishSavingWithError:contextInfo:), (__bridge void *)self);
                                                                 }
                                                             }
                                                         }];
                }
            } else  if (_isVideo){
                //视频
                [_movieoutput  startRecordingToOutputFileURL:[NSURL fileURLWithPath:[[self class] getFilePathWithIsCompression:YES]] recordingDelegate:self];
            }
        }
    }
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

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    NSLog(@"image = %@, error = %@, contextInfo = %@", image, error, contextInfo);
    if (error) {
        NSLog(@"error = %@",error);
    }
}
@end
