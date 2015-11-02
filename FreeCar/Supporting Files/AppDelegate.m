//
//  AppDelegate.m
//  FreeCar
//
//  Created by xiongchi on 15/7/3.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "LeftViewController.h"
#import "WWSideslipViewController.h"
#import "MyBSDSocket.h"
#import "LSTcpSocket.h"
#import "IndexViewController.h"

@interface AppDelegate ()
{
    WWSideslipViewController *_slide;
}
@end

@implementation AppDelegate


-(void)showLeft
{
    if (_slide)
    {
        [_slide showLeftView];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    
    IndexViewController *index = [[IndexViewController alloc] init];
    LeftViewController *left = [[LeftViewController alloc] init];
    WWSideslipViewController * slide = [[WWSideslipViewController alloc]initWithLeftView:left andMainView:index andRightView:nil andBackgroundImage:nil];
    _slide=slide;
    //滑动速度系数
    sleep(2);
    [slide setSpeedf:0.5];
    //点击视图是是否恢复位置
    slide.sideslipTapGes.enabled = YES;
    
    [self.window setRootViewController:slide];
   
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_ENTER_BACK_VC object:nil];
    [[MyBSDSocket sharedMyBSDSocket] closeSocket];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
//    if([[MyBSDSocket sharedMyBSDSocket] XzlConnect])
//    {
//        [[MyBSDSocket sharedMyBSDSocket] startSession];
//    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    if([[MyBSDSocket sharedMyBSDSocket] XzlConnect])
    {
        [[MyBSDSocket sharedMyBSDSocket] startSession];
    }
}

- (void)applicationWillTerminate:(UIApplication *)application
{
      [[MyBSDSocket sharedMyBSDSocket] closeSocket];
}

@end
