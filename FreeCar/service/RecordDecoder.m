//
//  RtspDecode.m
//  FreeCar
//
//  Created by xiongchi on 15/7/21.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "RecordDecoder.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"
#import "DecoderPublic.h"
#define kLibraryPath  [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]

static void avStreamFPSTimeBase(AVStream *st, CGFloat defaultTimeBase, CGFloat *pFPS, CGFloat *pTimeBase)
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



@interface RecordDecoder()
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
    NSMutableData *data;
    CGFloat _videoTimeBase;
}
@property (nonatomic,copy) NSString *strRtsp;

@end

@implementation RecordDecoder

-(void)dealloc
{
    [self closeScaler];
    
    avcodec_free_frame(&pFrame);
    
    avcodec_close(pCodecCtx);
    
    avformat_free_context(pFormatCtx);
    DLog(@"释放");
}


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
    _strRtsp = strPath;
    _nSecond = 0;
    _bEnd = NO;
    [self connectRtsp];
    return self;
}

-(BOOL)connectRtsp
{
    ///var/mobile/Containers/Data/Application/B1AA65BD-90B7-44C4-AF0A-63103B275320/Library/record/08061712_0007.MP4
    NSString *strPath = [NSString stringWithFormat:@"%@/record/%@",kLibraryPath,_strRtsp];
    if(avformat_open_input(&pFormatCtx,[strPath UTF8String], NULL, NULL)!=0)
    {
        DLog(@"连接失败");
        return NO;
    }
    DLog(@"连接成功");
    
    if(avformat_find_stream_info(pFormatCtx, NULL)<0)
    {
        DLog(@"找不到码流");
        return NO;
    }
    DLog(@"找到码流信息");
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
    pFrame = avcodec_alloc_frame();
    
    AVStream *st = pFormatCtx->streams[_videoStream];
    avStreamFPSTimeBase(st, 0.04, &_fps, &_videoTimeBase);
    
    _nSecond = (int)pFormatCtx->streams[_videoStream]->duration*pFormatCtx->streams[_videoStream]->time_base.num/pFormatCtx->streams[_videoStream]->time_base.den;
    
    DLog(@"seconds:%d---%f",_nSecond,_fps);
    
    return YES;
}

-(NSArray *)decodeFrames
{
    int gotframe;
    AVPacket packet;
    NSMutableArray *result = [NSMutableArray array];
    BOOL bFinish = NO;
    CGFloat minDuration = 0.1;
    CGFloat decodedDuration = 0;
    while (!bFinish)
    {
        if (av_read_frame(pFormatCtx, &packet) < 0)
        {
            _isEOF = YES;
            break;
        }
//        DLog(@"packet:%d",packet.size);
        if(packet.stream_index == _videoStream)
        {
            int pktSize = packet.size;
            int len = avcodec_decode_video2(pCodecCtx,pFrame,&gotframe,&packet);
            if (gotframe)
            {
                KxVideoFrame *frameVideo = [self handleVideoFrame];
                if (frameVideo)
                {
                    [result addObject:frameVideo];
                    _position = frameVideo.position;
                    decodedDuration += frameVideo.duration;
                    bFinish = YES;
                }
                frameVideo = nil;
            }
            if (0 == len || -1 == len)
            {
                continue;
            }
            pktSize -= len;
        }
        av_free_packet(&packet);
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
    
    frame.position = av_frame_get_best_effort_timestamp(pFrame) * _videoTimeBase;
    
    const int64_t frameDuration = av_frame_get_pkt_duration(pFrame);
    
    if (frameDuration)
    {
        frame.duration = frameDuration * _videoTimeBase;
        frame.duration += pFrame->repeat_pict * _videoTimeBase * 0.5;
    }
    else
    {
        frame.duration = 1.0 / _fps;
    }
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
    DLog(@"释放scaler");
    if (_swsContext)
    {
        sws_freeContext(_swsContext);
        _swsContext = NULL;
    }
    
    if (_pictureValid)
    {
        avpicture_free(&_picture);
        _pictureValid = NO;
    }
}


- (CGFloat) duration
{
    if (!pFormatCtx)
        return 0;
    if (pFormatCtx->duration == AV_NOPTS_VALUE)
        return MAXFLOAT;
    return (CGFloat)pFormatCtx->duration / AV_TIME_BASE;
}

#pragma mark 快进控制
- (void) setPosition: (CGFloat)seconds
{
    _position = seconds;
    _isEOF = NO;
    if (_videoStream != -1)
    {
        av_seek_frame(pFormatCtx, -1, _position*AV_TIME_BASE, AVSEEK_FLAG_ANY);
    }
}

@end
