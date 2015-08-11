//
//  LeftViewController.m
//  WWSideslipViewControllerSample
//
//  Created by 王维 on 14-8-26.
//  Copyright (c) 2014年 wangwei. All rights reserved.
//

// 版权属于原作者
// http://code4app.com (cn) http://code4app.net (en)
// 发布代码于最专业的源码分享网站: Code4App.com

#import "LeftViewController.h"
#import "Common.h"
#import "UIView+Extension.h"

@interface LeftViewController ()<UITableViewDataSource,UITableViewDelegate>
{
    
}
@property (nonatomic,strong) NSMutableArray *array;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NSMutableArray *itemList;
@end
@implementation LeftViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    
    _array = [NSMutableArray array];
    
    LeftCellInfo *leftInfo1 = [[LeftCellInfo alloc] initWithTitle:@"Live Preview" normal:@"ico_navigation_live-preview" high:@""];
    LeftCellInfo *leftInfo2 = [[LeftCellInfo alloc] initWithTitle:@"record" normal:@"ico_navigation_recordi" high:@""];
    LeftCellInfo *leftInfo3 = [[LeftCellInfo alloc] initWithTitle:@"Phone" normal:@"ico_navigation_phone" high:@""];
    LeftCellInfo *leftInfo4 = [[LeftCellInfo alloc] initWithTitle:@"Setting" normal:@"ico_navigation_setting" high:@""];
    [_array addObject:leftInfo1];
    [_array addObject:leftInfo2];
    [_array addObject:leftInfo3];
    [_array addObject:leftInfo4];
    
    _tableView = [[UITableView alloc] initWithFrame:Rect(0, 40,self.view.width,self.view.height)];
    
    UIImageView *imgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    imgView.image = [UIImage imageNamed:@"bg_side_navigation"];
    [self.view addSubview:imgView];
//    [_tableView setBackgroundView:imgView];
    [_tableView setBackgroundColor:[UIColor clearColor]];
    
    [self.view addSubview:_tableView];
    [_tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _tableView.delegate = self;
    _tableView.dataSource = self;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:YES];
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _array.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *strLeftDentify = @"LEFTVIEWCONTROLLERDENTIFY";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:strLeftDentify];
    if (cell==nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:strLeftDentify];
    }
    [cell setBackgroundColor:[UIColor clearColor]];
    LeftCellInfo *leftInfo = [_array objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:leftInfo.strNorImg];
    cell.textLabel.text = leftInfo.strTitle;
    cell.textLabel.font = XCFONT(14);
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *strInfo = [NSString stringWithFormat:@"%d",(int)(indexPath.row+1000)];
    [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_SHOW_MAIN_VC object:strInfo];
}



@end


@implementation LeftCellInfo

-(id)initWithTitle:(NSString *)strTitle normal:(NSString *)strNormal high:(NSString *)strHigh
{
    self = [super init];
    _strTitle = strTitle;
    _strNorImg = strNormal;
    _strHighImg = strHigh;
    
    return self;
}
@end
