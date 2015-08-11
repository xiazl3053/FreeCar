//
//  LeftViewController.h
//  WWSideslipViewControllerSample
//
//  Created by 王维 on 14-8-26.
//  Copyright (c) 2014年 wangwei. All rights reserved.
//

// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com

#import <UIKit/UIKit.h>
#import "RESideMenu.h"

#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

@interface LeftViewController : UIViewController

@property (strong, readonly, nonatomic) RESideMenu *sideMenu;

@end

@interface LeftCellInfo : NSObject

-(id)initWithTitle:(NSString *)strTitle normal:(NSString *)strNormal high:(NSString *)strHigh;

@property (nonatomic,copy) NSString *strNorImg;
@property (nonatomic,copy) NSString *strHighImg;
@property (nonatomic,copy) NSString *strTitle;

@end