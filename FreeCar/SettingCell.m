//
//  SettingCell.m
//  FreeCar
//
//  Created by xiongchi on 15/8/7.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "SettingCell.h"

@interface SettingCell()
{
    UILabel *sLine1;
    UILabel *sLine2;
}

@end

@implementation SettingCell


-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    _txtLabel = [[UILabel alloc] initWithFrame:Rect(15, 15, 200,15)];
    [_txtLabel setFont:XCFONT(14)];
    [_txtLabel setTextColor:UIColorFromRGB(0x2a2e46)];
    [self.contentView addSubview:_txtLabel];
    [self addViewLine];
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    sLine1.frame = Rect(15, 43.1, kScreenSourchWidth, 0.2);
    sLine2.frame = Rect(15, 43.3, kScreenSourchWidth, 0.2);
}

- (void)awakeFromNib
{
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

}

-(void)addViewLine
{
    sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(15, 42.8, kScreenSourchWidth, 0.2)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(15, 43, kScreenSourchWidth ,0.2)] ;
    
    sLine2.backgroundColor = [UIColor whiteColor];
    sLine1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:sLine1];
    [self.contentView addSubview:sLine2];
}

-(void)setContent:(NSString *)strContent
{
    _txtContent = [[UILabel alloc] initWithFrame:Rect(kScreenSourchWidth-180,15,140,15)];
    [_txtContent setText:strContent];
    [_txtContent setFont:XCFONT(12)];
    [_txtContent setTextColor:UIColorFromRGB(0X97989D)];
    [_txtContent setTextAlignment:NSTextAlignmentRight];
    [self.contentView addSubview:_txtContent];
}

@end
