//
//  RecordDBService.m
//  FreeCar
//
//  Created by xiongchi on 15/8/4.
//  Copyright (c) 2015年 xiongchi. All rights reserved.
//

#import "RecordDBService.h"
#import "FMDatabase.h"
#import "RecordModel.h"
#import "FMResultSet.h"

#define kDataLoginPath [kDocumentPath stringByAppendingPathComponent:@"xc.db"]

@implementation RecordDBService

+(FMDatabase *)initDatabaseUser
{
    FMDatabase *db= [FMDatabase databaseWithPath:kDataLoginPath];
    if(![db open])
    {
        DLog(@"open fail");
    }
    [db executeUpdate:@"CREATE TABLE IF NOT EXISTS recording (id integer primary key asc autoincrement, filename text unique,size integer,startTime timestamp)"];
    return db;
}

+(BOOL)addRecording:(RecordModel *)record
{
    NSString *strSql = @"insert or replace into recording (filename,size,startTime) values (?,?,?)";
    FMDatabase *db = [RecordDBService initDatabaseUser];
    [db beginTransaction];
    BOOL bReturn = [db executeUpdate:strSql,record.strName,[NSNumber numberWithInt:record.nAll],record.strDate];
    [db commit];
    [db close];
    return bReturn ;
}

+(NSArray*)queryAllRecord
{
    NSMutableArray *array = [NSMutableArray array];
    
    NSString *strSql =@"select * from recording";
    
    FMDatabase *db = [RecordDBService initDatabaseUser];
    
    FMResultSet *rs = [db executeQuery:strSql];
    
    while (rs.next)
    {
        NSArray *temp  =[[NSArray alloc] initWithObjects:[rs stringForColumn:@"filename"],
                         [rs stringForColumn:@"startTime"],[rs stringForColumn:@"size"], nil];
        RecordModel *record = [[RecordModel alloc] initWithArray:temp];
        [array addObject:record];
    }
    
    return array;
}

+(BOOL)removeArray:(NSArray *)array
{
    FMDatabase *db = [RecordDBService initDatabaseUser];
    for (RecordModel *record in array)
    {
        NSString *strInfo = @"delete from recording where filename = ?";
        [db beginTransaction];
        [db executeUpdate:strInfo,record.strName];
        [db commit];
        NSString *strFile = [NSString stringWithFormat:@"%@/record/%@",kLibraryPath,record.strName];
        [[NSFileManager defaultManager] removeItemAtPath:strFile error:nil];
    }
    return YES;
}

@end
