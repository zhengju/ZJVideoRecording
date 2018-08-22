//
//  ZJAssetWriteManager.h
//  ZJVideoRecording
//
//  Created by leeco on 2018/8/21.
//  Copyright © 2018年 郑俱. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

//录制状态，（这里把视频录制与写入合并成一个状态）
typedef NS_ENUM(NSInteger, ZJRecordState) {
    ZJRecordStateInit = 0,
    ZJRecordStatePrepareRecording,
    ZJRecordStateRecording,
    ZJRecordStateFinish,
    ZJRecordStateFail,
};
//录制视频的长宽比
typedef NS_ENUM(NSInteger, ZJVideoViewType) {
    Type1X1 = 0,
    Type4X3,
    TypeFullScreen
};


@protocol ZJAssetWriteManagerDelegate <NSObject>

- (void)finishWriting;
- (void)updateWritingProgress:(CGFloat)progress;

@end

@interface ZJAssetWriteManager : NSObject
@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property (nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;

@property (nonatomic, assign) ZJRecordState writeState;
@property (nonatomic, weak) id <ZJAssetWriteManagerDelegate> delegate;
- (instancetype)initWithURL:(NSURL *)URL viewType:(ZJVideoViewType )type;

- (void)startWrite;
- (void)stopWrite;
- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType;
- (void)destroyWrite;
@end
