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

#define _minBufferedDuration 0.2
#define _maxBufferedDuration 0.4


@interface PlayViewController ()
{
    UIView *_topHUD;
    UIView *_downHUD;
    UIImageView *bgView;
    UIImageView *downBgView;
    UILabel *_lblName;
    UIButton *_doneButton;
    RecordDecoder *decode;
    int _tickCounter;
    int nAllTime;
    
    BOOL _buffered;
    CGFloat _bufferedDuration;
    
    NSTimeInterval      _tickCorrectionTime;
    NSTimeInterval      _tickCorrectionPosition;
    
    CGFloat _moviePosition;
    
    dispatch_queue_t _dispatchQueue;
    
    UITapGestureRecognizer *tapGesture;
    
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

@implementation PlayViewController
NSString * formatTimeInterval(CGFloat seconds, BOOL isLeft)
{
    seconds = MAX(0, seconds);

    int s = seconds;
    int m = s / 60;
    int h = m / 60;

    s = s % 60;
    m = m % 60;

    return [NSString stringWithFormat:@"%@%d:%0.2d:%0.2d", isLeft ? @"-" : @"", h,m,s];
}

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
    [self.view setBackgroundColor:RGB(0, 0, 0)];
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
    
    _downHUD = [[UIView alloc] initWithFrame:Rect(0, fHeight-50, fWidth, 50)];

    downBgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"ptz_bg"]];
    [bgView setFrame:_downHUD.bounds];
    [_downHUD addSubview:downBgView];
    
    _progressLabel = [[UILabel alloc] initWithFrame:CGRectMake(3,5,60,20)];
    _progressLabel.backgroundColor = [UIColor clearColor];
    _progressLabel.opaque = NO;
    _progressLabel.adjustsFontSizeToFitWidth = NO;
    _progressLabel.textAlignment = NSTextAlignmentRight;
    _progressLabel.textColor = [UIColor whiteColor];
    _progressLabel.text = @"00:00:00";
    _progressLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0f];
    
    _progressSlider = [[UISlider alloc] initWithFrame:CGRectMake(68,5,fWidth-136,20)];
    
    _progressSlider.continuous = NO;
    _progressSlider.value = 0;
    [_progressSlider setUserInteractionEnabled:YES];
    
    _leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(fWidth-60,5,60,20)];
    _leftLabel.backgroundColor = [UIColor clearColor];
    _leftLabel.opaque = NO;
    _leftLabel.adjustsFontSizeToFitWidth = NO;
    _leftLabel.textAlignment = NSTextAlignmentLeft;
    _leftLabel.textColor = [UIColor grayColor];
    _leftLabel.font = [UIFont fontWithName:@"Helvetica" size:12.0f];
    _leftLabel.text = @"00:00:00";
    _leftLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
    
    [_downHUD addSubview:_progressSlider];
    [_downHUD addSubview:_progressLabel];
    [_downHUD addSubview:_leftLabel];
    
    [_progressSlider addTarget:self
                        action:@selector(progressDidChange:)
              forControlEvents:UIControlEventValueChanged];
    
    [self.view addSubview:_downHUD];
    
    _btnPlay = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnPlay setImage:[UIImage imageNamed:@"record_play"] forState:UIControlStateNormal];
    [_btnPlay setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
    [_btnPlay addTarget:self action:@selector(playDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:_btnPlay];
    _btnPlay.tag = 1001;
    
    _btnRewind = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnRewind setImage:[UIImage imageNamed:@"rewind"] forState:UIControlStateNormal];
    [_btnRewind setImage:[UIImage imageNamed:@"rewind_h"] forState:UIControlStateHighlighted];
    [_btnRewind addTarget:self action:@selector(rewindDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:_btnRewind];
    _btnRewind.tag = 1002;
    
    
    _btnForward = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btnForward setImage:[UIImage imageNamed:@"forward"] forState:UIControlStateNormal];
    [_btnForward setImage:[UIImage imageNamed:@"forward_h"] forState:UIControlStateHighlighted];
    [_btnForward addTarget:self action:@selector(forwardDidTouch:) forControlEvents:UIControlEventTouchUpInside];
    [_downHUD addSubview:_btnForward];
    _btnForward.tag = 1003;
    
    _btnPlay.frame = Rect(fWidth/2,  40, 30, 30);
    _btnRewind.frame = Rect(fWidth/2-50, 40, 30, 30);
    _btnForward.frame = Rect(fWidth/2+50, 40, 30, 30);
    
    
    
   decode = [[RecordDecoder alloc] initWithRtsp:_model.strName];
}

-(void)tapEvent
{
    _topHUD.hidden = !_topHUD.hidden;
    _downHUD.hidden = !_downHUD.hidden;
}

-(void)playDidTouch:(id)sender
{
    if (decode)
    {
        if (self.bPlaying)
        {
            [self pause];
            _pausing = YES;
        }
        else
        {
            _bPlaying = YES;
            _bDecoding = NO;
            _btnPlay.selected = YES;
            __weak PlayViewController *__self = self;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_global_queue(0, 0),
            ^{
                [__self startPlay];
            });
            _pausing = NO;
        }
    }
    else
    {
        __weak PlayViewController *weakSelf = self;
        dispatch_async(dispatch_get_global_queue(0, 0), ^
        {
             [weakSelf startConnect];
        });
    }
}

- (void)pause
{
    if (!self.bPlaying)
    {
        return;
    }
    _pausing = YES;
    __weak UIButton *btnPlay = _btnPlay;
    dispatch_async(dispatch_get_main_queue(), ^{
        btnPlay.selected = NO;
    });
    self.bPlaying = NO;
    self.bDecoding = YES;
    DLog(@"pause movie");
}

#pragma mark 快进
-(void)forwardDidTouch:(id)sender
{
    if(_moviePosition+nAllTime * 0.2 < nAllTime)
    {
        [self setMoviePosition: _moviePosition + nAllTime*0.2];
    }
}
#pragma mark 快退
-(void)rewindDidTouch:(id)sender
{
    if (_moviePosition - nAllTime *0.2 > 0 )
    {
        [self setMoviePosition: _moviePosition - nAllTime*0.2];
    }
}

-(void)progressDidChange:(UISlider*)sender
{
    UISlider *slider = sender;
    [self setMoviePosition:slider.value * nAllTime];
}

- (void) setMoviePosition: (CGFloat) position
{
    _bPlaying = NO;
    _moviePosition = position;
    __weak PlayViewController *_weakSelf =self;
    dispatch_async(dispatch_get_global_queue(0, 0), ^(void)
    {
        [_weakSelf updatePosition:position];
    });
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

- (void) updatePosition: (CGFloat) position
{
    [self freeBufferedFrames];
    position = MIN(nAllTime, MAX(0, position));
    __weak PlayViewController *weakSelf = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
           [weakSelf setDecoderPosition: position];
           [weakSelf setMoviePositionFromDecoder];
           dispatch_async(dispatch_get_main_queue(),
           ^{
                [weakSelf updateHUD];
           });
           if(!weakSelf.pausing)
           {
               weakSelf.bPlaying = YES;
               weakSelf.bDecoding = NO;
               dispatch_after(dispatch_time(DISPATCH_TIME_NOW,0.3 * NSEC_PER_SEC),dispatch_get_global_queue(0, 0),
               ^{
                   [weakSelf startPlay];
               });
           }
    });
}

- (void) setDecoderPosition: (CGFloat) position
{
    decode.position = position;
}

#pragma mark 视频时间戳
- (void) setMoviePositionFromDecoder
{
    _moviePosition= decode.position;
}

-(void)doneDidTouch
{
    __weak PlayViewController *__self = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [__self stopPlay];
    });
    
//    [[UIDevice currentDevice] setValue: [NSNumber numberWithInteger:UIDeviceOrientationLandscapeLeft] forKey:@"orientation"];
    [self dismissViewControllerAnimated:YES completion:
     ^{
//        [[UIApplication sharedApplication] setStatusBarOrientation:UIInterfaceOrientationPortrait animated:YES];
        [[NSNotificationCenter defaultCenter] postNotificationName:MESSAGE_UPDATE_RECORD_VC object:nil];
    }];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _dispatchQueue = dispatch_queue_create("xzlDecoder", DISPATCH_QUEUE_SERIAL);
    _btnPlay.selected = YES;
    
    __weak PlayViewController *__self = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        [__self startConnect];
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
        __weak RecordDecoder *__decoder = decode;
        nAllTime = decode.nSecond;
        dispatch_async(dispatch_get_main_queue(),
        ^{
            __self.leftLabel.text = formatTimeInterval(__decoder.nSecond,NO);
        });
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
    [_imgView setUserInteractionEnabled:YES];
    [_imgView addGestureRecognizer:tapGesture];
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
    
    @synchronized(_videoFrames)
    {
        [_videoFrames removeAllObjects];
    }
    decode = nil;
    
}

-(void)startPlay
{
    if (_buffered && ((_bufferedDuration > _minBufferedDuration) || decode.isEOF))
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
            if (decode.isEOF)
            {
                __weak PlayViewController *__self = self;
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
        __weak PlayViewController *__weakSelf = self;
        const NSTimeInterval correction = [self tickCorrection];
        const NSTimeInterval time = MAX(interval + correction, 0.001);
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, time * NSEC_PER_SEC);
        dispatch_after(popTime, dispatch_get_global_queue(0, 0),
        ^{
            [__weakSelf startPlay];
        });
    }
    if (_tickCounter++%3==0)
    {
        __weak PlayViewController *__self = self;
        dispatch_async(dispatch_get_main_queue(),
        ^{
            [__self updateHUD];
        });
    }
}

-(void)updateHUD
{
    const CGFloat duration = decode.duration;
    const CGFloat position = _moviePosition;
    
    if (_progressSlider.state == UIControlStateNormal)
        _progressSlider.value = position / duration;
    _progressLabel.text = formatTimeInterval(position, NO);
    
    if (decode.duration != MAXFLOAT)
        _leftLabel.text = formatTimeInterval(duration - position, YES);
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
    __weak RecordDecoder *__decoder = decode;
    __weak PlayViewController *__weakSelf = self;
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
        DLog(@"贴图:%d",nIndex++);
        KxVideoFrameRGB *rgbFrame = (KxVideoFrameRGB *)frame;
        __weak KxVideoFrameRGB *__rgbFrame = rgbFrame;
        __weak UIImageView *__imgView = _imgView;
        dispatch_sync(dispatch_get_main_queue(),
        ^{
            __imgView.image = [__rgbFrame asImage];
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
}

@end
