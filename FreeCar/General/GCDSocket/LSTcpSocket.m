//
//  LSTcpSocket.m
//  FreeCar
//
//  Created by xiongchi on 15/7/8.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "LSTcpSocket.h"

#import "GCDAsyncSocket.h"

@interface LSTcpSocket()<GCDAsyncSocketDelegate>
{
    
}

@property (nonatomic,strong) GCDAsyncSocket *asyncSocket;

@end



@implementation LSTcpSocket

DEFINE_SINGLETON_FOR_CLASS(LSTcpSocket);

-(BOOL)sendData:(NSData *)data
{
    BOOL bReturn = NO;
    return bReturn;
}

-(BOOL)recvData:(NSData *)data
{
    BOOL bReturn = NO;
    return bReturn;
}

-(BOOL)connectHost:(NSString *)strHost port:(int)nPort
{
    BOOL bReturn = NO;
    _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(0, 0)];
    NSError *error = nil;
    [_asyncSocket connectToHost:strHost onPort:nPort error:&error];
    if(error != nil)
    {
        DLog(@"error:%@",error);
        _asyncSocket.delegate = nil;
        return bReturn;
    }
    NSData *msgData = [@"123456789" dataUsingEncoding:NSUTF8StringEncoding];
    [_asyncSocket writeData:msgData withTimeout:50 tag:123];
    return bReturn;
}
-(void)closeSocket
{
    
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    DLog(@"123:%lu",tag);
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    DLog(@"销毁");
}

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    DLog(@"host:%@--port:%d",host,port);
}

@end
