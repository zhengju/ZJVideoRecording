//
//  ZJPhotographTopView.m
//  ZJVideoRecording
//
//  Created by zhengju on 2017/9/21.
//  Copyright © 2017年 郑俱. All rights reserved.
//

#import "ZJPhotographTopView.h"

@interface ZJPhotographTopView()
/**
 切换按钮
 */
@property(strong,nonatomic) UIButton * switchBtn;

@end


@implementation ZJPhotographTopView

- (instancetype)init{
    if (self = [super init]) {
        
    }
    return self;
}
- (void)layoutSubviews{
    [super layoutSubviews];
    [self configureUI];
}
- (void)configureUI{
    self.switchBtn = [[UIButton alloc]init];
    [self.switchBtn setImage:[UIImage imageNamed:@"切换"] forState:UIControlStateNormal];
    [self addSubview:self.switchBtn];
    //frame
    [self.switchBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(self).offset(-10);
        make.centerY.mas_equalTo(self.mas_centerY);
        make.width.height.mas_equalTo(35);
    }];
    WeakObj(self);
    [self.switchBtn bk_addEventHandler:^(id sender) {
        if ([selfWeak.delegate respondsToSelector:@selector(switchAction)]) {
            [selfWeak.delegate switchAction];
        }
    } forControlEvents:UIControlEventTouchUpInside];
    
}

@end
