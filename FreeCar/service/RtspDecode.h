//
//  RtspDecode.h
//  FreeCar
//
//  Created by xiongchi on 15/7/21.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RtspDecode : NSObject

@property (nonatomic,assign) int fps;

-(id)initWithRtsp:(NSString *)strPath;

-(NSArray *)decodeFrames;

@end
