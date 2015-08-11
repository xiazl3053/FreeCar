//
//  LSTcpSocket.h
//  FreeCar
//
//  Created by xiongchi on 15/7/8.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LSTcpSocket : NSObject

DEFINE_SINGLETON_FOR_HEADER(LSTcpSocket);


-(BOOL)connectHost:(NSString *)strHost port:(int)nPort;

-(BOOL)sendData:(NSData *)data;

-(BOOL)recvData:(NSData *)data;

-(void)closeSocket;



@end
