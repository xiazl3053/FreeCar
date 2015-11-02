//
//  RecordVIewController.m
//  FreeCar
//
//  Created by xiongchi on 15/8/1.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "RecordVIewController.h"
#import <MediaPlayer/MPMoviePlayerController.h>
#import <AVFoundation/AVFoundation.h>
#import "DownCell.h"
#import "RecordDBService.h"
#import "RecordModel.h"
#import "Toast+UIView.h"
#import "MyBSDSocket.h"
#import "AppDelegate.h"
#import "PlayViewController.h"

@interface RecordViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    NSMutableDictionary *dicDelete;
    UIButton *btnRight;
}
@property (nonatomic,strong) UIView *downView;
@property (nonatomic,strong) NSMutableArray *arrayRecord;
@property (nonatomic,strong) UITableView *tableView;

@end

@implementation RecordViewController


-(void)initViewNew
{
    _downView = [[UIView alloc] initWithFrame:Rect(0, kScreenSourchHeight-50, kScreenSourchWidth, 50)];
   
    [self.view addSubview:_downView];
    
    _downView.backgroundColor = [UIColor whiteColor];
    
    UIButton *btnAll = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [_downView addSubview:btnAll];
    
    btnAll.tag = 1;
    
    [btnAll setTitle:@"All" forState:UIControlStateNormal];
    
    [btnAll setTitle:@"Reselect" forState:UIControlStateSelected];
    
    [btnAll setTitleColor:XC_MAIN_COLOR forState:UIControlStateNormal];
    
    UIButton *btnDel = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [btnDel setTitleColor:XC_MAIN_COLOR forState:UIControlStateNormal];
    
    [btnDel setTitle:@"delete" forState:UIControlStateNormal];
    
    [_downView addSubview:btnDel];
    
    btnAll.frame = Rect(0, 0, kScreenSourchWidth/2-1, 50);
    
    btnDel.frame = Rect(kScreenSourchWidth/2, 0, kScreenSourchWidth/2-1, 50);
    
    [btnAll addTarget:self action:@selector(selectDelAll:) forControlEvents:UIControlEventTouchUpInside];
    
    [btnDel addTarget:self action:@selector(delAll) forControlEvents:UIControlEventTouchUpInside];
    
    UILabel *lblContent = [[UILabel alloc] initWithFrame:Rect(0, 0, kScreenSourchWidth, 1)];
    [lblContent setBackgroundColor:RGB(192.0,192,192)];
    [_downView addSubview:lblContent];
    
    _downView.hidden = YES;
    
    lblContent = [[UILabel alloc] initWithFrame:Rect(kScreenSourchWidth/2-1, 0, 1, 50)];
    [lblContent setBackgroundColor:RGB(192.0,192,192)];
    
    [_downView addSubview:lblContent];
}

-(void)selectDelAll:(UIButton *)btnSender
{
    if (btnSender.selected)
    {
        for (int i=0;i<_arrayRecord.count;i++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [_tableView deselectRowAtIndexPath:indexPath animated:NO];
            [dicDelete removeObjectForKey:indexPath];
        }
    }
    else
    {
        for (int i=0;i<_arrayRecord.count;i++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [_tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [dicDelete setObject:[_arrayRecord objectAtIndex:i] forKey:indexPath];
        }
    }
    btnSender.selected = !btnSender.selected;
}

-(void)delAll
{
    __weak NSMutableDictionary *__dictDelete = dicDelete;
    __weak NSMutableArray *__array = _arrayRecord;
    __weak UITableView *__tableView = _tableView;
    
    _downView.hidden = YES;
    __weak RecordViewController *__self = self;
    [self.view makeToastActivity];
//    __weak UIButton *__btnRight = btnRight;
    dispatch_async(dispatch_get_global_queue(0, 0),
       ^{
           [RecordDBService removeArray:[dicDelete allValues]];
           [_arrayRecord removeObjectsInArray:[dicDelete allValues]];
           [__array removeObjectsInArray:[__dictDelete allValues]];
           dispatch_async(dispatch_get_main_queue(),
                          ^{
                              [__self.view hideToastActivity];
                              [__tableView setEditing:NO animated:YES];
                              [__tableView reloadData];
                              btnRight.selected = NO;
                          });
       });
}




-(void)initHeadView
{
    UIButton *btnLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnLeft setImage:[UIImage imageNamed:@"btn_set_normal"] forState:UIControlStateHighlighted];
    [btnLeft setImage:[UIImage imageNamed:@"btn_set_high"] forState:UIControlStateNormal];
    [btnLeft addTarget:self action:@selector(leftClick) forControlEvents:UIControlEventTouchUpInside];
    [self setLeftBtn:btnLeft];
    
    btnRight  = [UIButton buttonWithType:UIButtonTypeCustom];
//    [btnRight setImage:[UIImage imageNamed:@"btn_remove_normal"] forState:UIControlStateHighlighted];
//    [btnRight setImage:[UIImage imageNamed:@"btn_remove_high"] forState:UIControlStateNormal];
//    [btnRight setImage:[UIImage imageNamed:@"OK_ICON"] forState:UIControlStateSelected];
    [btnRight setTitle:@"Edit" forState:UIControlStateNormal];
    
    [btnRight setTitle:@"Cancel" forState:UIControlStateSelected];
    
    [btnRight addTarget:self action:@selector(rightClick) forControlEvents:UIControlEventTouchUpInside];
    
    [self setRightBtn:btnRight];
    
    _tableView = [[UITableView alloc] initWithFrame:Rect(0, 64, kScreenSourchWidth, kScreenSourchHeight-64)];
    
    [self.view addSubview:_tableView];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    [self setTitleText:@"Phone files"];
}

-(void)rightClick
{
    if (_tableView.editing == YES)
    {
        DLog(@"dicDelete:%@",dicDelete);
        [_tableView setEditing:NO animated:YES];
        _downView.hidden = YES;
        [_tableView reloadData];
        btnRight.selected = NO;
    }
    else
    {
        btnRight.selected = YES;
        _downView.hidden = NO;
        ((UIButton*)[_downView viewWithTag:1]).selected=NO;
        
        [_tableView setEditing:YES animated:YES];
        
        [dicDelete removeAllObjects];
    }
}

-(void)leftClick
{
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showLeft];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    dicDelete = [NSMutableDictionary dictionary];
    _arrayRecord = [NSMutableArray array];
    [self.view setBackgroundColor:RGB(255, 255, 255)];
    [self initHeadView];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setLayout) name:MESSAGE_UPDATE_RECORD_VC object:nil];
    
    [self initViewNew];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self initData];
}

-(void)initData
{
    NSArray *aryRecord = [RecordDBService queryAllRecord];
    [_arrayRecord removeAllObjects];
    [_arrayRecord addObjectsFromArray:aryRecord];
    [_tableView reloadData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    DLog(@"count:%zi",_arrayRecord.count);
    return _arrayRecord.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *strRecordViewIdentifier = @"kRecordViewIdentifier";
    DownCell *cell = [tableView dequeueReusableCellWithIdentifier:strRecordViewIdentifier];
    if (cell==nil)
    {
        cell = [[DownCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strRecordViewIdentifier];
    }
    RecordModel *record = [_arrayRecord objectAtIndex:indexPath.row];
    record.nId = indexPath.row;
    if (record)
    {
        [cell setRecordInfo:record];
    }
    [cell setRecordViewStyle];
    __block NSString *__strPath = record.strName;
    __weak DownCell *__cell = cell;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        NSString *strInfo = [NSString stringWithFormat:@"%@/record/%@",kLibraryPath,__strPath];
        UIImage *image = [RecordViewController getImage:strInfo];
        dispatch_async(dispatch_get_main_queue(),
        ^{
            __cell.imgView.image = image;
        });
    });

    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleDelete | UITableViewCellEditingStyleInsert;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(3_0)
{
    if(tableView.editing ==YES)
    {
        [dicDelete removeObjectForKey:indexPath];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.editing ==YES)
    {
        [dicDelete setObject:[_arrayRecord objectAtIndex:indexPath.row] forKey:indexPath];
    }
    else
    {
        DLog(@"点击播放");
        RecordModel *record = [_arrayRecord objectAtIndex:indexPath.row];
        PlayViewController *playView = [[PlayViewController alloc] initWithModel:record];
        [[[[UIApplication sharedApplication]keyWindow] rootViewController] presentViewController:playView animated:YES completion:nil];
    }
}

+(UIImage *)getImage:(NSString *)videoURL
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoURL] options:nil];
    
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    
    gen.appliesPreferredTrackTransform = YES;
    
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    
    NSError *error = nil;
    
    CMTime actualTime;
    
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    
    CGImageRelease(image);
    
    return thumb;
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 95;
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

-(void)setLayout
{
    [self.view setNeedsDisplay];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
//    [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
    
//    [[UIDevice currentDevice] setValue: [NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
//    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
//    [UIView beginAnimations:nil context:nil];
//    [UIView setAnimationDuration:duration];
//    CGRect frame = [UIScreen mainScreen].bounds;
//    CGPoint center = CGPointMake(frame.origin.x + ceil(frame.size.width/2), frame.origin.y + ceil(frame.size.height/2));
//    self.view.center = center;
//    self.view.transform = CGAffineTransformIdentity;
//    self.view.bounds = CGRectMake(0, 0, kScreenSourchWidth, kScreenSourchHeight);
//    [UIView commitAnimations];
}

@end
