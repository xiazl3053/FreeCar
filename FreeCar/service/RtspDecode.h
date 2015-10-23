//
//  RtspDecode.h
//  FreeCar
//
//  Created by xiongchi on 15/7/21.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^RTSPDecodeBlock)(int nStatus);

@interface RtspDecode : NSObject

@property (nonatomic,assign) int fps;

@property (nonatomic,copy) RTSPDecodeBlock rtspBlock;

@property (nonatomic,assign) BOOL isEOF;

-(id)initWithRtsp:(NSString *)strPath;

-(NSArray *)decodeFrames;

-(BOOL)connectRtsp;

@end
