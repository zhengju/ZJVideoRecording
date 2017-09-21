//
//  ZJPhotographBottomView.h
//  ZJVideoRecording
//
//  Created by zhengju on 2017/9/21.
//  Copyright © 2017年 郑俱. All rights reserved.
//底部控制栏

#import <UIKit/UIKit.h>
#import "ZJCommonHeader.h"


@protocol ZJPhotographBottomViewDelegate <NSObject>

- (void)photographAction;

@end

@interface ZJPhotographBottomView : UIView
@property(weak,nonatomic) id<ZJPhotographBottomViewDelegate> delegate;
@end
