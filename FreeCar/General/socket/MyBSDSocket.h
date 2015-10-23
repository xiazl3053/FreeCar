#import <Foundation/Foundation.h>
#import <CoreFoundation/CFData.h>
#import <CoreFoundation/CFBase.h>
#define XTE_LOGIN_PLAT_IPERROR       999
#define XTE_LOGIN_PLAT_USERERROR      997
#define XTE_LOGIN_PLAT_DATAERROR      998
#define XTE_LOGIN_SERVERERROR          996
#define XTE_LOGIN_ANALYSIS               995
@interface MyBSDSocket : NSObject
{

}
@property (nonatomic,assign) int nParam;
DEFINE_SINGLETON_FOR_HEADER(MyBSDSocket);

/*建立socket连接*/
-(int)sendMessage:(NSData*)dataInfo;

-(int)connect:(const char *)ip port:(int)nPort;

-(BOOL)startSession;
-(BOOL)connectMedia;
-(int)XzlConnect;


-(NSData*)getComRecordInfo;

-(NSData*)getAlarmRecordInfo;

-(BOOL)downloadFile:(NSString*)strName;

-(void)getDownDone;

-(BOOL)removeFromArray:(NSArray *)array type:(int)nType;

-(BOOL)settingTimeInfo:(NSString *)strTime type:(int)nType;

-(void)stopSession;

-(int)getTimeSetting;

-(int)getTotalInfo;

-(int)getFreeInfo;

-(void)closeSocket;

-(BOOL)stopRecord;

-(NSString *)getStamp;

-(BOOL)formatSdCard;

-(NSString*)getResolution;

-(BOOL)setResolution:(NSString *)strResolution;

-(BOOL)setClock:(NSDate *)time;

- (NSString *)getTimeInfo;

@end
