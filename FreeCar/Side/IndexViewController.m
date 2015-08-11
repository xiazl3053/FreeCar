//
//  IndexViewController.m
//  FreeCar
//
//  Created by xiongchi on 15/8/5.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "IndexViewController.h"
#import "MainViewController.h"

#import "RecordVIewController.h"

#import "DownRecordViewController.h"
#import "SettingViewController.h"

@interface IndexViewController ()
{
    MainViewController *mainViewControl;
    DownRecordViewController *recordViewControl;
    RecordViewController *localRecord;
    UIViewController *tempControl;
    SettingViewController *settingControl;
}
@end

@implementation IndexViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    mainViewControl = [[MainViewController alloc] init];
    [self addChildViewController:mainViewControl];
    
    recordViewControl = [[DownRecordViewController alloc] init];
    [self addChildViewController:recordViewControl];
    
    localRecord = [[RecordViewController alloc] init];
    [self addChildViewController:localRecord];
    
    settingControl = [[SettingViewController alloc] init];
    [self addChildViewController:settingControl];
    
    tempControl = mainViewControl;
    
    [self showMainView];
}

-(void)showSettingView
{
    [tempControl.view removeFromSuperview];
    [self.view insertSubview:settingControl.view atIndex:0];
    tempControl = settingControl;
}

-(void)showLocalRecord
{
    [tempControl.view removeFromSuperview];
    [self.view insertSubview:localRecord.view atIndex:0];
    tempControl = localRecord;
}

-(void)showMainView
{
    [tempControl.view removeFromSuperview];
    [self.view insertSubview:mainViewControl.view atIndex:0];
    tempControl = mainViewControl;
}

-(void)showRecordView
{
    [tempControl.view removeFromSuperview];
    [self.view insertSubview:recordViewControl.view atIndex:0];
    tempControl = recordViewControl;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
