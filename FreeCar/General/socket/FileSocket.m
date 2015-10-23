//
//  FileSocket.m
//  FreeCar
//
//  Created by xiongchi on 15/8/5.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "FileSocket.h"
#import <netdb.h>
#import <fcntl.h>
#import <string.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import <unistd.h>
#import <stdlib.h>
#import <stdio.h>
#import <sys/wait.h>
#import <sys/types.h>
#import <sys/times.h>
#import <sys/time.h>
#import <sys/select.h>
#import <time.h>
#import <errno.h>

#define kReadFileLength   1024*400

@interface FileSocket ()
{
    int nSockfd;
    int nAllCount;
    NSString *_strFile;
    int nTemp;
}

@end

@implementation FileSocket

-(int)connect:(const char *)ip port:(int)nPort
{
    CFSocketRef socket;
	int sockfd=0;
	socket = CFSocketCreate(kCFAllocatorDefault,PF_INET ,SOCK_STREAM,IPPROTO_TCP , 0, NULL, NULL);
	struct sockaddr_in addr;
	memset(&addr,0,sizeof(addr));
	addr.sin_len = sizeof(addr);
	addr.sin_family = AF_INET;
	addr.sin_port = htons(nPort);
	addr.sin_addr.s_addr = inet_addr(ip);
	CFDataRef xteAddress = CFDataCreate(NULL,(unsigned char*)&addr,sizeof(addr));
	CFTimeInterval timeout = 5;
	CFSocketError e = CFSocketConnectToAddress(socket, xteAddress, timeout);
	if (e!=kCFSocketSuccess)
    {
		CFRelease(socket);
		return 0;
	}else
    {
		sockfd = CFSocketGetNative(socket);
		CFRelease(socket);
        nSockfd = sockfd;
        DLog(@"cg");
		return 1;
	}
	return 0;
}

-(id)init
{
    self = [super init];
//    nAllCount = nAll;
//    _strFile = strFile;
    return self;
}

-(void)initSockInfo:(int)nAll name:(NSString *)strName
{
    nAllCount = nAll;
    _strFile = strName;
    __weak FileSocket *__self = self;
    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
        if([__self connect:kXCarAddress port:8787])
        {
            [__self downloadStart];
        }
        else
        {
            DLog(@"连接失败");
        }
    });
}

-(void)downloadStart
{
    nTemp = 0;
    int nRef = 0;
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
    NSString *strFile  = [strDir stringByAppendingPathComponent:_strFile];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:strFile])
    {
        DLog(@"删除");
        [[NSFileManager defaultManager] removeItemAtPath:strFile error:nil];
    }
    else
    {
//        [[NSFileManager defaultManager] createFileAtPath:strFile contents:nil attributes:nil];
    }
    
//    NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:strFile];
    
    DLog(@"GG:strFile:%@",strFile);
    
    char cBuf[kReadFileLength];
    
    memset(&cBuf, 0, kReadFileLength);
    
    int i=0;
    
    int nNumber,nRead;
    char *puf = cBuf;
    int nLessSize=0;
    NSMutableData *fileData = [NSMutableData data];
    while (YES)
    {
        nNumber = 0;
        nRead = nAllCount - nTemp > kReadFileLength ? kReadFileLength : nAllCount - nTemp;
        if (nRead == 0)
        {
            break;
        }
        while (nNumber<nRead)
        {
            nLessSize = nRead - nNumber > 4096 ? 4096 : nRead-nNumber;
            nRef = (int)recv(nSockfd,puf+nNumber,nLessSize, 0);
            if (nRef<0)
            {
                if (_recordBlock)
                {
                    _recordBlock(0);
                }
                DLog(@"连接中断");
                return ;
            }
            nNumber += nRef;
        }
        [fileData appendBytes:cBuf length:nNumber];
        nTemp += nNumber;
        [_delegate downloadStuats:nTemp all:nAllCount];
        i++;
    }
    if([fileData writeToFile:strFile atomically:YES])
    {
        DLog(@"写入文件");
    }
    DLog(@"下载完成");
    if (_recordBlock)
    {
        _recordBlock(1);
    }
    close(nSockfd);
    
}

-(void)closeSocket
{
    close(nSockfd);
}

@end
