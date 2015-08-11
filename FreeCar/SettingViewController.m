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

@interface SettingViewController ()<UITableViewDataSource,UITableViewDelegate,UIPickerViewDataSource,UIPickerViewDelegate>
{
    NSArray *firstAry;
    NSArray *secondAry;
    NSArray *thrAry;
    UIPickerView *pickerStamp;
    NSArray *aryStamp;
   
    UIView *viewStamp;
    UIButton *btnStamp;
    
}

@property (nonatomic,strong) UITableView *tableView;

@end

@implementation SettingViewController

-(void)settingStamp
{
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
    MyBSDSocket *mySock = [MyBSDSocket sharedMyBSDSocket];
    [mySock settingTimeInfo:strInfo type:0];
    viewStamp.hidden = YES;
}

-(void)initPickerStamp
{
    viewStamp = [[UIView alloc] initWithFrame:Rect(0, kScreenSourchHeight-254,kScreenSourchWidth,254)];
    [viewStamp setBackgroundColor:RGB(255, 255, 255)];
    
    btnStamp = [UIButton buttonWithType:UIButtonTypeCustom];
    [viewStamp addSubview:btnStamp];
    [btnStamp setTitle:@"OK" forState:UIControlStateNormal];
    [btnStamp setTitleColor:RGB(15, 173, 225) forState:UIControlStateNormal];
    btnStamp.titleLabel.font = XCFONT(15);
    [btnStamp addTarget:self action:@selector(settingStamp) forControlEvents:UIControlEventTouchUpInside];
    btnStamp.frame = Rect(kScreenSourchWidth-50,0, 44,37);
    
    UILabel *lblContent = [[UILabel alloc] initWithFrame:Rect(0, 37, kScreenSourchWidth, 1)];
    [lblContent setBackgroundColor:[UIColor grayColor]];
    [viewStamp addSubview:lblContent];
    
    pickerStamp = [[UIPickerView alloc] initWithFrame:Rect(0, 38 , kScreenSourchWidth, 216)];
    pickerStamp.delegate = self;
    pickerStamp.dataSource = self;
    aryStamp = [[NSArray alloc] initWithObjects:@"date",@"time",@"data and time",@"off", nil];
    
    [viewStamp addSubview:pickerStamp];
    [self.view addSubview:viewStamp];
    
    viewStamp.hidden = YES;
}

-(void)initWithArray
{
    firstAry = [[NSArray alloc] initWithObjects:@"Video stamp",@"Format Camera", nil];
    secondAry = [[NSArray alloc] initWithObjects:@"File sorting",@"Network caching value"
                 ,@"Time setting",@"Total space",@"Free space",nil];
    thrAry = [[NSArray alloc] initWithObjects:@"App Version",@"Product Name",@"About",@"Firmware version", nil];
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

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
        }
        break;
        case 1:
        {
            strText = [secondAry objectAtIndex:indexPath.row];
            if (indexPath.row==3)
            {
                int nAll = [[MyBSDSocket sharedMyBSDSocket] getTotalInfo];
                [cell setContent:[NSString stringWithFormat:@"%.02f MB",(float)nAll/1024]];
            }
            else if(indexPath.row==4)
            {
                int nAll = [[MyBSDSocket sharedMyBSDSocket] getFreeInfo];
                [cell setContent:[NSString stringWithFormat:@"%.02f MB",(float)nAll/1024]];
                
            }
        }
        break;
        case 2:
        {
            strText = [thrAry objectAtIndex:indexPath.row];
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
        }
        break;
        case 1:
        {
            if (indexPath.row==3)
            {
                MyBSDSocket *mySocket = [MyBSDSocket sharedMyBSDSocket];
                int nAllNumber = [mySocket getTotalInfo];
                if (nAllNumber>=0)
                {
                    float fNumber = (float)nAllNumber/(1024);
                    NSString *strMsg = [NSString stringWithFormat:@"SD卡总空间%.02f MB",fNumber];
                    [self.view makeToast:strMsg];
                }
            }
            else if(indexPath.row == 4)
            {
                MyBSDSocket *mySock = [MyBSDSocket sharedMyBSDSocket];
                int nFree = [mySock getFreeInfo];
                if (nFree>=0)
                {
                    float fNumber = (float)nFree/(1024);
                    NSString *strMsg = [NSString stringWithFormat:@"SD卡剩余空间%.02f MB",fNumber];
                    [self.view makeToast:strMsg];                   
                }
            }
        }
        break;
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
    return aryStamp.count;
}

-(NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [aryStamp objectAtIndex:row];
}

-(CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
    return 44;
}

@end
