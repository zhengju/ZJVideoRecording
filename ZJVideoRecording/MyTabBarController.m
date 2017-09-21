//
//  MyTabBarController.m
//  TabBar_Demo
//
//  Created by zhengju on 16/11/18.
//  Copyright © 2016年 zhengju. All rights reserved.
//

#import "MyTabBarController.h"

#import "ZJNavigationController.h"

#define RGBACOLOR(r,g,b,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:(a)]

@interface MyTabBarController ()

@end

@implementation MyTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.defaultSelectedIndex = 0;
    
}
-(void)setUPAllChildViewController{

    self.childItemsArray = @[
                                 @{kClassKey  : @"ViewController",
                                   kTitleKey  : @"首页",
                                   kImgKey    : @"shouyexuanzhong",
                                   kSelImgKey : @"shouye"},
                                 
                                 @{kClassKey  : @"VideoListController",
                                   kTitleKey  : @"视频列表",
                                   kImgKey    : @"fuwu",
                                   kSelImgKey : @"fuwuxuanzhong"}
                                 ];
    
    
    
    
    self.itemNomalColor = RGBACOLOR(102, 102, 102, 1.0);
    
    self.itemSelectedColor =  RGBACOLOR(63, 101, 186, 1.0);

    
    
    [super setUPAllChildViewController];

}

@end
