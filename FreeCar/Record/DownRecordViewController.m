//
//  DownRecordViewController.m
//  FreeCar
//
//  Created by xiongchi on 15/8/1.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "DownRecordViewController.h"
#import "AppDelegate.h"
#import "RtspViewController.h"
#import "UIView+Extension.h"
#import "Toast+UIView.h"
#import "DownCell.h"
#import "RecordModel.h"
#import "MyBSDSocket.h"
#import "RecordDBService.h"
#import "FileSocket.h"

@interface DownRecordViewController ()<UITableViewDataSource,UITableViewDelegate,DownCellDelegate,RecordDownloadDelegate>
{
    FileSocket *fileSocket;
    NSMutableDictionary *dicDelete;
    NSInteger nTag;
    UIButton *btnRight;
    UIView *viewColor;
}

@property (nonatomic,assign) BOOL bSelectAll;
@property (nonatomic,strong) DownCell *downCell;
@property (nonatomic,assign) BOOL bDownloading;
@property (nonatomic,strong) UILabel *lblContent;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *array;
@property (nonatomic,strong) UIView *downView;
@property (nonatomic,strong) UIView *downloadView;

@property (nonatomic,strong) UISlider *downSlider;
@property (nonatomic,strong) UILabel *lblName;

@end

@implementation DownRecordViewController

-(void)dealloc
{
    _downCell = nil;
    _lblContent = nil;
    _tableView = nil;
    _array = nil;
}

-(void)initViewNew
{
    _downloadView = [[UIView alloc] initWithFrame:Rect(50, kScreenSourchHeight/2-75, kScreenSourchWidth-100, 150)];
    
    _downView = [[UIView alloc] initWithFrame:Rect(0, kScreenSourchHeight-50, kScreenSourchWidth, 50)];
    
    viewColor = [[UIView alloc] initWithFrame:Rect(0, 0, kScreenSourchWidth, kScreenSourchHeight)];
    
    [self.view addSubview:viewColor];
    
    [viewColor setBackgroundColor:RGB(192, 192, 192)];
    
    viewColor.alpha = 0.7;
    
    viewColor.hidden = YES;
    
    [self.view addSubview:_downloadView];
    
    _downloadView.backgroundColor = [UIColor whiteColor];
    
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
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(0, 15, _downloadView.width,20)];
    
    [_lblName setText:@"下载"];
    
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    
    [_lblName setTextColor:XC_MAIN_COLOR];
    
    _lblName.font = XCFONT(15);
    
    [_downloadView addSubview:_lblName];
    
    _downSlider = [[UISlider alloc] initWithFrame:Rect(10, 50, _downloadView.width-20, 30)];
    
    [_downloadView addSubview:_downSlider];
    
    UIButton *btnCan = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [btnCan setTitle:@"cancel" forState:UIControlStateNormal];
    
    [btnCan setTitleColor:XC_MAIN_COLOR forState:UIControlStateNormal];
    
    [btnCan addTarget:self action:@selector(closeDownload) forControlEvents:UIControlEventTouchUpInside];
    
    [_downloadView addSubview:btnCan];
    
    btnCan.frame = Rect(_downloadView.width/2-40, _downSlider.y+_downSlider.height+10, 80, 45);
    
    btnCan.layer.borderColor = RGB(192, 192, 192).CGColor;
    
    btnCan.layer.borderWidth = 1;
    
    [btnCan.layer setMasksToBounds:YES];
    
    btnCan.layer.cornerRadius = 3.0;
    
    _downloadView.hidden = YES;
}

#pragma mark 取消下载
-(void)closeDownload
{
    [fileSocket closeSocket];
    viewColor.hidden = YES;
    _downloadView.hidden = YES;
}

-(void)selectDelAll:(UIButton *)btnSender
{
    if (btnSender.selected)
    {
        for (int i=0;i<_array.count;i++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [_tableView deselectRowAtIndexPath:indexPath animated:NO];
            [dicDelete removeObjectForKey:indexPath];
        }
    }
    else
    {
        for (int i=0;i<_array.count;i++)
        {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:i inSection:0];
            [_tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [dicDelete setObject:[_array objectAtIndex:i] forKey:indexPath];
        }
    }
    btnSender.selected = !btnSender.selected;
}

-(void)delAll
{
    __weak NSMutableDictionary *__dictDelete = dicDelete;
    __weak NSMutableArray *__array = _array;
    __weak UITableView *__tableView = _tableView;
    
    _downView.hidden = YES;
    __weak DownRecordViewController *__self = self;
    [self.view makeToastActivity];
    __block NSInteger __nTag = nTag;
    __weak UIButton *__btnRight = btnRight;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        
        MyBSDSocket *bsdSocket = [MyBSDSocket sharedMyBSDSocket];
        [bsdSocket removeFromArray:[dicDelete allValues] type:__nTag==10001?1:2];
        [__array removeObjectsInArray:[__dictDelete allValues]];
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__self.view hideToastActivity];
            [__tableView setEditing:NO animated:YES];
            __btnRight.selected = NO;
            [__tableView reloadData];
        });
    });
}

-(void)leftClick
{
    [(AppDelegate *)[[UIApplication sharedApplication] delegate] showLeft];
}

-(void)rightClick
{
    if (_tableView.editing == YES)
    {
        DLog(@"dicDelete:%@",dicDelete);
        MyBSDSocket *bsdSocket = [MyBSDSocket sharedMyBSDSocket];
        [bsdSocket removeFromArray:[dicDelete allValues] type:nTag==10001?1:2];
        [_array removeObjectsInArray:[dicDelete allValues]];
        [_tableView setEditing:NO animated:YES];
        [_tableView reloadData];
        _downView.hidden = YES;
        btnRight.selected = NO;
    }
    else
    {
        btnRight.selected = YES;
        ((UIButton*)[_downView viewWithTag:1]).selected=NO;
        [_tableView setEditing:YES animated:YES];
        [dicDelete removeAllObjects];
        _downView.hidden = NO;
    }
}

-(void)initBodyView
{
    UIButton *btnLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnLeft setImage:[UIImage imageNamed:@"btn_set_normal"] forState:UIControlStateHighlighted];
    [btnLeft setImage:[UIImage imageNamed:@"btn_set_high"] forState:UIControlStateNormal];
    [btnLeft addTarget:self action:@selector(leftClick) forControlEvents:UIControlEventTouchUpInside];
    [self setLeftBtn:btnLeft];
   
    btnRight  = [UIButton buttonWithType:UIButtonTypeCustom];
    
    [btnRight setTitle:@"Edit" forState:UIControlStateNormal];
    
    [btnRight setImage:[UIImage imageNamed:@"OK_ICON"] forState:UIControlStateSelected];
    
    [btnRight addTarget:self action:@selector(rightClick) forControlEvents:UIControlEventTouchUpInside];
     
    [self setRightBtn:btnRight];
    
    UIButton *btnCom = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnCom setTitle:@"Common" forState:UIControlStateNormal];
    [btnCom setBackgroundColor:RGB(0, 188, 77)];
    [self.view addSubview:btnCom];
    [btnCom setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnCom.titleLabel.font = XCFONT(13);
    
    UIButton *btnAlarm = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnAlarm setTitle:@"Emegnecy" forState:UIControlStateNormal];
    [btnAlarm setBackgroundColor:RGB(0, 188, 77)];
    [self.view addSubview:btnAlarm];
    [btnAlarm setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnAlarm.titleLabel.font = XCFONT(13);
    
    btnCom.frame = Rect(0, 64, kScreenSourchWidth/2,44);
    btnAlarm.frame = Rect(kScreenSourchWidth/2, 64, kScreenSourchWidth/2, 44);
    [btnCom addTarget:self action:@selector(touchEvent:) forControlEvents:UIControlEventTouchUpInside];
    [btnAlarm addTarget:self action:@selector(touchEvent:) forControlEvents:UIControlEventTouchUpInside];
    btnCom.tag = 10001;
    btnAlarm.tag = 10002;
    nTag = 10001;
    
    _lblContent = [[UILabel alloc] initWithFrame:Rect(1, 40, kScreenSourchWidth/2-1,4)];
    [_lblContent setBackgroundColor:[UIColor whiteColor]];
    [btnCom addSubview:_lblContent];
    
    [self setTitleText:@"Recording Files"];
    _tableView = [[UITableView alloc] initWithFrame:Rect(0, 113, kScreenAppWidth, kScreenSourchHeight-113)];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

-(void)touchEvent:(UIButton *)btn
{
    [btn addSubview:_lblContent];
    
    nTag = btn.tag;
    
    if (btn.tag==10001)
    {
        [self initData];
    }
    else
    {
        [self initAlarm];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    nTag = 10001;
    _array = [NSMutableArray array];
    dicDelete = [NSMutableDictionary dictionary];
    [self.view setBackgroundColor:RGB(246, 246, 246)];
    [self initBodyView];
    [self initViewNew];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (nTag)
    {
        [self initData];
    }
    else
    {
        [self initAlarm];
    }
}

-(void)initAlarm
{
    [_array removeAllObjects];
    [self updateView];
    __weak DownRecordViewController *__self =self;
    dispatch_async(dispatch_get_global_queue(0, 0),
   ^{
       MyBSDSocket *bsdSocket = [MyBSDSocket sharedMyBSDSocket];
       NSData *data = [bsdSocket getAlarmRecordInfo];
       if (data==nil)
       {
           dispatch_async(dispatch_get_main_queue(), ^{
               [__self.view makeToast:@"No record"];
               [__self.tableView reloadData];
           });
           return ;
       }
       [__self comRecord:data];
   });
}

-(void)initData
{
    [_array removeAllObjects];
    [self updateView];
    __weak DownRecordViewController *__self =self;
    dispatch_async(dispatch_get_global_queue(0, 0),
   ^{
       MyBSDSocket *bsdSocket = [MyBSDSocket sharedMyBSDSocket];
       NSData *data = [bsdSocket getComRecordInfo];
       if (data==nil)
       {
           dispatch_async(dispatch_get_main_queue(),
           ^{
               [__self.view makeToast:@"No record"];
               [__self.tableView reloadData];
           });
           return ;
       }
       [__self comRecord:data];
   });
}

-(void)comRecord:(NSData *)strData
{
    NSError *error;
    NSDictionary *weatherDic = [NSJSONSerialization JSONObjectWithData:strData options:NSJSONReadingMutableLeaves error:&error];
    if (error)
    {
        return ;
    }
    NSArray *array = [weatherDic objectForKey:@"listing"];
    [_array removeAllObjects];
    for(int i=0;i<array.count;i++)
    {
        NSDictionary *song = [array objectAtIndex:i];
        RecordModel *record = [[RecordModel alloc] initWithItem:song];
        if([record.strName rangeOfString:@"_thm"].location == NSNotFound)
        {
            record.nType = nTag==10001 ? 1 : 2;
            [_array addObject:record];
        }
    }
    [self updateView];
}

-(void)updateView
{
    __weak UITableView *__tableView = _tableView;
    dispatch_async(dispatch_get_main_queue(), ^{
        [__tableView reloadData];
    });
}

#pragma mark datasource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _array.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *strDownRecordIdentify = @"downRecordIdentifier";
    DownCell *cell = [_tableView dequeueReusableCellWithIdentifier:strDownRecordIdentify];
    if (cell==nil)
    {
        cell = [[DownCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strDownRecordIdentify];
    }

    RecordModel *record = [_array objectAtIndex:indexPath.row];
    record.nId = indexPath.row;
    if (record)
    {
        [cell setRecordInfo:record];
        cell.delegate = self;
    }
    return cell;
}

#pragma mark delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(tableView.editing ==YES)
    {
        [dicDelete setObject:[_array objectAtIndex:indexPath.row] forKey:indexPath];
    }
    else
    {
        RecordModel *model = [_array objectAtIndex:indexPath.row];
        RtspViewController *rtspView = [[RtspViewController alloc] initWithModel:model];
        [[[[UIApplication sharedApplication]keyWindow] rootViewController] presentViewController:rtspView animated:YES completion:nil];
        
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 95;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
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

-(void)clickDownload:(RecordModel *)record
{
    if(_bDownloading)
    {
        [self.view makeToast:@"Downloading..." duration:1.5 position:@"center"];
        return;
    }
    if ([RecordDBService queryRecordByName:record.strName])
    {
        [self.view makeToast:@"File already exists"];
        return ;
    }
    
    _downCell = (DownCell*)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:record.nId inSection:0]];
    
    MyBSDSocket *bsdSocket = [MyBSDSocket sharedMyBSDSocket];
    
    if([bsdSocket downloadFile:record.strName])
    {
        [self downloadInfo:record.strName size:record.nAll];
        _bDownloading = YES;
        _downSlider.value = 0;
        _downloadView.hidden = NO;
        viewColor.hidden = NO;
    }
    else
    {
        [self.view makeToast:@"download failed"];
    }
}

-(void)downloadInfo:(NSString *)strInfo size:(int)nAll
{
    if (fileSocket == nil)
    {
        fileSocket = [[FileSocket alloc] init];
    }
    __weak DownRecordViewController *__self = self;
    __weak UIView *__viewCoclor = viewColor;
    RecordModel *recordInfo = _downCell.recordInfo;
    __weak RecordModel *__recordInfo = recordInfo;
    fileSocket.recordBlock = ^(int nStatus)
    {
        if (nStatus == 0)
        {
            __self.bDownloading = NO;
            dispatch_async(dispatch_get_main_queue(),
           ^{
               [__self.view makeToast:@"download failed" duration:1.5 position:@"center"];
               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(),
                ^{
                    __self.downloadView.hidden = YES;
                    __viewCoclor.hidden = YES;
               });
           });
        }
        else
        {
            DLog(@"下载完成");
            MyBSDSocket *bsdSocket = [MyBSDSocket sharedMyBSDSocket];
            [bsdSocket getDownDone];
            dispatch_async(dispatch_get_main_queue(),
            ^{
                [RecordDBService addRecording:__recordInfo];
                [__self.view makeToast:@"Done" duration:1.5 position:@"center"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(),
                   ^{
                       __self.downloadView.hidden = YES;
                       __viewCoclor.hidden = YES;
                       __self.bDownloading = NO;
                   }
                );
            });
        }
    };
    fileSocket.delegate = self;
    [fileSocket initSockInfo:nAll name:strInfo];
}

-(void)downloadStuats:(int)nCurrent all:(int)nAll
{
    NSString *strInfo = [NSString stringWithFormat:@"%.02f %%",(float)nCurrent/nAll * 100];
    __block NSString *__strInfo = strInfo;
    
    CGFloat fValue = (float)nCurrent/nAll;
    __block CGFloat __fValue = fValue;
    __weak UISlider *__slider = _downSlider;
    dispatch_sync(dispatch_get_main_queue(),
    ^{
        __slider.value = __fValue;
    });
}


@end
