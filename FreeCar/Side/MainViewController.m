//
//  PlayViewController.m
//  FreeCar
//
//  Created by xiongchi on 15/7/21.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "MainViewController.h"
#import "rtspDecode.h"
#import "AppDelegate.h"
#import "UIView+Extension.h"
#import "MyBSDSocket.h"
#import "DecoderPublic.h"

@interface MainViewController()
{
    RtspDecode *decode;
}
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
    
//    UIButton *btnRight  = [UIButton buttonWithType:UIButtonTypeCustom];
//    [btnRight setImage:[UIImage imageNamed:@"btn_remove_normal"] forState:UIControlStateHighlighted];
//    [btnRight setImage:[UIImage imageNamed:@"btn_remove_high"] forState:UIControlStateNormal];
//    [btnRight addTarget:self action:@selector(rightClick) forControlEvents:UIControlEventTouchUpInside];
//    [self setRightBtn:btnRight];
}

-(void)rightClick
{
    
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
    _videoFrames = [NSMutableArray array];
    [self createGlView];
    _imgView.image = [UIImage imageNamed:@"bf_live_preview"];
//    UIButton *btnTest = [UIButton buttonWithType:UIButtonTypeCustom];
//    [btnTest setTitle:@"播放" forState:UIControlStateNormal];
//    [self.view addSubview:btnTest];
//    [btnTest addTarget:self action:@selector(connectRealPlay) forControlEvents:UIControlEventTouchUpInside];
//    btnTest.frame = Rect(50, 64, 64, 30);
//    btnTest.titleLabel.font = XCFONT(15);
//    _btnPlay = btnTest;
    
//    _btnPlay.frame = Rect(, <#y#>, 61.5, 61.5);
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _imgView.frame = Rect(0, kScreenSourchHeight/2-kScreenSourchWidth/2, kScreenSourchWidth,kScreenSourchWidth);
    __weak MainViewController *__self = self;
    
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
       [__self connectRealPlay];
    });
}
-(void)stopPlay
{
    _bPlaying = NO;
    _bDecoding = YES;
    __weak MainViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
       [__self.imgView setImage:[UIImage imageNamed:@"bf_live_preview"]];
    });
    decode = nil;
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    __weak MainViewController *__self = self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        [__self stopPlay];
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
        __weak MainViewController *__self = self;
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
    _imgView = [[UIImageView alloc] initWithFrame:Rect(0, 20, self.view.width, self.view.height-20)];
    [self.view addSubview:_imgView];
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
    __weak RtspDecode *__decoder = decode;
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
    return UIInterfaceOrientationMaskPortrait;
}

-(void)connectRealPlay
{
    MyBSDSocket *bsdSocket = [MyBSDSocket sharedMyBSDSocket];
    if([bsdSocket connectMedia])
    {
        decode = [[RtspDecode alloc] initWithRtsp:@"rtsp://192.168.42.1/live"];
        __weak MainViewController *__self = self;
        dispatch_async(dispatch_get_global_queue(0, 0),
        ^{
            [__self startConnect];
        });
    }
    else
    {
        DLog(@"连接失败");
    }
}

@end
