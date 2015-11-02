//
//  RtspDecode.m
//  FreeCar
//
//  Created by xiongchi on 15/7/21.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "RtspDecode.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#import "DecoderPublic.h"
#include <sys/time.h>

#define kLibraryPath  [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]


typedef struct exit_info
{
    int nExit;
}exit_info;

static void rtspTime(AVStream *st, CGFloat defaultTimeBase, CGFloat *pFPS, CGFloat *pTimeBase)
{
    CGFloat fps, timebase;
    
    if (st->time_base.den && st->time_base.num)
        timebase = av_q2d(st->time_base);
    else if(st->codec->time_base.den && st->codec->time_base.num)
        timebase = av_q2d(st->codec->time_base);
    else
        timebase = defaultTimeBase;
    
    if (st->codec->ticks_per_frame != 1) {
        NSLog(@"WARNING: st.codec.ticks_per_frame=%d", st->codec->ticks_per_frame);
        //timebase *= st->codec->ticks_per_frame;
    }
    
    if (st->avg_frame_rate.den && st->avg_frame_rate.num)
        fps = av_q2d(st->avg_frame_rate);
    else if (st->r_frame_rate.den && st->r_frame_rate.num)
        fps = av_q2d(st->r_frame_rate);
    else
        fps = 1.0 / timebase;
    
    if (pFPS)
        *pFPS = fps;
    if (pTimeBase)
        *pTimeBase = timebase;
}

static int decode_interrupt_cb(void *ctx)
{
    exit_info *is = ctx;
//    DLog(@"nExit:%d",is->nExit);
    return is->nExit;
}

@interface RtspDecode()
{
    AVCodecContext *pCodecCtx;
    AVFormatContext *pFormatCtx;
    AVFrame *pFrame;
    struct SwsContext *_swsContext;
    AVPicture _picture;
    BOOL _pictureValid;
    CGFloat fSrcWidth,fSrcHeight;
    int _videoStream;
    NSFileHandle *fileHandle;
    NSMutableArray *_aryVideo;
    NSMutableData *data;
    NSRecursiveLock *theLock;
    exit_info *is;
}

@property (nonatomic,copy) NSString *strRtsp;

@end


@implementation RtspDecode


-(void)startRecord
{
    NSDate *senddate=[NSDate date];
    //时间格式s
    NSDateFormatter  *dateformatter=[[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"YYYY-MM-dd HH-mm-ss"];
    
    //保存文件路径
    NSDateFormatter  *fileformatter=[[NSDateFormatter alloc] init];
    [fileformatter setDateFormat:@"YYYYMMddHHmmss"];
    NSString *filePath = [NSString stringWithFormat:@"%@.mp4",[fileformatter stringFromDate:senddate]];
    //创建一个目录
    NSString *strDir = [kLibraryPath  stringByAppendingPathComponent:@"record"];
    BOOL bFlag = YES;
    if (![[NSFileManager defaultManager] fileExistsAtPath:strDir isDirectory:&bFlag])
    {
        DLog(@"目录不存在");
        [[NSFileManager defaultManager] createDirectoryAtPath:strDir withIntermediateDirectories:NO attributes:nil error:nil];
        BOOL success = [[NSURL fileURLWithPath:strDir] setResourceValue: [NSNumber numberWithBool: YES]
                                                                 forKey: NSURLIsExcludedFromBackupKey error:nil];
        if(!success)
        {
            DLog(@"Error excluding不备份文件夹");
        }
    }
    //视频文件保存路径
    NSString *strFile  = [strDir stringByAppendingPathComponent:filePath];
    //开始时间与文件名
    if ([[NSFileManager defaultManager] createFileAtPath:strFile contents:nil attributes:nil])
    {
        DLog(@"创建文件成功:%@",strFile);
    }
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:strFile];
    data = [[NSMutableData alloc] init];
}

-(id)initWithRtsp:(NSString *)strPath
{
    self = [super init];
    av_register_all();
    avcodec_register_all();
    avformat_network_init();
    _strRtsp = strPath;
    return self;
}

-(BOOL)connectRtsp
{
    pFormatCtx = avformat_alloc_context();
    is = malloc(sizeof(exit_info));
    is->nExit = 0;
    pFormatCtx->interrupt_callback.callback = decode_interrupt_cb;
    pFormatCtx->interrupt_callback.opaque = is;
    if(avformat_open_input(&pFormatCtx, [_strRtsp UTF8String], NULL, NULL) != 0 )
    {
        DLog(@"连接失败");
        if (_rtspBlock)
        {
            _rtspBlock(2);
        }
        avformat_close_input(&pFormatCtx);
        pFormatCtx = NULL;
        return NO;
    }
    
    pFormatCtx->probesize = 100 *1024;
    pFormatCtx->max_analyze_duration2 = 5 * AV_TIME_BASE;
    if(avformat_find_stream_info(pFormatCtx, NULL)<0)
    {
        if (_rtspBlock)
        {
            _rtspBlock(2);
        }
        return NO;
    }
    _videoStream = -1;
    int i=0;
    for (i = 0; i < pFormatCtx->nb_streams;i++)
    {
        if (pFormatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO)
        {
            _videoStream = i;
            break;
        }
    }
    if( _videoStream == -1 )
    {
        DLog(@"找不到视频数据");
        return NO;
    }
    pCodecCtx = pFormatCtx->streams[_videoStream]->codec;
    AVCodec *pCodec = avcodec_find_decoder(pCodecCtx->codec_id);
    if(avcodec_open2(pCodecCtx, pCodec, NULL) < 0)
    {
        return NO;
    }
//    pFrame = avcodec_alloc_frame();
    pFrame = av_frame_alloc();
    AVStream *st = pFormatCtx->streams[_videoStream];
    
    CGFloat _videoTimeBase;
    
    rtspTime(st, 0.04, &_fps, &_videoTimeBase);
    
    int nSecond = (int)pFormatCtx->streams[_videoStream]->duration*pFormatCtx->streams[_videoStream]->time_base.num/pFormatCtx->streams[_videoStream]->time_base.den;
    DLog(@"seconds:%d---%f",nSecond,_fps);
    _isEOF = NO;
    if (_rtspBlock)
    {
        _rtspBlock(1);
    }
    return YES;
}

-(NSArray *)decodeFrames
{
    int gotframe;
    AVPacket packet;
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL bFinish = NO;
    int nRef = 0;
    CGFloat minDuration = 0;
    CGFloat decodedDuration = 0;
    av_init_packet(&packet);
    while (!bFinish)
    {
        nRef = av_read_frame(pFormatCtx, &packet);
        if (nRef < 0 )
        {
            if (is->nExit)
            {
                _isEOF = YES;
                break ;
            }
        }
        if(packet.stream_index == _videoStream)
        {
            int len = avcodec_decode_video2(pCodecCtx,pFrame,&gotframe,&packet);
            if (gotframe)
            {
                KxVideoFrame *frameVideo = [self handleVideoFrame];
                if (frameVideo)
                {
                    [result addObject:frameVideo];
                    bFinish = YES;
                    decodedDuration += frameVideo.duration;
                    if (decodedDuration > minDuration)
                    {
                        bFinish = YES;
                    }
                }
                frameVideo = nil;
            }
            if (0 == len || -1 == len)
            {
                break;
            }
        }
        else
        {
            av_free_packet(&packet);
        }
    }
    av_free_packet(&packet);
    return result;
}

- (KxVideoFrame *) handleVideoFrame
{
    if (!pFrame->data[0])
    {
        return nil;
    }
    KxVideoFrame *frame;
    if (fSrcWidth != pCodecCtx->width || fSrcHeight != pCodecCtx->height)
    {
        avcodec_flush_buffers(pCodecCtx);
        [self setupScaler];
        fSrcWidth = pCodecCtx->width;
        fSrcHeight = pCodecCtx->height;
        return nil;
    }
    sws_scale(_swsContext,
              (const uint8_t **)pFrame->data,
              pFrame->linesize,
              0,
              pCodecCtx->height,
              _picture.data,
              _picture.linesize);
    KxVideoFrameRGB *rgbFrame = [[KxVideoFrameRGB alloc] init];
    rgbFrame.linesize = _picture.linesize[0];
    rgbFrame.rgb = [NSData dataWithBytes:_picture.data[0]
                                  length:rgbFrame.linesize * pCodecCtx->height];
    frame = rgbFrame;
    frame.width = pCodecCtx->width;
    frame.height = pCodecCtx->height;
    
    frame.duration = 1.0 / 25;
    return frame;
}

#pragma mark rgb
- (BOOL) setupScaler
{
    [self closeScaler];
    DLog(@"新的:%d-%d",pCodecCtx->width,pCodecCtx->height);
    _pictureValid = avpicture_alloc(&_picture,
                                    PIX_FMT_RGB24,
                                    pCodecCtx->width,
                                    pCodecCtx->height) == 0;
    if (!_pictureValid)
        return NO;
    _swsContext = sws_getCachedContext(_swsContext,
                                       pCodecCtx->width,
                                       pCodecCtx->height,
                                       pCodecCtx->pix_fmt,
                                       pCodecCtx->width,
                                       pCodecCtx->height,
                                       PIX_FMT_RGB24,
                                       SWS_FAST_BILINEAR,
                                       NULL, NULL, NULL);
    
    return _swsContext != NULL;
}
#pragma mark 关闭转换
- (void) closeScaler
{
    if (_swsContext) {
        sws_freeContext(_swsContext);
        _swsContext = NULL;
    }
    
    if (_pictureValid)
    {
        avpicture_free(&_picture);
        _pictureValid = NO;
    }
}

-(void)dealloc
{
    DLog(@"释放");
    [self closeScaler];
    av_frame_free(&pFrame);
    pFrame = NULL;
    avcodec_close(pCodecCtx);
    pCodecCtx = NULL;
    if(pFormatCtx)
    {
        DLog(@"close pFormat");
        avformat_close_input(&pFormatCtx);
        pFormatCtx = NULL;
    }
    free(is);
}

-(void)setRtspExit
{
    is->nExit = 1;
}

@end
