//
//  RecordDecoder.h
//  FreeCar
//
//  Created by xiongchi on 15/8/7.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecordDecoder : NSObject

@property (nonatomic,assign) BOOL bEnd;
@property (nonatomic,assign) int fps;

-(id)initWithRtsp:(NSString *)strPath;
-(NSArray *)decodeFrames;

@end
