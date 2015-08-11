//
//  PlayViewController.m
//  FreeCar
//
//  Created by xiongchi on 15/7/21.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "PlayViewController.h"
#import "RecordDecoder.h"
#import "UIView+Extension.h"
#import "DecoderPublic.h"
#import "RecordModel.h"

@interface PlayViewController ()
{
    UIView *_topHUD;
    UIImageView *bgView;
    UILabel *_lblName;
    UIButton *_doneButton;
    RecordDecoder *decode;
}
@property (nonatomic,assign) BOOL bDecoding;
@property (nonatomic,assign) BOOL bPlaying;
@property (nonatomic,strong) NSMutableArray *videoFrames;
@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) RecordModel *model;
@end

@implementation PlayViewController

-(id)initWithModel:(RecordModel*)model
{
    self = [super init];
    
    _model = model;
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:RGB(0, 0, 0)];
    [self prefersStatusBarHidden];
    _videoFrames = [NSMutableArray array];
    [self createGlView];
    _topHUD = [[UIView alloc] initWithFrame:CGRectMake(0,0,kScreenSourchWidth,49)];
    _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_topHUD];
    _topHUD.alpha = 1;
    
    [_topHUD addSubview:bgView];
    
    UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, _topHUD.frame.size.height-0.2, kScreenSourchWidth, 0.1)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, _topHUD.frame.size.height-0.1, kScreenSourchWidth, 0.1)] ;
    sLine2.backgroundColor = [UIColor whiteColor];
    sLine1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [_topHUD addSubview:sLine1];
    [_topHUD addSubview:sLine2];
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,15,kScreenSourchWidth-60,20)];
    
    [_lblName setTextAlignment:NSTextAlignmentCenter];
    
    [_lblName setText:_model.strName];
    
    [_lblName setFont:[UIFont fontWithName:@"Helvetica" size:15.0f]];
    
    [_lblName setTextColor:[UIColor whiteColor]];
    
    [_topHUD addSubview:_lblName];
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_doneButton setImage:[UIImage imageNamed:@"btn_return_nor"] forState:UIControlStateNormal];
    [_doneButton setImage:[UIImage imageNamed:@"btn_return_down"] forState:UIControlStateHighlighted];
    _doneButton.frame = CGRectMake(5,2.5,44,44);
    _doneButton.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:18];
    _doneButton.showsTouchWhenHighlighted = YES;
    [_doneButton addTarget:self action:@selector(doneDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_topHUD addSubview:_doneButton];
   decode = [[RecordDecoder alloc] initWithRtsp:_model.strName];
    
}

-(void)doneDidTouch:(UIButton *)btnSender
{
    __weak PlayViewController *__self = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [__self stopPlay];
    });
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _topHUD.frame = Rect(0, 0, kScreenSourchWidth, 50);
    
    [self.view insertSubview:_imgView atIndex:0];
    _lblName.frame = Rect(40, 15, 200, 20);
    bgView.frame = _topHUD.bounds;
    
    _imgView.frame = Rect(0, 0, kScreenSourchWidth, kScreenSourchHeight);
    
    __weak PlayViewController *__self = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [__self startConnect];
    });
}

-(void)startConnect
{
    CGFloat fTIme=0;
    if (decode)
    {
        while (decode.fps==0)
        {
            [NSThread sleepForTimeInterval:0.5f];
            fTIme+=0.5f;
            if (fTIme>30)
            {
                return ;
            }
        }
        _bPlaying = YES;
        _bDecoding = NO;
        __weak PlayViewController *__self = self;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [__self startPlay];
        });
    }
    
}

- (void)didReceiveMemoryWarning
{
     
    [super didReceiveMemoryWarning];
}

-(void)createGlView
{
    _imgView = [[UIImageView alloc] initWithFrame:Rect(0, 0, self.view.width, self.view.height-20)];
    bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ptz_bg"]];
//    [self.view addSubview:_imgView];
    [bgView setFrame:_topHUD.bounds];
    
}

-(void)stopPlay
{
    _bPlaying = NO;
    _bDecoding = YES;
    __weak PlayViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
        [__self.imgView setImage:nil];
    });
    decode = nil;
}

-(void)startPlay
{
    if(_bPlaying)
    {
        if (decode.bEnd)
        {
            DLog(@"视频播放完成");
            [self stopPlay];
            return ;
        }
        if(_videoFrames.count>0)
        {
            [self updatePlayUI];
        }
        if (_videoFrames.count==0)
        {
            //解码开启
            [self decodeAsync];
        }
        __weak PlayViewController *__weakSelf = self;
        dispatch_time_t after = dispatch_time(DISPATCH_TIME_NOW, 0.03 * NSEC_PER_SEC );
        dispatch_after(after, dispatch_get_global_queue(0, 0),
        ^{
            [__weakSelf startPlay];
        });
    }
}

-(void)decodeAsync
{
    if (!_bPlaying || _bDecoding)
    {
        return ;
    }
    _bDecoding = YES;
    __weak RecordDecoder *__decoder = decode;
    __weak PlayViewController *__weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        BOOL bGood = YES;
        while (bGood)
        {
            NSArray *array = [__decoder decodeFrames];
            bGood = NO;
            if (array && array.count>0)
            {
                @synchronized(__weakSelf.videoFrames)
                {
                    for (KxVideoFrame *frame in array)
                    {
                        [__weakSelf.videoFrames addObject:frame];
                    }
                }
                array = nil;
            }
        }
        __weakSelf.bDecoding = NO;
    });
}

-(CGFloat)updatePlayUI
{
    CGFloat interval = 0;
    KxVideoFrame *frame;
    @synchronized(_videoFrames)
    {
        if (_videoFrames.count > 0)
        {
            frame = _videoFrames[0];
            [_videoFrames removeObjectAtIndex:0];
        }
    }
    if (frame)
    {
        KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB*)frame;
        __weak UIImageView *__imgView = _imgView;
        __weak UIImage *__image = [rgbFrame asImage];
        dispatch_sync(dispatch_get_main_queue(),
                      ^{
                          [__imgView setImage:__image];
                      });
        interval = frame.duration;
    }
    frame = nil;
    return interval;
}

-(BOOL)shouldAutorotate
{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

-(BOOL)prefersStatusBarHidden
{
    return  YES;
}


@end
