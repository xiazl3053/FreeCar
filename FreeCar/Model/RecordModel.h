//
//  RecordModel.h
//  FreeCar
//
//  Created by xiongchi on 15/8/1.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecordModel : NSObject

-(id)initWithArray:(NSArray *)ary;

-(id)initWithItem:(NSDictionary *)item;

@property (nonatomic,assign) int nAll;
@property (nonatomic,assign) NSInteger nId;
@property (nonatomic,copy) NSString *strImg;
@property (nonatomic,copy) NSString *strDate;
@property (nonatomic,copy) NSString *strSize;
@property (nonatomic,copy) NSString *strName;
@property (nonatomic,assign) int nType;


@end
