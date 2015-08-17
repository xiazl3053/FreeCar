//
//  MyBSDSocket.m
//  xtefirovoad
//
//  Created by xia zhonglin on 9/20/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "MyBSDSocket.h"
#import "FileSocket.h"
#import "RecordModel.h"
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

@interface MyBSDSocket()
{
    int nSockfd;
}

@end

@implementation MyBSDSocket

DEFINE_SINGLETON_FOR_CLASS(MyBSDSocket);

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

-(int)sendMessage:(NSData*)dataInfo
{
    DLog(@"dataInfo:%s",dataInfo.bytes);
    return (int)send(nSockfd,[dataInfo bytes],(int)dataInfo.length, 0);
}

-(NSData*)reciveMessage:(int)nType
{
    NSData *data = nil;
    int nCount = 0;
    do
    {
        char cData[1024*50];
        memset(cData, 0,1024*50);
        int nRef = 0;
        int nTemp = 0;
        char *buf = cData;
        while ((nRef = (int)recv(nSockfd,buf+nTemp,10240,0))!=-1)
        {
            nTemp += nRef;
            DLog(@"cdata:%s",cData);
            if (cData[nTemp-1] == '}' && cData[nTemp] == '\0')
            {
                DLog(@"收到");
                break;
            }
        }
        data = [NSData dataWithBytes:cData length:nTemp];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        int nNumber = [[dict objectForKey:@"msg_id"] intValue];
        if (nNumber == nType)
        {
            break;
        }
        DLog(@"again:%d",nType);
        nCount++;
    }while (nCount<2);
    return data;
}

-(BOOL)startSession
{
    const char *cData = "{\"msg_id\" : 257,\"token\" : 0}";
    NSData *data = [NSData dataWithBytes:cData length:strlen(cData)];
    [self sendMessage:data];
    data = nil;
    data = [NSData data];
    NSData *data1 = [self reciveMessage:257];
    NSError *error = nil;
    NSDictionary *weatherDic = [NSJSONSerialization JSONObjectWithData:data1 options:NSJSONReadingMutableLeaves error:&error];
    int nParam = [[weatherDic objectForKey:@"param"] intValue];
    _nParam = nParam;
    
    return YES;
}

-(NSData*)getAlarmRecordInfo
{
    if (self.nParam==0)
    {
        if(![self XzlConnect])
        {
            DLog(@"连接失败");
            return nil;
        }
        [self startSession];
    }
    NSString *strInfo = nil;
    //1
    NSData *data = nil;
    
    int nParam = self.nParam;
    
    strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 1284,\"token\" : %d}",self.nParam];
    
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    
    data = [self reciveMessage:1284];
    
    strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 1283,\"token\" : %d,\"param\":\"%s\"}",nParam,"/tmp/fuse_d/EVENT/"];
    
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    
    data = [self reciveMessage:1283];
    
    if(![self validateJson:data type:1283])
    {
        return nil;
    }
    
    strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 1282,\"token\" : %d,\"param\":\"-D -S\"}",self.nParam];
    
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    
    data = [self reciveMessage:1282];
    
    return data;
}

-(NSData *)getComRecordInfo
{
    if (self.nParam==0)
    {
        if(![self XzlConnect])
        {
            DLog(@"连接失败");
            return nil;
        }
        [self startSession];
    }
    NSString *strInfo = nil;
    //1
    NSData *data = nil;
    
    int nParam = self.nParam;
    
    strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 1283,\"token\" : %d,\"param\":\"%s\"}",nParam,"/tmp/fuse_d/DCIM/100MEDIA/"];
    data = [NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length];
    
    [self sendMessage:data];
    
    data = nil;
    data = [self reciveMessage:1283];
    
    if(![self validateJson:data type:1283])
    {
        return nil;
    }
    strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 1282,\"token\" : %d,\"param\":\"-D -S\"}",nParam];
    data = [NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length];
    [self sendMessage:data];
    data = nil;
    data = [self reciveMessage:1282];
    
    return data;
}

-(BOOL)connectMedia
{
    if ([self XzlConnect])
    {
        NSString *strInfo = nil;
        //1
        NSData *data = nil;
        if (![self startSession])
        {
            return NO;
        }
        int nParam = self.nParam;
        
        strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 3,\"token\" : %d}",nParam];
        
        [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
        
        [self reciveMessage:3];
        
        //3   {"msg_id" : 9,"param" : "stream_type","token" : 4}
        strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 9,\"param\" : \"stream_type\",\"token\" : %d}",nParam];
        [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
        [self reciveMessage:9];
        //4
        strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 9,\"param\" : \"stream_while_record\",\"token\" : %d}",nParam];
        [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
        [self reciveMessage:9];
        
        strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 2,\"param\" : \"on\",\"token\" : %d,\"type\" :\"stream_while_record\"}",nParam];
        [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
        data = nil;
        [self reciveMessage:2];
        strInfo = nil;
        
        //6
        strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 259,\"param\" : \"none_force\",\"token\" : %d}",nParam];
        data = [NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length];
        [self sendMessage:data];
        data = nil;
        [self reciveMessage:259];
        strInfo = nil;
        return YES;
    }
    return NO;
}


-(int)XzlConnect
{
    if([self connect:kXCarAddress port:kXCarPort])
    {
        return 1;
    }
    return 0;
}

-(BOOL)downloadFile:(NSString*)strName
{
    NSString *strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 1285,\"token\" : %d,\"fetch_size\":0,\"offset\":0,\"param\":\"%s\"}",self.nParam,
                         [strName UTF8String]];
    
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    
    NSData *dataInfo = [self reciveMessage:1285];
    
    if (![self validateJson:dataInfo type:1285])
    {
         return NO;
    }
    return YES;
}

-(int)getDeviceStatus
{
    if (self.nParam==0)
    {
        if(![self XzlConnect])
        {
            DLog(@"连接失败");
            return 0;
        }
        
        if (![self startSession])
        {
            return 0;
        }
    }
    NSString *strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 1,\"token\" : %d,\"type\":\"app_status\"}",self.nParam];
    
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    
    NSData *appStatus = [self reciveMessage:1];
    
    while(![self validateJson:appStatus type:1])
    {
        DLog(@"重新获取一次");
        appStatus = [self reciveMessage:1];
    }
    
    NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:appStatus options:NSJSONReadingMutableLeaves error:nil];
    
    NSString *strStatus = [jsonData objectForKey:@"param"];
    if ([strStatus isEqualToString:@"idle"])
    {
        return 1;
    }
    else if([strStatus isEqualToString:@"vf"])
    {
        NSString *strMsg = [NSString stringWithFormat:@"{\"token\":%d, \"msg_id\": 260}",self.nParam];
        [self sendMessage:[NSData dataWithBytes:[strMsg UTF8String] length:strMsg.length]];
        [self reciveMessage:260];
        DLog(@"stop vf");
        return 1;
    }
    else
    {
        [self stopRecord];
    }
    return 1;
}

-(void)getDownDone
{
    [self reciveMessage:7];
}

-(BOOL)removeFromArray:(NSArray *)array
{
    if([self getDeviceStatus]==0)
    {
        return  NO;
    }
    for (RecordModel *record in array)
    {
        NSString *strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 1281,\"token\" : %d,\"param\":\"/tmp/fuse_d/DCIM/100MEDIA/%s\"}",
                             self.nParam,[record.strName UTF8String]];
        [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
        [self reciveMessage:1281];
        DLog(@"删除record:%@",record.strName);
    }
    return  YES;
}



-(BOOL)settingTimeInfo:(NSString *)strTime type:(int)nType
{
    if ([self getDeviceStatus] == 0)
    {
        return NO;
    }
    
    NSString *strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 2,\"param\" : \"%@\",\"token\" : %d,\"type\" : \"video_stamp\"}",
                         strTime,self.nParam];
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    NSData *dataInfo = [self reciveMessage:2];
    return [self validateJson:dataInfo type:2];
}

-(BOOL)validateJson:(NSData*)data type:(int)nType
{
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    if (error)
    {return  NO;}
    int nRval = [[dict objectForKey:@"rval"] intValue];
    int nMsgId = [[dict objectForKey:@"msg_id"] intValue];
    if (nRval == 0)
    {
        if (nMsgId==nType)
        {
            return YES;
        }
        else
        {
            return NO;
        }
        return YES;
    }
    return NO;
}

-(int)getFreeInfo
{
    if (self.nParam==0)
    {
        if (![self XzlConnect])
        {
            return 0;
        }
        [self startSession];
    }
    NSString *strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 5,\"token\" : %d,\"type\" : \"free\"}",self.nParam];
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    NSData *data = [self reciveMessage:5];
    if ([self validateJson:data type:5])
    {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        return [[dict objectForKey:@"param"] intValue];
    }
    return -1;
}

-(int)getTotalInfo
{
    if (self.nParam==0)
    {
        if (![self XzlConnect])
        {
            return 0;
        }
        [self startSession];
    }
    NSString *strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 5,\"token\" : %d,\"type\" : \"total\"}",self.nParam];
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    NSData *data = [self reciveMessage:5];
    if ([self validateJson:data type:5])
    {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
        return [[dict objectForKey:@"param"] intValue];
    }
    return -1;
}

-(int)getTimeSetting
{
    if ([self getDeviceStatus]==0)
    {
        return 0;
    }
//    NSString *strInfo = [NSString stringWithFormat:@""];
    return 1;
}

#pragma mark 停止录像
-(void)stopRecord
{
    NSString *strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 514 ,\"token\":%d}",self.nParam];
    
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    
    [self reciveMessage:514];
    
    self.nParam = 0;
}

-(void)stopSession
{
    NSString *strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 258 ,\"token\":%d}",self.nParam];
    
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    
    [self reciveMessage:258];
    
    self.nParam = 0;
    
}

-(void)closeSocket
{
    DLog(@"关闭");
    
    close(nSockfd);
    
    _nParam = 0;
}

-(NSString *)getStamp
{
    if (self.nParam==0)
    {
        if (![self XzlConnect])
        {
            return nil;
        }
        [self startSession];
    }
    
    NSString *strInfo = [NSString stringWithFormat:@"{\"msg_id\" : 1,\"token\" : %d,\"type\" : \"video_stamp\"}",self.nParam];
    
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    
    NSData *data = [self reciveMessage:1];
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:nil];
    NSString *strMsg=nil;
    if ((strMsg =[dict objectForKey:@"param"])!=nil)
    {
        return strMsg;
    }
    return nil;
}

-(BOOL)formatSdCard
{
    if ([self getDeviceStatus]==0) {
        return NO;
    }
    NSString *strInfo = [NSString stringWithFormat:@"{\"token\": %d, \"msg_id\": 4, \"param\":\"D:\"}",self.nParam];
    
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    
    NSData *data = [self reciveMessage:4];
    
    if (![self validateJson:data type:4])
    {
        return NO;
    }
    return YES;
}

-(NSString*)getResolution
{
    if (self.nParam==0)
    {
        if (![self XzlConnect])
        {
            return nil;
        }
        [self startSession];
    }
    NSString *strInfo = [NSString stringWithFormat:@"{\"token\": %d, \"msg_id\": 3}",self.nParam];
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    NSData *data = [self reciveMessage:3];
    if (![self validateJson:data type:3])
    {
        return nil;
    }
    NSError *error;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&error];
    if (error)
    {
        return nil;
    }
    NSArray *param = [dict objectForKey:@"param"];
    if (param!= nil)
    {
        for (NSDictionary *dict in param)
        {
            NSString *strValue = [dict objectForKey:@"video_resolution"];
            if (strValue!=nil)
            {
                return strValue;
            }
        }
    }
    return nil;
}

-(BOOL)setResolution:(NSString *)strResolution
{
    if ([self getDeviceStatus]==0)
    {
        return NO;
    }
    
    NSString *strInfo = [NSString stringWithFormat:@"{\"token\": %d, \"msg_id\": 2,\"type\":\"video_resolution\",\"param\":\"%@\"}",self.nParam,strResolution];
    
    [self sendMessage:[NSData dataWithBytes:[strInfo UTF8String] length:strInfo.length]];
    
    NSData *data = [self reciveMessage:2];
    
    if (![self validateJson:data type:2])
    {
        return NO;
    }
    return YES;
}

@end



















