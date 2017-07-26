//
//  CameraVC.h
//  TestGit
//
//  Created by Chan on 2017/7/20.
//  Copyright © 2017年 Chan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
@interface CameraVC : UIViewController

@property(nonatomic,strong) AVCaptureSession *session;  //全局会话

@property(nonatomic,strong) AVCaptureDeviceInput *input;   //输入流

@property(nonatomic,strong) AVCaptureDevice  *device;   //设备

@property(nonatomic,strong) AVCaptureStillImageOutput *output;  //输出流 (照片)

@property(nonatomic,strong) AVCaptureVideoPreviewLayer *preView; //预览曾

@property(nonatomic, assign) BOOL isVideo;  //是否是录制视频

@end
