//
//  DTLog.m
//  VisualSymbolicateCrash
//
//  Created by ximiao on 15/6/21.
//  Copyright (c) 2015年 ximiao. All rights reserved.
//

#import "DTLog.h"
#include <pthread.h>
@import Dispatch;

@protocol DTLogProtocol <NSObject>
-(id)log:(NSString *)text;
@end

@interface DTCommandLineLog : NSObject<DTLogProtocol>
-(void)log:(NSString*)text;
@end

#define WriteToFileCount 50 //每50条log写一次文件

@interface DTFileLog : NSObject<DTLogProtocol>
@property(nonatomic, strong)NSMutableArray *array;
@property(nonatomic, strong)NSFileHandle *file;
@property(nonatomic, strong)NSThread *thread;
@property(nonatomic)BOOL keepRun;
@property(nonatomic, strong)NSLock *lock;
-(void)log:(NSString*)text;
@end



@implementation DTLog {
    NSMutableArray *_logEntrtys;
    NSDictionary *_levelStrDic;
}
+(DTLog*)sharedInstance {
    static DTLog *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DTLog alloc] initWithType:LogType_CommandLineAndFile];
    });
    return instance;
}
-(id)initWithType:(LogType)type {
    self = [super init];
    _type = type;
    _outPutLevel = LogLevel_All;
    _logEntrtys = [[NSMutableArray alloc] init];
    _levelStrDic = [NSDictionary dictionaryWithObjectsAndKeys:
                    @"OFF", [NSNumber numberWithInteger:LogLevel_Off],
                    @"FATAL", [NSNumber numberWithInteger:LogLevel_Fatal],
                    @"ERROR", [NSNumber numberWithInteger:LogLevel_Error],
                    @"INFO", [NSNumber numberWithInteger:LogLevel_Info],
                    @"DEBUG", [NSNumber numberWithInteger:LogLevel_Debug],
                    @"TRACE", [NSNumber numberWithInteger:LogLevel_Trace],
                    @"ALL", [NSNumber numberWithInteger:LogLevel_All],
                    nil];
    switch (type) {
        case LogType_CommandLine:
            [_logEntrtys addObject:[[DTCommandLineLog alloc] init]];
            break;
        case LogType_CommandLineAndFile:
            [_logEntrtys addObject:[[DTCommandLineLog alloc] init]];
            [_logEntrtys addObject:[[DTFileLog alloc] init]];
            break;
        case LogType_File:
            [_logEntrtys addObject:[[DTFileLog alloc] init]];
            break;
        case LogType_None:
            break;
        default:
            assert(false && @"不支持的logType");
            break;
    }
    return self;
}
-(NSString*)getRealOutput:(LogLevel)level Text:(NSString*)text {
    NSString *strLevel = [_levelStrDic objectForKey:[NSNumber numberWithInteger:level]];
    NSString *str = [NSString stringWithFormat:@"%@|%@\r\n",
                     strLevel,
                     text];
    return str;
}
-(void)log:(LogLevel)level Text:(NSString *)text {
    if (level <= self.outPutLevel) {
        NSString *outPut = [self getRealOutput:level Text:text];
        for (id<DTLogProtocol> logEntrty in _logEntrtys) {
             [logEntrty log:outPut];
        }
       
    }
}
-(void)log:(LogLevel)level Text:(NSString *)text File:(NSString*)file Line:(NSInteger)line Function:(NSString*)fun Thread:(NSThread*)thread Time:(NSDate*)time {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    //[dateFormatter setDateStyle:kCFDateFormatterFullStyle];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss.SSS"];
    NSString *str = [NSString stringWithFormat:@"%@|%@|File:%@:%ld|Function:%@|%@",
                     [dateFormatter stringFromDate:time],
                     thread,
                     file,
                     line,
                     fun,
                     text];
    [self log:level Text:str];
}
@end

@implementation DTFileLog {
    dispatch_semaphore_t _semaphore;

}
-(id)init {
    self = [super init];
    _array = [[NSMutableArray alloc] init];
#if TARGET_OS_IPHONE
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
#else
    NSString *path = [[NSBundle mainBundle] bundlePath];
#endif
    NSString *logFilePath = [NSString stringWithFormat:@"%@/%@", path, @"WeiboMovie.log"];
    _file = [NSFileHandle fileHandleForUpdatingAtPath:logFilePath];
    if (!_file) {
        [[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
        _file = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(callToStop) name:@"applicationWillTerminate" object:nil];
    _semaphore = dispatch_semaphore_create(0);
    _lock = [[NSLock alloc] init];
    _thread = [[NSThread alloc] initWithTarget:self selector:@selector(writeToFileThread) object:nil];
    [_thread start];
    return self;
}
//写文件的线程
-(void)writeToFileThread {
    _keepRun = YES;
    NSArray *logs;
    while (_keepRun) {
        long ret = dispatch_semaphore_wait(_semaphore, dispatch_time(DISPATCH_TIME_NOW, 3*NSEC_PER_SEC));
        if (self.array.count >= WriteToFileCount) {
            [self.lock lock];
            logs = [self.array copy];
            [self.array removeAllObjects];
            [self.lock unlock];
            [self writeToFile:logs];
        }
    }
    [self.lock lock];
    [self writeToFile:self.array];
    [self.lock unlock];
}
//批量写文件
-(void)writeToFile:(NSArray*)array {
    NSMutableString *allStr = [[NSMutableString alloc] init];
    for (NSString*str in self.array) {
        [allStr appendString:str];
    }
    [_file writeData:[allStr dataUsingEncoding:NSUTF8StringEncoding]];
}
-(void)callToStop {
    _keepRun = NO;
    dispatch_semaphore_signal(_semaphore);
}
-(void)dealloc {
    [_file closeFile];
}
-(void)log:(NSString*)text {
    //if (_keepRun) {
        [self.lock lock];
        [self.array addObject:text];
        [self.lock unlock];
    //}
    //[_file writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
}
@end
@implementation DTCommandLineLog
-(void)log:(NSString*)text {
    printf([text cStringUsingEncoding:NSUTF8StringEncoding]);
}
@end
