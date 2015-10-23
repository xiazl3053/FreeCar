//
//  RecordDBService.h
//  FreeCar
//
//  Created by xiongchi on 15/8/4.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RecordModel.h"

@interface RecordDBService : NSObject

+(BOOL)addRecording:(RecordModel *)record;

+(NSArray*)queryAllRecord;

+(BOOL)removeArray:(NSArray *)array;

+(BOOL)queryRecordByName:(NSString *)strName;

@end
