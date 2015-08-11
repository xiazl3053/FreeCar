//
//  RecordModel.m
//  FreeCar
//
//  Created by xiongchi on 15/8/1.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "RecordModel.h"


@implementation RecordModel


-(id)initWithArray:(NSArray *)ary
{
    self = [super init];
    _strName = ary[0];
    _strDate = ary[1];
    _nAll = [ary[2] intValue];
    _strSize = [NSString stringWithFormat:@"%.02f MB",(float)_nAll/(1024*1024)];
    return  self;
}

-(id)initWithItem:(NSDictionary *)item
{
    self = [super init];
    char cFilePath[32];
    int nSize;
    char cTime[50];
    memset(cFilePath, 0, 32);
    memset(cTime, 0, 50);
//    DLog(@"item:%@",item);
    _strName = item.allKeys[0];
    
    sscanf([item.allValues[0] UTF8String],"%d bytes|%s",&nSize,cTime);
    _nAll = nSize;
    _strSize = [NSString stringWithFormat:@"%.02f MB",(float)nSize/(1024*1024)];
    _strDate = [NSString stringWithFormat:@"%s",cTime];
    
    return self;
}



@end
