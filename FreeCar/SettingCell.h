//
//  SettingCell.h
//  FreeCar
//
//  Created by xiongchi on 15/8/7.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingCell : UITableViewCell

@property (nonatomic,strong) UILabel *txtLabel;
@property (nonatomic,strong) UILabel *txtContent;


-(void)setContent:(NSString *)strContent;

@end
