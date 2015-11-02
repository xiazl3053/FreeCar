//
//  PlayViewController.m
//  FreeCar
//
//  Created by xiongchi on 15/7/21.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "MainViewController.h"
#import "rtspDecode.h"
#import "Toast+UIView.h"
#import "AppDelegate.h"
#import "UIView+Extension.h"
#import "MyBSDSocket.h"
#import "DecoderPublic.h"

@interface MainViewController()
{
//    RtspDecode *decode;
    BOOL bScreen;
    UITapGestureRecognizer *doubleGesture;
    CGFloat fHeight;
}
@property (nonatomic,strong) NSMutableArray *aryDecoder;
@property (nonatomic,strong) UIButton *btnPlay;
@property (nonatomic,assign) BOOL bDecoding;
@property (nonatomic,assign) BOOL bPlaying;
@property (nonatomic,strong) NSMutableArray *videoFrames;
@property (nonatomic,strong) UIImageView *imgView;

@end

@implementation MainViewController

-(void)initHeadView
{
    [self setTitleText:@"Live preview"];
    
    UIButton *btnLeft = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnLeft setImage:[UIImage imageNamed:@"btn_set_normal"] forState:UIControlStateHighlighted];
    [btnLeft setImage:[UIImage imageNamed:@"btn_set_high"] forState:UIControlStateNormal];
    [btnLeft addTarget:self action:@selector(leftClick) forControlEvents:UIControlEventTouchUpInside];
    [self setLeftBtn:btnLeft];
    
    
    UIButton *btnRight = [UIButton buttonWithType:UIButtonTypeCustom];
    [btnRight setImage:[UIImage imageNamed:@"button_live-preview_full_normal"] forState:UIControlStateNormal];
    [btnRight setImage:[UIImage imageNamed:@"button_live-preview_full_onpress"] forState:UIControlStateHighlighted];
    [self setRightBtn:btnRight];
    [btnRight addTarget:self action:@selector(rightClick) forControlEvents:UIControlEventTouchUpInside];
}

-(void)rightClick
{
    [self fullPlayMode];
}

#pragma mark 全屏与四屏切换，设置frame与bounds
-(void)fullPlayMode
{
    if (!bScreen)//NO状态表示当前竖屏，需要转换成横屏
    {
        CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
        [[UIDevice currentDevice] setValue: [NSNumber numberWithInteger:UIDeviceOrientationLandscapeRight] forKey:@"orientation"];
        [UIViewController attemptRotationToDeviceOrientation];
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        CGRect frame = [UIScreen mainScreen].bounds;
        CGPoint center = CGPointMake(frame.origin.x + ceil(frame.size.width/2), frame.origin.y + ceil(frame.size.height/2));
        self.view.center = center;
        self.view.transform = [self transformView];
        self.view.bounds = Rect(0, 0, frame.size.height, frame.size.width);
        [UIView commitAnimations];
        bScreen = !bScreen;
    }
    else
    {
        [self setHorizontal];
        bScreen = !bScreen;
    }
}

-(void)setHorizontal
{
    [[UIDevice currentDevice] setValue: [NSNumber numberWithInteger:UIDeviceOrientationPortrait] forKey:@"orientation"];
    CGFloat duration = [UIApplication sharedApplication].statusBarOrientationAnimationDuration;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:duration];
    CGRect frame = [UIScreen mainScreen].bounds;
    CGPoint center = CGPointMake(frame.origin.x + ceil(frame.size.width/2), frame.origin.y + ceil(frame.size.height/2));
    self.view.center = center;
    self.view.transform = [self transformView];
    self.view.bounds = CGRectMake(0, 0, kScreenSourchWidth, kScreenSourchHeight);
    [UIView commitAnimations];
}

-(CGAffineTransform)transformView
{
    if (!bScreen)
    {
        return CGAffineTransformMakeRotation(M_PI/2);
    }
    else
    {
        return CGAffineTransformIdentity;
    }
}


-(void)leftClick
{
    [(AppDelegate*)[[UIApplication sharedApplication] delegate] showLeft];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _aryDecoder = [NSMutableArray array];
    [self.view setBackgroundColor:RGB(0, 0, 0)];
    [self initHeadView];
    _videoFrames = [NSMutableArray array];
    [self createGlView];
    _imgView.image = [UIImage imageNamed:@"bf_live_preview"];
    fHeight = (float)kScreenSourchWidth/16*10;
    _imgView.frame = Rect(0, kScreenSourchHeight/2-fHeight/2, kScreenSourchWidth,fHeight);
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    __weak MainViewController *__self = self;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [__self.view makeToastActivity];
    });
    
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
       [__self connectRealPlay];
    });
}
-(void)stopPlay
{
    _bPlaying = NO;
    _bDecoding = YES;
    if (_aryDecoder.count>0)
    {
        RtspDecode *rtsp = (RtspDecode *)[_aryDecoder objectAtIndex:0];
        [rtsp setRtspExit];
        [NSThread sleepForTimeInterval:0.3];
        rtsp = nil;
        [_aryDecoder removeObjectAtIndex:0];
    }
    __weak MainViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
       [__self.imgView setImage:[UIImage imageNamed:@"bf_live_preview"]];
    });
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopPlay) name:MESSAGE_ENTER_BACK_VC object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MESSAGE_ENTER_BACK_VC object:nil];
    __weak MainViewController *__self = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [__self stopPlay];
    });
}

-(void)startConnect
{
    
}

- (void)didReceiveMemoryWarning
{
    
    [super didReceiveMemoryWarning];
}

-(void)createGlView
{
    _imgView = [[UIImageView alloc] initWithFrame:Rect(0, 20, self.view.width, self.view.height-20)];
    [self.view addSubview:_imgView];
    doubleGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(rightClick)];
    doubleGesture.numberOfTapsRequired = 2;
    [_imgView addGestureRecognizer:doubleGesture];
    [_imgView setUserInteractionEnabled:YES];
}

-(void)startPlay
{
    if(_bPlaying)
    {
        if(_videoFrames.count>0)
        {
            [self updatePlayUI];
        }
        if (_videoFrames.count==0)
        {
            //解码开启
            [self decodeAsync];
        }
        __weak MainViewController *__weakSelf = self;
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
    if (_aryDecoder.count<=0)
    {
        _bDecoding = NO;
        return ;
    }
    __weak RtspDecode *__decoder = [_aryDecoder objectAtIndex:0];
    __weak MainViewController *__weakSelf = self;
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
        UIImage *image = [rgbFrame asImage];
        __weak UIImage *__image = image;
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
    return UIInterfaceOrientationMaskPortrait;
}

-(void)connectRealPlay
{
    MyBSDSocket *bsdSocket = [MyBSDSocket sharedMyBSDSocket];
    if([bsdSocket connectMedia])
    {
        RtspDecode *decode = [[RtspDecode alloc] initWithRtsp:@"rtsp://192.168.42.1/live"];
        __weak MainViewController *__self = self;
        decode.rtspBlock = ^(int nStatus)
        {
            if (nStatus==1)
            {
                __self.bPlaying = YES;
                __self.bDecoding = NO;
                dispatch_async(dispatch_get_global_queue(0, 0), ^{
                    [__self startPlay];
                });
                dispatch_async(dispatch_get_main_queue(), ^{
                    [__self.view hideToastActivity];
                });
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(),
                ^{
                    [__self.view hideToastActivity];
                    [__self.view makeToast:@"connect fail"];
                });
            }
        };
        [decode connectRtsp];
        [_aryDecoder addObject:decode];
    }
    else
    {
        __weak MainViewController *__self = self;
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__self.view hideToastActivity];
            [__self.view makeToast:@"connect fail"];
        });
    }
}

#pragma mark 横屏
-(void)setCross
{
    [self setHeadViewHidden:YES];
    _imgView.frame = Rect(0, 0, kScreenSourchHeight, kScreenSourchWidth);
}

#pragma mark 竖屏
-(void)setVertical
{
    [self setHeadViewHidden:NO];
    _imgView.frame = Rect(0, kScreenSourchHeight/2-fHeight/2, kScreenSourchWidth,fHeight);
}

#pragma mark 加入重力支持
-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    if (!bScreen)//bScreen 旋转前判断状态：NO 表示  竖屏   YES 表示横屏      在LayoutSubviews之后与前一结论相反
    {
        //翻转为竖屏时
        [self setVertical];
    }else
    {
        //翻转为横屏时
        [self setCross];
    }
}

@end
