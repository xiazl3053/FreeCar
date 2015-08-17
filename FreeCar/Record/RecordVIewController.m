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
}
@property (nonatomic,strong) NSMutableArray *arrayRecord;
@property (nonatomic,strong) UITableView *tableView;

@end

@implementation RecordViewController

-(void)initHeadView
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
        [RecordDBService removeArray:[dicDelete allValues]];
        [_arrayRecord removeObjectsInArray:[dicDelete allValues]];
        [_tableView setEditing:NO animated:YES];
        [_tableView reloadData];
    }
    else
    {
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
    return _arrayRecord.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *strRecordViewIdentifier = @"kRecordViewIdentifier";
    DownCell *cell = [tableView dequeueReusableCellWithIdentifier:strRecordViewIdentifier];
    if (cell==nil) {
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

@end
