//
//  ViewController.m
//  ZJVideoRecording
//
//  Created by zhengju on 2017/9/18.
//  Copyright © 2017年 郑俱. All rights reserved.
//

#import "ViewController.h"
#import "ZJPhotograph.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    ZJPhotograph * vc  = [[ZJPhotograph alloc]init];
    
    [self.navigationController pushViewController:vc animated:NO];
    
}



@end
