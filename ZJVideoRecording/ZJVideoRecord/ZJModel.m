//
//  ZJModel.m
//  ZJVideoRecording
//
//  Created by leeco on 2018/8/21.
//  Copyright © 2018年 郑俱. All rights reserved.
//

#import "ZJModel.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "XCFileManager.h"
#import "ZJAssetWriteManager.h"
@interface ZJModel()<AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, ZJAssetWriteManagerDelegate>
{
    AVURLAsset * videoAsset;
    CADisplayLink  *dlink;
    AVAssetExportSession *exporter;
}
@property (nonatomic, weak) UIView *superView;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) dispatch_queue_t videoQueue;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewlayer;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;

@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;

@property (nonatomic, strong)ZJAssetWriteManager *writeManager;

@property (nonatomic, strong, readwrite) NSURL *videoUrl;
@property (nonatomic, strong, readwrite) NSURL *videoUrl2;
@property (strong,nonatomic)  UIImageView *focusCursor; //聚焦光标

@property (nonatomic, assign) ZJFlashState flashState;
@property (nonatomic, assign) ZJVideoViewType viewType;
@end
@implementation ZJModel
- (instancetype)initWithFMVideoViewType:(ZJVideoViewType)type superView:(UIView *)superView
{
    self = [super init];
    if (self) {
        _superView = superView;
        _viewType = type;
        [self setUpWithType:type];
    }
    return self;
}

#pragma mark - lazy load
- (AVCaptureSession *)session
{
    // 录制5秒钟视频 高画质10M,压缩成中画质 0.5M
    // 录制5秒钟视频 中画质0.5M,压缩成中画质 0.5M
    // 录制5秒钟视频 低画质0.1M,压缩成中画质 0.1M
    if (!_session) {
        _session = [[AVCaptureSession alloc] init];
        if ([_session canSetSessionPreset:AVCaptureSessionPresetHigh]) {//设置分辨率
            _session.sessionPreset=AVCaptureSessionPresetHigh;
        }
    }
    return _session;
}

- (dispatch_queue_t)videoQueue
{
    if (!_videoQueue) {
        _videoQueue = dispatch_queue_create("com.5miles", DISPATCH_QUEUE_SERIAL);
    }
    return _videoQueue;
}
- (AVCaptureVideoPreviewLayer *)previewlayer
{
    if (!_previewlayer) {
        _previewlayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
        _previewlayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    return _previewlayer;
}

- (void)setRecordState:(ZJRecordState)recordState
{
    if (_recordState != recordState) {
        _recordState = recordState;
        if (self.delegate && [self.delegate respondsToSelector:@selector(updateRecordState:)]) {
            [self.delegate updateRecordState:_recordState];
        }
    }
}

- (UIImageView *)focusCursor
{
    if (!_focusCursor) {
        _focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(100, 100, 50, 50)];
        _focusCursor.image = [UIImage imageNamed:@"focusImg"];
        _focusCursor.alpha = 0;
    }
    return _focusCursor;
}
#pragma mark - setup
- (void)setUpWithType:(ZJVideoViewType )type
{
    ///1. 初始化捕捉会话，数据的采集都在会话中处理
    [self setUpInit];
    ///2. 设置视频的输入输出
    [self setUpVideo];

    ///3. 设置音频的输入输出
    [self setUpAudio];
    
    ///4. 视频的预览层
    [self setUpPreviewLayerWithType:type];
    
    ///5. 开始采集画面
    [self.session startRunning];
    
    /// 6. 初始化writer， 用writer 把数据写入文件
    [self setUpWriter];
    
    /// 7. 增加聚焦功能（可有可无）
    [self addFocus];
}

- (void)setUpVideo
{
    // 2.1 获取视频输入设备(摄像头)
    AVCaptureDevice *videoCaptureDevice=[self getCameraDeviceWithPosition:AVCaptureDevicePositionBack];//取得后置摄像头
    // 2.2 创建视频输入源
    NSError *error=nil;
    self.videoInput= [[AVCaptureDeviceInput alloc] initWithDevice:videoCaptureDevice error:&error];
    // 2.3 将视频输入源添加到会话
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoOutput.alwaysDiscardsLateVideoFrames = YES; //立即丢弃旧帧，节省内存，默认YES
    [self.videoOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if ([self.session canAddOutput:self.videoOutput]) {
        [self.session addOutput:self.videoOutput];
    }
    
}
- (void)setUpAudio
{
    // 2.2 获取音频输入设备
    AVCaptureDevice *audioCaptureDevice=[[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    NSError *error=nil;
    // 2.4 创建音频输入源
    self.audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioCaptureDevice error:&error];
    // 2.6 将音频输入源添加到会话
    if ([self.session canAddInput:self.audioInput]) {
        [self.session addInput:self.audioInput];
    }
    
    self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [self.audioOutput setSampleBufferDelegate:self queue:self.videoQueue];
    if([self.session canAddOutput:self.audioOutput]) {
        [self.session addOutput:self.audioOutput];
    }
    
}

- (void)setUpPreviewLayerWithType:(ZJVideoViewType )type
{
    CGRect rect = CGRectZero;
    switch (type) {
        case Type1X1:
            rect = CGRectMake(0, 0, kScreenWidth, kScreenWidth);
            break;
        case Type4X3:
            rect = CGRectMake(0, 0, kScreenWidth, kScreenWidth*4/3);
            break;
        case TypeFullScreen:
            rect = [UIScreen mainScreen].bounds;
            break;
        default:
            rect = [UIScreen mainScreen].bounds;
            break;
    }
    
    self.previewlayer.frame = rect;
    [_superView.layer insertSublayer:self.previewlayer atIndex:0];
}

- (void)setUpWriter
{
    self.videoUrl = [[NSURL alloc] initFileURLWithPath:[self createVideoFilePath]];
    self.writeManager = [[ZJAssetWriteManager alloc] initWithURL:self.videoUrl viewType:_viewType];
    self.writeManager.delegate = self;
    
}
//添加视频聚焦
- (void)addFocus
{
    [self.superView addSubview:self.focusCursor];
    UITapGestureRecognizer *tapGesture= [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
    [self.superView addGestureRecognizer:tapGesture];
}
-(void)tapScreen:(UITapGestureRecognizer *)tapGesture{
    CGPoint point= [tapGesture locationInView:self.superView];
    //将UI坐标转化为摄像头坐标
    CGPoint cameraPoint= [self.previewlayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}
-(void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusCursor.center=point;
    self.focusCursor.transform=CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha=1.0;
    [UIView animateWithDuration:1.0 animations:^{
        self.focusCursor.transform=CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha=0;
        
    }];
}
//设置聚焦点
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}
-(void)changeDeviceProperty:(void(^)(AVCaptureDevice *captureDevice))propertyChange{
    AVCaptureDevice *captureDevice= [self.videoInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}
#pragma mark - public method
//切换摄像头
- (void)turnCameraAction
{
    [self.session stopRunning];
    // 1. 获取当前摄像头
    AVCaptureDevicePosition position = self.videoInput.device.position;
    
    //2. 获取当前需要展示的摄像头
    if (position == AVCaptureDevicePositionBack) {
        position = AVCaptureDevicePositionFront;
    } else {
        position = AVCaptureDevicePositionBack;
    }
    
    // 3. 根据当前摄像头创建新的device
    AVCaptureDevice *device = [self getCameraDeviceWithPosition:position];
    
    // 4. 根据新的device创建input
    AVCaptureDeviceInput *newInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    
    //5. 在session中切换input
    [self.session beginConfiguration];
    [self.session removeInput:self.videoInput];
    [self.session addInput:newInput];
    [self.session commitConfiguration];
    self.videoInput = newInput;
    
    [self.session startRunning];
    
}


- (void)switchflash
{
    if(_flashState == ZJFlashClose){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeOn];
            [self.videoInput.device unlockForConfiguration];
            _flashState = ZJFlashOpen;
        }
    }else if(_flashState == ZJFlashOpen){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeAuto];
            [self.videoInput.device unlockForConfiguration];
            _flashState = ZJFlashAuto;
        }
    }else if(_flashState == ZJFlashAuto){
        if ([self.videoInput.device hasTorch]) {
            [self.videoInput.device lockForConfiguration:nil];
            [self.videoInput.device setTorchMode:AVCaptureTorchModeOff];
            [self.videoInput.device unlockForConfiguration];
            _flashState = ZJFlashClose;
        }
    };
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateFlashState:)]) {
        [self.delegate updateFlashState:_flashState];
    }
    
}


- (void)startRecord
{
    if (self.recordState == ZJRecordStateInit) {
        [self.writeManager startWrite];
        self.recordState = ZJRecordStateRecording;
    }
}

- (void)stopRecord
{
    
    [self.writeManager stopWrite];
    [self.session stopRunning];
    self.recordState = ZJRecordStateFinish;
    
}

- (void)reset
{
    self.recordState = ZJRecordStateInit;
    [self.session startRunning];
    [self setUpWriter];
    
}


#pragma mark - private method
//初始化设置
- (void)setUpInit
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBack) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive) name:UIApplicationWillEnterForegroundNotification object:nil];
    [self clearFile];
    _recordState = ZJRecordStateInit;
}
//存放视频的文件夹
- (NSString *)videoFolder
{
    NSString *cacheDir = [XCFileManager cachesDir];
    NSString *direc = [cacheDir stringByAppendingPathComponent:VIDEO_FOLDER];
    if (![XCFileManager isExistsAtPath:direc]) {
        [XCFileManager createDirectoryAtPath:direc];
    }
    return direc;
}
//清空文件夹
- (void)clearFile
{
    [XCFileManager removeItemAtPath:[self videoFolder]];
    
}
//写入的视频路径
- (NSString *)createVideoFilePath
{
    NSString *videoName = [NSString stringWithFormat:@"%@.mp4", [NSUUID UUID].UUIDString];
    NSString *path = [[self videoFolder] stringByAppendingPathComponent:videoName];
    return path;
    
}

#pragma mark - 获取摄像头
-(AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition )position{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}


#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate AVCaptureAudioDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {
        
        //视频
        if (connection == [self.videoOutput connectionWithMediaType:AVMediaTypeVideo]) {
            
            if (!self.writeManager.outputVideoFormatDescription) {
                @synchronized(self) {
                    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                    self.writeManager.outputVideoFormatDescription = formatDescription;
                }
            } else {
                @synchronized(self) {
                    if (self.writeManager.writeState == ZJRecordStateRecording) {
                        [self.writeManager appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
                    }
                    
                }
            }
            
            
        }
        
        //音频
        if (connection == [self.audioOutput connectionWithMediaType:AVMediaTypeAudio]) {
            if (!self.writeManager.outputAudioFormatDescription) {
                @synchronized(self) {
                    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);
                    self.writeManager.outputAudioFormatDescription = formatDescription;
                }
            }
            @synchronized(self) {
                
                if (self.writeManager.writeState == ZJRecordStateRecording) {
                    [self.writeManager appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
                }
                
            }
            
        }
    }
    
}


#pragma mark - AVAssetWriteManagerDelegate
- (void)updateWritingProgress:(CGFloat)progress
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(updateRecordingProgress:)]) {
        [self.delegate updateRecordingProgress:progress];
    }
}

- (void)finishWriting
{
    [self.session stopRunning];
    self.recordState = ZJRecordStateFinish;
}
#pragma mark - notification
- (void)enterBack
{
    self.videoUrl = nil;
    [self.session stopRunning];
    [self.writeManager destroyWrite];
    
}

- (void)becomeActive
{
    [self reset];
}
///使用AVfoundation添加水印
- (void)AVsaveVideoPath:(NSURL*)videoPath WithWaterImg:(UIImage*)img WithCoverImage:(UIImage*)coverImg WithQustion:(NSString*)question WithFileName:(NSString*)fileName withCallBack:(void (^)())callback
{
    
    
//    videoPath = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"sintel" ofType:@"mov"]];
    
    if (!videoPath) {
        return;
    }
    
    //1 创建AVAsset实例 AVAsset包含了video的所有信息 self.videoUrl输入视频的路径
    
    //封面图片
    NSDictionary *opts = [NSDictionary dictionaryWithObject:@(YES) forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    videoAsset = [AVURLAsset URLAssetWithURL:videoPath options:opts];     //初始化视频媒体文件
    
    CMTime startTime = CMTimeMakeWithSeconds(0.2, 600);
    CMTime endTime = CMTimeMakeWithSeconds(videoAsset.duration.value/videoAsset.duration.timescale-0.2, videoAsset.duration.timescale);
    
    //声音采集
    AVURLAsset * audioAsset = [[AVURLAsset alloc] initWithURL:videoPath options:opts];
    
    //2 创建AVMutableComposition实例. apple developer 里边的解释 【AVMutableComposition is a mutable subclass of AVComposition you use when you want to create a new composition from existing assets. You can add and remove tracks, and you can add, remove, and scale time ranges.】
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    
    //3 视频通道  工程文件中的轨道，有音频轨、视频轨等，里面可以插入各种对应的素材
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    //把视频轨道数据加入到可变轨道中 这部分可以做视频裁剪TimeRange
    [videoTrack insertTimeRange:CMTimeRangeMake(startTime, endTime)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero error:nil];
    //音频通道
    AVMutableCompositionTrack * audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
    //音频采集通道
    AVAssetTrack * audioAssetTrack = [[audioAsset tracksWithMediaType:AVMediaTypeAudio] firstObject];
    [audioTrack insertTimeRange:CMTimeRangeMake(startTime, endTime) ofTrack:audioAssetTrack atTime:kCMTimeZero error:nil];
    
    //3.1 AVMutableVideoCompositionInstruction 视频轨道中的一个视频，可以缩放、旋转等
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration);
    
    // 3.2 AVMutableVideoCompositionLayerInstruction 一个视频轨道，包含了这个轨道上的所有视频素材
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    //    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        //        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    //    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
    //        videoAssetOrientation_ =  UIImageOrientationUp;
    //    }
    //    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
    //        videoAssetOrientation_ = UIImageOrientationDown;
    //    }
   // [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];//注释之后MP4格式的视频可以显示
    [videolayerInstruction setOpacity:0.0 atTime:endTime];
    // 3.3 - Add instructions
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];
    //AVMutableVideoComposition：管理所有视频轨道，可以决定最终视频的尺寸，裁剪需要在这里进行
    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
    
    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }
    
    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 25);
    [self applyVideoEffectsToComposition:mainCompositionInst WithWaterImg:img WithCoverImage:coverImg WithQustion:question size:CGSizeMake(renderWidth, renderHeight)];
    
    // 4 - 输出路径
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4",fileName]];
    unlink([myPathDocs UTF8String]);
    NSURL* videoUrl = [NSURL fileURLWithPath:myPathDocs];
    
    dlink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateProgress)];
    [dlink setFrameInterval:15];
    [dlink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [dlink setPaused:NO];
    // 5 - 视频文件输出
    
    exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=videoUrl;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            //这里是输出视频之后的操作，做你想做的
            [self exportDidFinish:exporter];
            if (callback) {
                self.videoUrl2 = videoUrl;
                callback();
            }
            
        });
    }];
    
}
- (void)exportDidFinish:(AVAssetExportSession *)exporter{
    
}
- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition WithWaterImg:(UIImage*)img WithCoverImage:(UIImage*)coverImg WithQustion:(NSString*)question  size:(CGSize)size {
    
    UIFont *font = [UIFont systemFontOfSize:30.0];
    CATextLayer *subtitle1Text = [[CATextLayer alloc] init];
    [subtitle1Text setFontSize:30];
    [subtitle1Text setString:question];
    [subtitle1Text setAlignmentMode:kCAAlignmentCenter];
    [subtitle1Text setForegroundColor:[[UIColor whiteColor] CGColor]];
    subtitle1Text.masksToBounds = YES;
    subtitle1Text.cornerRadius = 23.0f;
    [subtitle1Text setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5].CGColor];
    CGSize textSize = [question sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:font,NSFontAttributeName, nil]];
    [subtitle1Text setFrame:CGRectMake(50, 100, textSize.width+20, textSize.height+10)];
    
    //水印
    CALayer *imgLayer = [CALayer layer];
    imgLayer.contents = (id)img.CGImage;
    //    imgLayer.bounds = CGRectMake(0, 0, size.width, size.height);
    imgLayer.bounds = CGRectMake(0, 0, 210, 50);
    imgLayer.position = CGPointMake(size.width/2.0, size.height/2.0);
    
    //第二个水印
    CALayer *coverImgLayer = [CALayer layer];
    coverImgLayer.contents = (id)coverImg.CGImage;
    //    [coverImgLayer setContentsGravity:@"resizeAspect"];
    coverImgLayer.bounds =  CGRectMake(50, 200,210, 50);
    coverImgLayer.position = CGPointMake(size.width/4.0, size.height/4.0);
    
    // 2 - The usual overlay
    CALayer *overlayLayer = [CALayer layer];
    [overlayLayer addSublayer:subtitle1Text];
    [overlayLayer addSublayer:imgLayer];
    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [overlayLayer setMasksToBounds:YES];
    
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];
    [parentLayer addSublayer:coverImgLayer];
    
    //设置封面
    CABasicAnimation *anima = [CABasicAnimation animationWithKeyPath:@"opacity"];
    anima.fromValue = [NSNumber numberWithFloat:1.0f];
    anima.toValue = [NSNumber numberWithFloat:0.0f];
    anima.repeatCount = 0;
    anima.duration = 5.0f;  //5s之后消失
    [anima setRemovedOnCompletion:NO];
    [anima setFillMode:kCAFillModeForwards];
    anima.beginTime = AVCoreAnimationBeginTimeAtZero;
    [coverImgLayer addAnimation:anima forKey:@"opacityAniamtion"];
    
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
}

//更新生成进度
- (void)updateProgress {
   // [SVProgressHUD showProgress:exporter.progress status:NSLocalizedString(@"生成中...", nil)];
    if (exporter.progress>=1.0) {
        [dlink setPaused:true];
        [dlink invalidate];
        //        [SVProgressHUD dismiss];
    }
}

- (void)destroy
{
    [self.session stopRunning];
    self.session = nil;
    self.videoQueue = nil;
    self.videoOutput = nil;
    self.videoInput = nil;
    self.audioOutput = nil;
    self.audioInput = nil;
    [self.writeManager destroyWrite];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    [self destroy];
    
}
@end
