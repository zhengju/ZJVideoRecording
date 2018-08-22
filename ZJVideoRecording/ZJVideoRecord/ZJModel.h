//
//  ZJModel.h
//  ZJVideoRecording
//
//  Created by leeco on 2018/8/21.
//  Copyright © 2018年 郑俱. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ZJAssetWriteManager.h"


//闪光灯状态
typedef NS_ENUM(NSInteger, ZJFlashState) {
    ZJFlashClose = 0,
    ZJFlashOpen,
    ZJFlashAuto,
};

@protocol ZJModelDelegate <NSObject>

- (void)updateFlashState:(ZJFlashState)state;
- (void)updateRecordingProgress:(CGFloat)progress;
- (void)updateRecordState:(ZJRecordState)recordState;

@end
@interface ZJModel : NSObject
@property (nonatomic, weak  ) id<ZJModelDelegate>delegate;
@property (nonatomic, assign) ZJRecordState recordState;
@property (nonatomic, strong, readonly) NSURL *videoUrl;
- (instancetype)initWithFMVideoViewType:(ZJVideoViewType )type superView:(UIView *)superView;

- (void)turnCameraAction;
- (void)switchflash;
- (void)startRecord;
- (void)stopRecord;
- (void)reset;
@end
