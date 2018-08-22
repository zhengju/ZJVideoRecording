//
//  ZJVideoView.h
//  ZJVideoRecording
//
//  Created by leeco on 2018/8/21.
//  Copyright © 2018年 郑俱. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZJModel.h"
@protocol ZJVideoViewDelegate <NSObject>

-(void)dismissVC;
-(void)recordFinishWithvideoUrl:(NSURL *)videoUrl;

@end
@interface ZJVideoView : UIView
@property (nonatomic, assign) ZJVideoViewType viewType;
@property (nonatomic, strong, readonly) ZJModel *fmodel;
@property (nonatomic, weak) id <ZJVideoViewDelegate> delegate;

- (instancetype)initWithFMVideoViewType:(ZJVideoViewType)type;
- (void)reset;
@end
