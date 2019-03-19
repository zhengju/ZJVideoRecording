//
//  ViewController.m
//  ZJVideoRecording
//
//  Created by zhengju on 2017/9/18.
//  Copyright © 2017年 郑俱. All rights reserved.
//

#import "ViewController.h"
#import "ZJPhotograph.h"
#import "ZJVideoController.h"
#import <GPUImage/GPUImage.h>
#import "GPUImageBeautifyFilter.h"
@interface ViewController ()<GPUImageVideoCameraDelegate>
@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;//输出源
@property (nonatomic, strong) GPUImageView *filterView;//输出源
@property(strong, nonatomic) GPUImageFilter *mFilter;//滤镜
@property(strong, nonatomic) UIImageView *videoImg;//滤镜
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];

    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.videoCamera.delegate = self;
    
    self.filterView = [[GPUImageView alloc] initWithFrame:self.view.frame];
    self.filterView.center = self.view.center;
    
    [self.view addSubview:self.filterView];
    
    
    GPUImageView * view = [[GPUImageView alloc]initWithFrame:CGRectMake(0, 0, 200, 200)];
    
    [self.view addSubview:view];
    
   [self.videoCamera addTarget:view];
   
    
    
    _mFilter = [[GPUImageBeautifyFilter alloc]init];
    [self.videoCamera addTarget:_mFilter];
    [_mFilter addTarget:self.filterView];
    
    
    [self.videoCamera startCameraCapture];
    
//    self.videoImg = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 200, 200)];
//    self.videoImg.backgroundColor = [UIColor redColor];
//    [self.view addSubview:self.videoImg];
    
    
    
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    ZJPhotograph * vc  = [[ZJPhotograph alloc]init];
//
//    [self.navigationController pushViewController:vc animated:NO];
    
//    ZJVideoController * videoController = [[ZJVideoController alloc]init];
//     [self.navigationController pushViewController:videoController animated:NO];

}
- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    // Create a UIImage from the sample buffer data
    UIImage *img = [self imageFromSampleBuffer:sampleBuffer];
    
    
     dispatch_async(dispatch_get_main_queue(), ^{
     self.videoImg.image=img;
     });
     
}
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer
{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    return (image);
}
@end
