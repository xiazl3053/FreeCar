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
}

@property (nonatomic,assign) BOOL bDownloading;
//@property (nonatomic,strong) 
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
    
    [self setTitleText:@"Recording Files"];
    _tableView = [[UITableView alloc] initWithFrame:Rect(0, 64, kScreenAppWidth, kScreenSourchHeight-64)];
    [self.view addSubview:_tableView];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _array = [NSMutableArray array];
    dicDelete = [NSMutableDictionary dictionary];
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
    [self initData];
}

-(void)initData
{
    __weak DownRecordViewController *__self =self;
    dispatch_async(dispatch_get_global_queue(0, 0),
   ^{
       MyBSDSocket *bsdSocket = [MyBSDSocket sharedMyBSDSocket];
       NSData *data = [bsdSocket getComRecordInfo];
       if (data==nil)
       {
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
//    DLog(@"array:%@",array);
    [_array removeAllObjects];
    for(int i=0;i<array.count;i++)
    {
//        NSString *strItem = array[i];
        NSDictionary *song = [array objectAtIndex:i];
//        NSLog(@"song info: %@----%@\t\n",song.allKeys[0],song.allValues[0]);
        
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
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
    _bDownloading = YES;
    _downCell = cellInfo;
    DLog(@" _downCell.recordInfo.strName:%@", _downCell.recordInfo.strName);
   
    MyBSDSocket *bsdSocket = [MyBSDSocket sharedMyBSDSocket];
    _downCell.lblPercent.hidden = NO;
    [_downCell.lblPercent setText:@"开始下载"];
    if([bsdSocket downloadFile:record.strName])
    {
        [self downloadInfo:record.strName size:record.nAll];
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
