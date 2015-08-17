//
//  DownRecordViewController.m
//  FreeCar
//
//  Created by xiongchi on 15/8/1.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "DownRecordViewController.h"
#import "AppDelegate.h"
#import "Toast+UIView.h"
#import "DownCell.h"
#import "RecordModel.h"
#import "MyBSDSocket.h"
#import "RecordDBService.h"
#import "FileSocket.h"

@interface DownRecordViewController ()<UITableViewDataSource,UITableViewDelegate,DownCellDelegate,RecordDownloadDelegate>
{
    FileSocket *fileSocket;
    DownCell *_downCell;
    NSMutableDictionary *dicDelete;
    NSInteger nTag;
}

@property (nonatomic,assign) BOOL bDownloading;
//@property (nonatomic,strong)
@property (nonatomic,strong) UILabel *lblContent;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *array;
@end

@implementation DownRecordViewController

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
        [bsdSocket removeFromArray:[dicDelete allValues]];
        [_array removeObjectsInArray:[dicDelete allValues]];
        [_tableView setEditing:NO animated:YES];
        [_tableView reloadData];
    }
    else
    {
        [_tableView setEditing:YES animated:YES];
        [dicDelete removeAllObjects];
    }
}

-(void)initBodyView
{
    UIButton *btnLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnLeft setImage:[UIImage imageNamed:@"btn_set_normal"] forState:UIControlStateHighlighted];
    [btnLeft setImage:[UIImage imageNamed:@"btn_set_high"] forState:UIControlStateNormal];
    [btnLeft addTarget:self action:@selector(leftClick) forControlEvents:UIControlEventTouchUpInside];
    [self setLeftBtn:btnLeft];
   
    UIButton *btnRight  = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnRight setImage:[UIImage imageNamed:@"btn_remove_normal"] forState:UIControlStateHighlighted];
    [btnRight setImage:[UIImage imageNamed:@"btn_remove_high"] forState:UIControlStateNormal];
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
    // Do any additional setup after loading the view.
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
        
        [_array addObject:record];
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
    static NSString *strDownRecordIdentify = @"DOWNRECORDTABLEVIEWIDENTIFY";
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

-(void)clickDownload:(RecordModel *)record cell:(DownCell*)cellInfo
{
    if(_bDownloading)
    {
        [self.view makeToast:@"正在下载" duration:1.5 position:@"center"];
        return;
    }
    _downCell = cellInfo;
    DLog(@" _downCell.recordInfo.strName:%@", _downCell.recordInfo.strName);
    MyBSDSocket *bsdSocket = [MyBSDSocket sharedMyBSDSocket];
    if([bsdSocket downloadFile:record.strName])
    {
        [self downloadInfo:record.strName size:record.nAll];
        _bDownloading = YES;
        [_downCell.lblPercent setText:@"开始下载"];
        _downCell.lblPercent.hidden = NO;
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
    __weak DownCell *__cell = _downCell;
    fileSocket.recordBlock = ^(int nStatus)
    {
        if (nStatus == 0)
        {
            __self.bDownloading = NO;
            dispatch_async(dispatch_get_main_queue(),
           ^{
               [__self.view makeToast:@"下载失败" duration:1.5 position:@"center"];
               dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(),
                ^{
                      __cell.lblPercent.hidden = YES;
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
                __cell.lblPercent.text = @"完成";
                [RecordDBService addRecording:__cell.recordInfo];
                [__self.view makeToast:@"下载完成" duration:1.5 position:@"center"];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1.5 * NSEC_PER_SEC), dispatch_get_main_queue(),
                       ^{
                           __cell.lblPercent.hidden = YES;
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
//    DLog(@"current:%d",nAll);
    NSString *strInfo = [NSString stringWithFormat:@"%.02f %%",(float)nCurrent/nAll * 100];
//    DLog(@"status:%@",strInfo);
    __block NSString *__strInfo = strInfo;
    __weak DownCell *__cell = _downCell;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [__cell.lblPercent setText:__strInfo];
    });
}



@end
