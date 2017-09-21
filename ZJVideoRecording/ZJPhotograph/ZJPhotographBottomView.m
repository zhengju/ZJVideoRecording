//
//  ZJPhotographBottomView.m
//  ZJVideoRecording
//
//  Created by zhengju on 2017/9/21.
//  Copyright © 2017年 郑俱. All rights reserved.
//

#import "ZJPhotographBottomView.h"

@interface ZJPhotographBottomView()
/**
 拍照按钮
 */
@property(strong,nonatomic) UIButton * photographBtn;

@end


@implementation ZJPhotographBottomView
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
    self.photographBtn = [[UIButton alloc]init];
    [self.photographBtn setImage:[UIImage imageNamed:@"拍照"] forState:UIControlStateNormal];
    [self addSubview:self.photographBtn];
    //frame
    [self.photographBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(self).offset(0);
        make.centerX.mas_equalTo(self.mas_centerX);
        make.width.height.mas_equalTo(64);
    }];
    WeakObj(self);
    [self.photographBtn bk_addEventHandler:^(id sender) {
        if ([selfWeak.delegate respondsToSelector:@selector(photographAction)]) {
            [selfWeak.delegate photographAction];
        }
    } forControlEvents:UIControlEventTouchUpInside];

}
@end
