//
//  ViewController.m
//  ZJVideoRecording
//
//  Created by zhengju on 2017/9/18.
//  Copyright © 2017年 郑俱. All rights reserved.
//

#import "ViewController.h"
#import "ZJPhotograph.h"
#import "ZJVideoController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    
    
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    ZJPhotograph * vc  = [[ZJPhotograph alloc]init];
//
//    [self.navigationController pushViewController:vc animated:NO];
    
    ZJVideoController * videoController = [[ZJVideoController alloc]init];
     [self.navigationController pushViewController:videoController animated:NO];

}


@end
