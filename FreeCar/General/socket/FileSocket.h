//
//  FileSocket.h
//
//  FreeCar
//  Created by xiongchi on 15/8/5.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^RecordDownloadFile)(int nStatus);

@protocol RecordDownloadDelegate <NSObject>

-(void)downloadStuats:(int)nCurrent all:(int)nAll;

@end

@interface FileSocket : NSObject

@property (nonatomic,assign) id<RecordDownloadDelegate> delegate;
@property (nonatomic,copy) RecordDownloadFile recordBlock;

-(void)initSockInfo:(int)nAll name:(NSString *)strName;

-(void)closeSocket;

@end
