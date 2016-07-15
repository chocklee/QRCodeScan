//
//  QRCodeScanViewController.m
//  QRCodeScan
//
//  Created by 李长浩 on 16/7/15.
//  Copyright © 2016年 chocklee. All rights reserved.
//

#import "QRCodeScanViewController.h"
#import <AVFoundation/AVFoundation.h>

static const char *kQRCodeScanQueueName = "QRCodeScanQueue";

@interface QRCodeScanViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property (nonatomic, assign) BOOL isLightOn;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineTopConstraint;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) CGFloat number;

@end

@implementation QRCodeScanViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // 添加定时器
    self.timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(animateineAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
    self.number = 1;
    // 闪光灯默认关闭
    self.isLightOn = NO;
    // 开启扫描
    [self startScan];
}

// 开始扫描
- (BOOL)startScan {
    // 获取手机硬件设备
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    // 初始化输入流
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        NSLog(@"%@",[error localizedDescription]);
        return NO;
    }
    // 创建会话
    _captureSession = [[AVCaptureSession alloc] init];
    // 添加输入流
    [_captureSession addInput:input];
    // 初始化输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
    // 添加输出流
    [_captureSession addOutput:output];
    // 创建dispatch queue
    dispatch_queue_t queue = dispatch_queue_create(kQRCodeScanQueueName, DISPATCH_QUEUE_CONCURRENT);
    //扫描的结果苹果是通过代理的方式区回调，所以outPut需要添加代理，并且因为扫描是耗时的工作，所以把它放到子线程里面
    [output setMetadataObjectsDelegate:self queue:queue];
    // 设置支持二维码和条形码扫描
    [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
    // 创建输出对象
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    [_previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    _previewLayer.frame = self.view.bounds;
    [self.view.layer insertSublayer:_previewLayer atIndex:0];
    // 开始会话
    [_captureSession startRunning];
    return YES;
}

// 结束扫描
- (void)stopScan {
    // 停止会话
    [_captureSession stopRunning];
    _captureSession = nil;
}

#pragma mark -- AVCaptureMetadataOutputObjectsDelegate
// 扫描结果的代理回调方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects != nil && metadataObjects.count > 0) {
        // 扫描到之后，停止扫描
        [self stopScan];
        [self.timer invalidate];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.navigationController popViewControllerAnimated:YES];
        });
        // 获取结果并对其进行处理
        AVMetadataMachineReadableCodeObject *object = metadataObjects.firstObject;
        if ([[object type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            NSString *result = object.stringValue;
            // 处理result
            NSLog(@"%@",result);
        } else {
            NSLog(@"不是二维码");
        }
    }
}

// 开启和关闭闪光灯
- (IBAction)didClickedLightUpButton:(UIButton *)sender {
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //判断手机是否有闪光灯
    if ([device hasTorch]) {
        //呼叫手机操作系统，控制手机硬件
        NSError *error = nil;
        [device lockForConfiguration:&error];
        if (self.isLightOn == NO) {
            [device setTorchMode:AVCaptureTorchModeOn];
            self.isLightOn = YES;
        } else {
            [device setTorchMode:AVCaptureTorchModeOff];
            self.isLightOn = NO;
        }
    }
    //结束对硬件的控制，跟上面的lockForConfiguration是配对的API
    [device unlockForConfiguration];
}

- (void)animateineAction {
    if (self.lineTopConstraint.constant < 320) {
        self.lineTopConstraint.constant = 95 + self.number;
        self.number += 2;
    } else {
        self.lineTopConstraint.constant = 95;
        self.number = 1;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
