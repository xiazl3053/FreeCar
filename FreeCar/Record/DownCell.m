//
//  DownCell.m
//  FreeCar
//
//  Created by xiongchi on 15/8/1.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "DownCell.h"

#import "UIView+Extension.h"

#import "RecordModel.h"
#import "UIImageView+WebCache.h"

@interface DownCell()
{
    UILabel *sLine1;
    UILabel *sLine2;
}

@end


@implementation DownCell

-(void)setRecordViewStyle
{
    _btnDown.hidden = YES;
}

-(void)setRecordInfo:(RecordModel *)recordModel
{
    //设置图片地址与默认图片
//    [_imgView sd_setImageWithURL:nil placeholderImage:nil];
    [_lblTitle setText:recordModel.strName];
    [_lblDate setText:recordModel.strDate];
    [_lblSize setText:recordModel.strSize];
    _recordInfo = recordModel;
}


-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    [self initBody];
    
    return self;
}

-(void)initBody
{
    _imgView = [[UIImageView alloc] initWithFrame:Rect(15, 10, 100, 75)];
    [self.contentView addSubview:_imgView];
    [_imgView setImage:[UIImage imageNamed:@"pic_example"]];
    
    UIImageView *imgTemp = [[UIImageView alloc] initWithFrame:_imgView.frame];
    [imgTemp setImage:[UIImage imageNamed:@"pic_play"]];
    [self.contentView addSubview:imgTemp];
    
    
    _lblTitle = [[UILabel alloc] initWithFrame:Rect(_imgView.x+_imgView.width+15, 15, kScreenAppWidth-170,17)];
    [self.contentView addSubview:_lblTitle];
    [_lblTitle setFont:XCFONT(15)];
    
    _lblDate = [[UILabel alloc] initWithFrame:Rect(_lblTitle.x, 40, _lblTitle.width, 14)];
    [_lblDate setFont:XCFONT(12)];
    [self.contentView addSubview:_lblDate];
    
    _lblSize = [[UILabel alloc] initWithFrame:Rect(_lblDate.x, 70, _lblTitle.width, 13)];
    [_lblSize setFont:XCFONT(12)];
    [self.contentView addSubview:_lblSize];
    
    [_lblTitle setTextColor:UIColorFromRGB(0x2a2e46)];
    [_lblDate setTextColor:UIColorFromRGB(0x97989d)];
    [_lblSize setTextColor:UIColorFromRGB(0x42be56)];
    
    _btnDown = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.contentView addSubview:_btnDown];
    _btnDown.frame = Rect(kScreenSourchWidth-50, 28, 44, 44);
    [_btnDown setImage:[UIImage imageNamed:@"btn_down_nor"] forState:UIControlStateNormal];
    [_btnDown setImage:[UIImage imageNamed:@"btn_down_high"] forState:UIControlStateHighlighted];
    [_btnDown addTarget:self action:@selector(downloadFile) forControlEvents:UIControlEventTouchUpInside];
    
    _lblPercent = [[UILabel alloc] initWithFrame:Rect(kScreenSourchWidth-80,_lblSize.y,60,15)];
    [_lblPercent setFont:XCFONT(12)];
    [_lblPercent setTextColor:[UIColor redColor]];
    [self.contentView addSubview:_lblPercent];
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    sLine1.frame = Rect(15, 94, kScreenSourchWidth-30, 0.3);
    sLine2.frame = Rect(15, 94.3, kScreenSourchWidth-30, 0.3);
}

-(void)downloadFile
{
    if (_delegate && [_delegate respondsToSelector:@selector(clickDownload:)])
    {
        [_delegate clickDownload:_recordInfo];
    }
}

- (void)awakeFromNib
{
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

-(void)addViewLine
{
    sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(21, 60, kScreenSourchWidth, 0.2)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(21, 60.2, kScreenSourchWidth ,0.2)] ;
    
    sLine2.backgroundColor = [UIColor whiteColor];
    sLine1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [self.contentView addSubview:sLine1];
    [self.contentView addSubview:sLine2];
}

@end
