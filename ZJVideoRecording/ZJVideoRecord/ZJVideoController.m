//
//  ZJVideoController.m
//  ZJVideoRecording
//
//  Created by leeco on 2018/8/21.
//  Copyright © 2018年 郑俱. All rights reserved.
//

#import "ZJVideoController.h"
#import "ZJVideoView.h"
#import "FMVideoPlayController.h"
@interface ZJVideoController ()<ZJVideoViewDelegate>
@property (nonatomic, strong)ZJVideoView *videoView;

@end

@implementation ZJVideoController


- (BOOL)prefersStatusBarHidden{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.hidden = YES;
    
    _videoView  =[[ZJVideoView alloc] initWithFMVideoViewType:TypeFullScreen];
    _videoView.delegate = self;
    [self.view addSubview:_videoView];
    self.view.backgroundColor = [UIColor blackColor];
    
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_videoView.fmodel.recordState == ZJRecordStateFinish) {
        [_videoView.fmodel reset];
    }
}


- (void)dismissVC
{
    if ([self.navigationController.childViewControllers count] > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
    
}


- (void)recordFinishWithvideoUrl:(NSURL *)videoUrl
{
    FMVideoPlayController *playVC = [[FMVideoPlayController alloc] init];
    playVC.videoUrl =  videoUrl;
    [self.navigationController pushViewController:playVC animated:YES];
    
    
    
}

@end
