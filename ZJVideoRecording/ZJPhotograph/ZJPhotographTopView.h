//
//  ZJPhotographTopView.h
//  ZJVideoRecording
//
//  Created by zhengju on 2017/9/21.
//  Copyright © 2017年 郑俱. All rights reserved.
//头部控制栏

#import <UIKit/UIKit.h>
#import "ZJCommonHeader.h"


@protocol ZJPhotographTopViewDelegate <NSObject>

- (void)switchAction;

@end

@interface ZJPhotographTopView : UIView
@property(weak,nonatomic) id<ZJPhotographTopViewDelegate> delegate;
@end
