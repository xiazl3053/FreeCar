//
//  RtspViewController.m
//  FreeCar
//
//  Created by xiongchi on 15/10/21.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "RtspViewController.h"
#import "RecordDecoder.h"
#import "Toast+UIView.h"
#import "UIView+Extension.h"
#import "DecoderPublic.h"
#import "RecordModel.h"
#import "RtspDecode.h"

#define _minBufferedDuration 0.01
#define _maxBufferedDuration 0.02


@interface RtspViewController ()
{
    UIView *_topHUD;
    UIView *_downHUD;
    UIImageView *bgView;
    UIImageView *downBgView;
    UILabel *_lblName;
    UIButton *_doneButton;
    int _tickCounter;
    int nAllTime;
    
    BOOL _buffered;
    CGFloat _bufferedDuration;
    
    NSTimeInterval      _tickCorrectionTime;
    NSTimeInterval      _tickCorrectionPosition;
    
    CGFloat _moviePosition;
    
    dispatch_queue_t _dispatchQueue;
    
    UITapGestureRecognizer *tapGesture;
    
    RtspDecode *_decode;
    int nIndex;
}

@property (nonatomic,strong) UIButton *btnPlay;
@property (nonatomic,strong) UIButton *btnRewind;
@property (nonatomic,strong) UIButton *btnForward;
@property (nonatomic,assign) BOOL pausing;
@property (nonatomic,assign) BOOL bDecoding;
@property (nonatomic,assign) BOOL bPlaying;
@property (nonatomic,strong) NSMutableArray *videoFrames;
@property (nonatomic,strong) UIImageView *imgView;
@property (nonatomic,strong) RecordModel *model;

@property (nonatomic,strong) UISlider *progressSlider;
@property (nonatomic,strong) UILabel *progressLabel;
@property (nonatomic,strong) UILabel *leftLabel;
@end

@implementation RtspViewController

-(id)initWithModel:(RecordModel*)model
{
    self = [super init];
    _model = model;
    _moviePosition = 0;
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:RGB(255,255,255)];
    nIndex = 0;
    [self prefersStatusBarHidden];
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapEvent)];
    _videoFrames = [NSMutableArray array];
    
    [self createGlView];
    
    CGFloat fWidth = kScreenSourchWidth > kScreenSourchHeight ? kScreenSourchWidth : kScreenSourchHeight;
    CGFloat fHeight = kScreenSourchWidth > kScreenSourchHeight ? kScreenSourchHeight : kScreenSourchWidth;
    
    _topHUD = [[UIView alloc] initWithFrame:CGRectMake(0,0,fWidth,49)];
    _topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:_topHUD];
    _topHUD.alpha = 1;
    
    [_topHUD addSubview:bgView];
    
    UILabel *sLine1 = [[UILabel alloc] initWithFrame:CGRectMake(0, _topHUD.frame.size.height-0.2, fWidth, 0.1)];
    sLine1.backgroundColor = [UIColor colorWithRed:198/255.0
                                             green:198/255.0
                                              blue:198/255.0
                                             alpha:1.0];
    UILabel *sLine2 = [[UILabel alloc] initWithFrame:CGRectMake(0, _topHUD.frame.size.height-0.1, fWidth, 0.1)] ;
    sLine2.backgroundColor = [UIColor whiteColor];
    sLine1.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    sLine2.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    [_topHUD addSubview:sLine1];
    [_topHUD addSubview:sLine2];
    
    _lblName = [[UILabel alloc] initWithFrame:Rect(30,15,fWidth-60,20)];
    
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
    [_doneButton addTarget:self action:@selector(doneDidTouch) forControlEvents:UIControlEventTouchUpInside];
    [_topHUD addSubview:_doneButton];
}

-(void)doneDidTouch
{
    [self stopPlay];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)tapEvent
{
    _topHUD.hidden = !_topHUD.hidden;
    _downHUD.hidden = !_downHUD.hidden;
}

#pragma mark 清空所有frame
- (void) freeBufferedFrames
{
    @synchronized(_videoFrames)
    {
        [_videoFrames removeAllObjects];
    }
    _bufferedDuration = 0;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _dispatchQueue = dispatch_queue_create("xzl_decoder", DISPATCH_QUEUE_SERIAL);
    __weak RtspViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [__self.view makeToastActivity];
    });
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
       [__self connectRealPlay];
    });
}

-(void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGFloat fWidth = kScreenSourchWidth > kScreenSourchHeight ? kScreenSourchWidth : kScreenSourchHeight;
    CGFloat fHeight = kScreenSourchWidth > kScreenSourchHeight ? kScreenSourchHeight : kScreenSourchWidth;
    
    _topHUD.frame = Rect(0, 0, fWidth, 50);
    
    [self.view insertSubview:_imgView atIndex:0];
    
    _lblName.frame = Rect(40, 15, 200, 20);
    
    bgView.frame = _topHUD.bounds;
    
    _downHUD.frame = Rect(0, fHeight-80, fWidth, 80);
    
    downBgView.frame = _downHUD.bounds;
    
    _progressSlider.frame = Rect(68,5,fWidth-136,20);
    
    _leftLabel.frame = Rect(fWidth-60,5,60,20);
    
    _imgView.frame = Rect(0, 0, fWidth, fHeight);
    
    _btnPlay.frame = Rect(fWidth/2,  40, 30, 30);
    _btnRewind.frame = Rect(fWidth/2-50, 40, 30, 30);
    _btnForward.frame = Rect(fWidth/2+50, 40, 30, 30);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

-(void)createGlView
{
    _imgView = [[UIImageView alloc] initWithFrame:Rect(0, 0, self.view.width, self.view.height-20)];
    bgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ptz_bg"]];
    [_imgView setUserInteractionEnabled:YES];
    [_imgView addGestureRecognizer:tapGesture];
    [bgView setFrame:_topHUD.bounds];
}

-(void)stopPlay
{
    [_decode setRtspExit];
    _bPlaying = NO;
    _bDecoding = YES;
    __weak RtspViewController *__self = self;
    dispatch_async(dispatch_get_main_queue(),
    ^{
       [__self.imgView setImage:nil];
    });
    @synchronized(_videoFrames)
    {
        [_videoFrames removeAllObjects];
    }
    [NSThread sleepForTimeInterval:0.5];
}

-(void)startPlay
{
    if (_buffered && ((_bufferedDuration > _minBufferedDuration) || _decode.isEOF))
    {
        _tickCorrectionTime = 0;
        _buffered = NO;
    }
    CGFloat interval = 0;
    if (!_buffered)
    {
        interval = [self updatePlayUI];
    }
    if(_bPlaying)
    {
        const NSUInteger leftFrames = _videoFrames.count;
        if (0 == leftFrames)
        {
            if (_decode.isEOF)
            {
                __weak RtspViewController *__self = self;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [__self doneDidTouch];
                });
                return;
            }
            
            if (_minBufferedDuration > 0 && !_buffered) {
                _buffered = YES;
            }
        }
        
        if (!leftFrames ||
            !(_bufferedDuration > _minBufferedDuration))
        {
            //解码开启
            [self decodeAsync];
        }
        __weak RtspViewController *__weakSelf = self;
        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = MAX(interval + correction, 0.001);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_global_queue(0, 0),
       ^{
           [__weakSelf startPlay];
       });
    }
}



- (CGFloat) tickCorrection
{
    if (_buffered)
    {
        return 0;
    }
    const NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];
    if (!_tickCorrectionTime)
    {
        _tickCorrectionTime = now;
        _tickCorrectionPosition = _moviePosition;
        return 0;
    }
    
    NSTimeInterval dPosition = _moviePosition - _tickCorrectionPosition;
    NSTimeInterval dTime = now - _tickCorrectionTime;
    NSTimeInterval correction = dPosition - dTime;
    
    if (correction > 1.f || correction < -1.f)
    {
        correction = 0;
        _tickCorrectionTime = 0;
    }
    return correction;
}

-(void)decodeAsync
{
    if (!_bPlaying || _bDecoding)
    {
        return ;
    }
    _bDecoding = YES;
    __weak RtspDecode *__decoder = _decode;
    __weak RtspViewController *__weakSelf = self;
    dispatch_async(_dispatchQueue,
   ^{
       BOOL bGood = YES;
       while (bGood)
       {
           bGood = NO;
           NSArray *array = [__decoder decodeFrames];
           if (array && array.count>0)
           {
               bGood = [__weakSelf addFrame:array];
           }
       }
       __weakSelf.bDecoding = NO;
   });
}

-(BOOL)addFrame:(NSArray *)frames
{
    @synchronized(_videoFrames)
    {
        for (KxMovieFrame *frame in frames)
        {
            [_videoFrames addObject:frame];
            _bufferedDuration += frame.duration;
        }
    }
    return _bPlaying && _bufferedDuration < _maxBufferedDuration;
}

-(CGFloat)updatePlayUI
{
    KxVideoFrame *frame;
    @synchronized(_videoFrames)
    {
        if (_videoFrames.count > 0)
        {
            frame = _videoFrames[0];
            [_videoFrames removeObjectAtIndex:0];
            _bufferedDuration -= frame.duration;
        }
    }
    if (frame)
    {
        KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB *)frame;
        UIImage *image = [rgbFrame asImage];
        __weak UIImage *__image = image;
        __weak UIImageView *__imgView = _imgView;
        dispatch_sync(dispatch_get_main_queue(),
          ^{
              __imgView.image = __image;
          });
        _moviePosition = frame.position;
        return frame.duration;
    }
    return 0;
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
    return YES;
}


-(void)dealloc
{
    DLog(@"释放PlayView");
    _videoFrames = nil;
    _btnPlay = nil;
    _btnRewind = nil;
    _imgView = nil;
    _model = nil;
//    if (_decode)
//    {
//        _decode = nil;
//    }
}

-(void)connectRealPlay
{
    NSString *strInfo = nil;
    NSString *strName = [NSString stringWithFormat:@"%@_thm.MP4",[_model.strName componentsSeparatedByString:@"."][0]];
    if (_model.nType==1) {
        strInfo = [NSString stringWithFormat:@"rtsp://192.168.42.1/tmp/fuse_d/DCIM/100MEDIA/%@",strName];
    }
    else
    {
        strInfo = [NSString stringWithFormat:@"rtsp://192.168.42.1/tmp/fuse_d/EVENT/%@",strName];
    }
    DLog(@"RTSP:%@",strInfo);
    _decode = [[RtspDecode alloc] initWithRtsp:strInfo];
    __weak RtspViewController *__self = self;
    _decode.rtspBlock = ^(int nStatus)
    {
        if (nStatus==1)
        {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                __self.bPlaying= YES;
                __self.bDecoding = NO;
                [__self startPlay];
                dispatch_async(dispatch_get_main_queue(), ^{
                    [__self.view hideToastActivity];
                });
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
    [_decode connectRtsp];
 
}

@end