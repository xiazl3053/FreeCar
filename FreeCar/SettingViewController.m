//
//  SettingViewController.m
//  FreeCar
//
//  Created by xiongchi on 15/8/7.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "SettingViewController.h"
#import "AppDelegate.h"
#import "Toast+UIView.h"
#import "SettingCell.h"
#import "MyBSDSocket.h"

@interface SettingViewController ()<UITableViewDataSource,UITableViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate,UIAlertViewDelegate>
{
    NSArray *firstAry;
    NSArray *secondAry;
    NSArray *thrAry;
    UIPickerView *pickerStamp;
    UIPickerView *pickerResolu;
    NSArray *aryStamp;
    NSArray *aryResolution;
    UIDatePicker *datePicker;
    
    UIView *viewStamp;
    UIView *viewResolution;
    UIView *viewDate;
    
    UIButton *btnStamp;

    UIButton *btnResolu;
    int nAllSpace;
    int nFreeSpace;
}
@property (nonatomic,copy) NSString *strStamp;
@property (nonatomic,copy) NSString* strRelolution;
@property (nonatomic,strong) UITableView *tableView;

@end

@implementation SettingViewController

-(void)settingStamp
{
    [self.view makeToastActivity];
    
    NSInteger nRow = [pickerStamp selectedRowInComponent:0];
    NSString *strInfo=nil;
    if(nRow==2)
    {
        strInfo = @"date/time";
    }
    else
    {
        strInfo = [aryStamp objectAtIndex:nRow];
    }
    __block NSString *__strInfo = strInfo;
    __weak SettingViewController *__self = self;
    __weak UIView *__viewStamp = viewStamp;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        MyBSDSocket *mySock = [MyBSDSocket sharedMyBSDSocket];
        if([mySock settingTimeInfo:__strInfo type:0])
        {
            __self.strStamp = __strInfo;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [__self.view hideToastActivity];
            
            [__self.tableView reloadData];
            
            __viewStamp.hidden = YES;
        });
    });
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    __weak SettingViewController *__self = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [__self initData];
    });
}

-(void)initData
{
    MyBSDSocket *mySock = [MyBSDSocket sharedMyBSDSocket];
    
    nFreeSpace = [mySock getFreeInfo];
    
    nAllSpace = [mySock getTotalInfo];
    
    _strStamp = [mySock getStamp];
    
    _strRelolution = [mySock getResolution];
    
    __weak SettingViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [__self.tableView reloadData];
    });
}

-(void)initDateView
{
    viewDate = [[UIView alloc] initWithFrame:self.view.bounds];
    UIView *headView = [[UIView alloc] initWithFrame:Rect(0, 0,kScreenSourchWidth, kScreenSourchHeight-254)];
    [headView setBackgroundColor:RGB(128, 128, 128)];
    [viewDate addSubview:headView];
    headView.alpha = 0.5f;
    UIView *backView = [[UIView alloc] initWithFrame:Rect(0, kScreenSourchHeight-254 , kScreenSourchWidth, 254)];
    [viewDate addSubview:backView];
    [backView setBackgroundColor:RGB(255, 255, 255)];
    
    UIButton *btnCan = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnCan setTitle:@"Cancel" forState:UIControlStateNormal];
    [btnCan setTitleColor:RGB(0, 188, 77) forState:UIControlStateNormal];
    [backView addSubview:btnCan];
    btnCan.titleLabel.font = XCFONT(15);
    btnCan.frame = Rect(10, 0,70, 37);
    [btnCan addTarget:self action:@selector(hiddenDate) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *btnDate = [UIButton buttonWithType:UIButtonTypeCustom];
    [backView addSubview:btnDate];
    [btnDate setTitle:@"OK" forState:UIControlStateNormal];
    [btnDate setTitleColor:RGB(0, 188, 77) forState:UIControlStateNormal];
    btnDate.titleLabel.font = XCFONT(15);
    [btnDate addTarget:self action:@selector(setDateInfo) forControlEvents:UIControlEventTouchUpInside];
    btnDate.frame = Rect(kScreenSourchWidth-50,0, 44,37);
  
    UILabel *lblContent = [[UILabel alloc] initWithFrame:Rect(0,37, kScreenSourchWidth, 1)];
    [lblContent setBackgroundColor:[UIColor grayColor]];
    [backView addSubview:lblContent];
   
    datePicker = [[UIDatePicker alloc]initWithFrame:Rect(0, 38, kScreenSourchWidth, 216)];
    [datePicker setDatePickerMode:UIDatePickerModeDateAndTime];
//    NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
//    fmt.dateFormat = @"yyyy-MM-dd HH:mm:ss";
//    NSDate *dateInfo = [fmt dateFromString:@"2015-8-10 0:0:0"];
    [backView addSubview:datePicker];
    
    [self.view addSubview:viewDate];
    viewDate.hidden = YES;
}

-(void)hiddenDate
{
    viewDate.hidden = YES;
}

-(void)setDateInfo
{
    [self.view makeToastActivity];
    __weak SettingViewController *__self = self;
    __weak UIView *__viewDate = viewDate;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        NSDate *date = datePicker.date;
        BOOL bFlag = [[MyBSDSocket sharedMyBSDSocket] setClock:date];
        if (bFlag)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [__self.view hideToastActivity];
                __viewDate.hidden = YES;
            });
        }
    });
}

-(void)initPickerResolu
{
    viewResolution = [[UIView alloc] initWithFrame:self.view.bounds];
    UIView *headView = [[UIView alloc] initWithFrame:Rect(0, 0,kScreenSourchWidth, kScreenSourchHeight-254)];
    [headView setBackgroundColor:RGB(128, 128, 128)];
    [viewResolution addSubview:headView];
    headView.alpha = 0.5f;
    UIView *backView = [[UIView alloc] initWithFrame:Rect(0, kScreenSourchHeight-254 , kScreenSourchWidth, 254)];
    [viewResolution addSubview:backView];
    [backView setBackgroundColor:RGB(255, 255, 255)];
    
    UIButton *btnCan = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnCan setTitle:@"Cancel" forState:UIControlStateNormal];
    [btnCan setTitleColor:RGB(0, 188, 77) forState:UIControlStateNormal];
    [backView addSubview:btnCan];
    btnCan.titleLabel.font = XCFONT(15);
    btnCan.frame = Rect(10, 0,70, 37);
    [btnCan addTarget:self action:@selector(hiddenResolu) forControlEvents:UIControlEventTouchUpInside];
    
    btnResolu = [UIButton buttonWithType:UIButtonTypeCustom];
    [backView addSubview:btnResolu];
    [btnResolu setTitle:@"OK" forState:UIControlStateNormal];
    [btnResolu setTitleColor:RGB(0, 188, 77) forState:UIControlStateNormal];
    btnResolu.titleLabel.font = XCFONT(15);
    [btnResolu addTarget:self action:@selector(setResolution) forControlEvents:UIControlEventTouchUpInside];
    btnResolu.frame = Rect(kScreenSourchWidth-50,0, 44,37);
  
    UILabel *lblContent = [[UILabel alloc] initWithFrame:Rect(0,37, kScreenSourchWidth, 1)];
    [lblContent setBackgroundColor:[UIColor grayColor]];
    [backView addSubview:lblContent];
    
    aryResolution = [[NSArray alloc] initWithObjects:@"2560x1080 30P 21:9",@"2304x1296 30P 16:9",@"1920x1080 60P 16:9",@"HDR 1920x1080 30P 16:9",@"1920x1080 30P 16:9",@"1280x720 60P 16:9",@"1280x720 30P 16:9", nil];
    
    pickerResolu = [[UIPickerView alloc] initWithFrame:Rect(0, 38, kScreenSourchWidth, 216)];
    
    pickerResolu.delegate = self;
    
    pickerResolu.dataSource = self;
    
    [backView addSubview:pickerResolu];
    
    [self.view addSubview:viewResolution];
    
    viewResolution.hidden = YES;
    
}

-(void)hiddenResolu
{
    viewResolution.hidden = YES;
}

-(void)setResolution
{
    [self.view makeToastActivity];
    __weak SettingViewController *__self = self;
    __weak UIView *__viewResolution = viewResolution;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[MyBSDSocket sharedMyBSDSocket] setResolution:[aryResolution objectAtIndex:[pickerResolu selectedRowInComponent:0]]];
        __self.strRelolution = [aryResolution objectAtIndex:[pickerResolu selectedRowInComponent:0]];
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__self.view hideToastActivity];
            [__self.tableView reloadData];
            __viewResolution.hidden = YES;
        });
    });
}

-(void)initPickerStamp
{
    viewStamp = [[UIView alloc] initWithFrame:self.view.bounds];
    UIView *headView = [[UIView alloc] initWithFrame:Rect(0, 0,kScreenSourchWidth, kScreenSourchHeight-254)];
    [headView setBackgroundColor:RGB(128, 128, 128)];
    [viewStamp addSubview:headView];
    headView.alpha = 0.5f;
    UIView *backView = [[UIView alloc] initWithFrame:Rect(0, kScreenSourchHeight-254 , kScreenSourchWidth, 254)];
    [viewStamp addSubview:backView];
    [backView setBackgroundColor:RGB(255, 255, 255)];
    
    UIButton *btnCan = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnCan setTitle:@"Cancel" forState:UIControlStateNormal];
    [btnCan setTitleColor:RGB(0, 188, 77) forState:UIControlStateNormal];
    [backView addSubview:btnCan];
    btnCan.titleLabel.font = XCFONT(15);
    btnCan.frame = Rect(10, 0,70, 37);
    [btnCan addTarget:self action:@selector(hiddenStamp) forControlEvents:UIControlEventTouchUpInside];
    
    btnStamp = [UIButton buttonWithType:UIButtonTypeCustom];
    [backView addSubview:btnStamp];
    [btnStamp setTitle:@"OK" forState:UIControlStateNormal];
    [btnStamp setTitleColor:RGB(0, 188, 77) forState:UIControlStateNormal];
    btnStamp.titleLabel.font = XCFONT(15);
    [btnStamp addTarget:self action:@selector(settingStamp) forControlEvents:UIControlEventTouchUpInside];
    btnStamp.frame = Rect(kScreenSourchWidth-50,0, 44,37);
    
    UILabel *lblContent = [[UILabel alloc] initWithFrame:Rect(0, 37, kScreenSourchWidth, 1)];
    [lblContent setBackgroundColor:[UIColor grayColor]];
    [backView addSubview:lblContent];
    
    pickerStamp = [[UIPickerView alloc] initWithFrame:Rect(0,38, kScreenSourchWidth, 216)];
    pickerStamp.delegate = self;
    pickerStamp.dataSource = self;
    aryStamp = [[NSArray alloc] initWithObjects:@"date",@"time",@"data/time",@"off", nil];

    [backView addSubview:pickerStamp];
    
    [self.view addSubview:viewStamp];
    
    viewStamp.hidden = YES;
}

-(void)hiddenStamp
{
    viewStamp.hidden = YES;
}

-(void)initWithArray
{
    firstAry = [[NSArray alloc] initWithObjects:@"Video stamp",@"Format Camera", nil];
    secondAry = [[NSArray alloc] initWithObjects:@"File sorting",@"Network caching value"
                 ,@"Time setting",@"Total space",@"Free space",@"video_resolution",nil];
    thrAry = [[NSArray alloc] initWithObjects:@"App Version",@"Product Name",@"About",nil];
}

-(void)initWithTable
{
    _tableView = [[UITableView alloc] initWithFrame:Rect(0, 64, kScreenSourchWidth, kScreenSourchHeight-64) style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    [self.view addSubview:_tableView];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
}

-(void)initHeadView
{
    [self setTitleText:@"Setting"];
    UIButton *btnLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnLeft setImage:[UIImage imageNamed:@"btn_set_normal"] forState:UIControlStateHighlighted];
    [btnLeft setImage:[UIImage imageNamed:@"btn_set_high"] forState:UIControlStateNormal];
    [btnLeft addTarget:self action:@selector(leftClick) forControlEvents:UIControlEventTouchUpInside];
    [self setLeftBtn:btnLeft];
}

-(void)leftClick
{
    [(AppDelegate*)[[UIApplication sharedApplication] delegate] showLeft];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:RGB(0, 0, 0)];
    [self initHeadView];
    [self initWithArray];
    [self initWithTable];
    [self initPickerStamp];
    [self initPickerResolu];
    [self initDateView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0:
        {
            return firstAry.count;
        }
        break;
        case 1:
        {
            return  secondAry.count;
        }
        break;
        case 2:
        {
            return  thrAry.count;
        }
        break;
    }
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *strSettingIdentifier = @"SETTINGIDENTIFIER";
    SettingCell *cell = [tableView dequeueReusableCellWithIdentifier:strSettingIdentifier];
    if (cell==nil) {
        cell = [[SettingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strSettingIdentifier];
    }
    NSString *strText = nil;
    switch (indexPath.section)
    {
        case 0:
        {
            strText = [firstAry objectAtIndex:indexPath.row];
            if (indexPath.row==0 && _strStamp!= nil && ![_strStamp isEqualToString:@""])
            {
                [cell setContent:_strStamp];
            }
        }
        break;
            
        case 1:
        {
            strText = [secondAry objectAtIndex:indexPath.row];
            
            if (indexPath.row ==3 && nAllSpace>0)
            {
                [cell setContent:[NSString stringWithFormat:@"%.02f MB",(float)nAllSpace/1024]];
            }
            else if(indexPath.row == 4 && nFreeSpace > 0)
            {
                [cell setContent:[NSString stringWithFormat:@"%.02f MB",(float)nFreeSpace/1024]];
            }
            else if(indexPath.row == 5 && _strRelolution != nil && ![_strRelolution isEqualToString:@""])
            {
                [cell setContent:_strRelolution];
            }
        }
        break;
        case 2:
        {
            strText = [thrAry objectAtIndex:indexPath.row];
            if (indexPath.row == 0)
            {
                [cell setContent:@"1.0"];
            }
            else if(indexPath.row == 1)
            {
                [cell setContent:@"SmartCarLife"];
            }
            else if(indexPath.row == 2)
            {
                
            }
        }
        break;
    }
    cell.txtLabel.text = strText;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return  cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 43.5;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 15;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0:
        {
            if (indexPath.row==0)
            {
                [viewStamp setHidden:NO];
            }
            else
            {
                if (_strRelolution)
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Remind" message:@"Are you sure Format?" delegate:self cancelButtonTitle:@"cancel" otherButtonTitles:@"continue", nil];
                    [alert show];
                    alert.tag = 1000;
                    alert.delegate = self;
                }
                else
                {
                    [self.view makeToast:@"导航仪通信异常"];
                }
            }
        }
        break;
        case 1:
        {
            if (indexPath.row == 5)
            {
                viewResolution.hidden = NO;
            }
            else if(indexPath.row==2)
            {
                viewDate.hidden = NO;
            }
        }
        default:
            break;
    }
}



#pragma mark pickerDataSource
-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if (pickerStamp == pickerView) {
        return aryStamp.count;
    }
    return aryResolution.count;
}

-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if (pickerView == pickerStamp) {
        return [aryStamp objectAtIndex:row];
    }
    return [aryResolution objectAtIndex:row];
}

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 44;
}

-(void)format_gcd
{
    __weak SettingViewController *__self = self;
    [self.view makeToastActivity];
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [[MyBSDSocket sharedMyBSDSocket] formatSdCard];
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__self.view hideToastActivity];
        });
    });
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 1000) {
        switch (buttonIndex) {
            case 1:
            {
                [self format_gcd];
            }
            break;
                
            default:
                break;
        }
    }
}

@end
