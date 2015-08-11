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
#define kLibraryPath  [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]

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
    NSMutableData *data;
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
    _strRtsp = strPath;
    [self connectRtsp];
    return self;
}

-(BOOL)connectRtsp
{
    avformat_network_init();
    if(avformat_open_input(&pFormatCtx,[_strRtsp UTF8String], NULL, NULL)!=0)
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
    _fps = 25;
   
    return YES;
}

-(NSArray *)decodeFrames
{
    int gotframe;
    AVPacket packet;
    av_init_packet(&packet);
    NSMutableArray *result = [[NSMutableArray alloc] init];
    BOOL bFinish = NO;
    int nRef = 0;
    CGFloat minDuration = 0;
    CGFloat decodedDuration = 0;
    while (!bFinish)
    {
        nRef = av_read_frame(pFormatCtx, &packet);
//        DLog(@"pakcet.size:%d",packet.size);
        if(nRef>=0 && packet.stream_index == _videoStream)
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
                av_free_packet(&packet);
                break;
            }
        }
        else
        {
            //结束
            break;
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
    
    if (_pictureValid) {
        avpicture_free(&_picture);
        _pictureValid = NO;
    }
}
@end
