//
//  DownCell.h
//  FreeCar
//
//  Created by xiongchi on 15/8/1.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RecordModel;
@class DownCell;
@protocol DownCellDelegate <NSObject>

-(void)clickDownload:(RecordModel *)record cell:(DownCell*)cellInfo;

@end


@interface DownCell : UITableViewCell


//@property (nonatomic,assign) float fPercent;

@property (nonatomic,strong) UILabel *lblPercent;

@property (nonatomic,assign) id<DownCellDelegate> delegate;
@property (nonatomic,strong) RecordModel *recordInfo;
@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) UILabel *lblTitle;
@property (nonatomic,strong) UILabel *lblDate;
@property (nonatomic,strong) UILabel *lblSize;
@property (nonatomic,strong) UIButton *btnDown;

-(void)setRecordInfo:(RecordModel *)recordModel;

-(void)setRecordViewStyle;

@end
