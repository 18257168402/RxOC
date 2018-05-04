//
// Created by 黎书胜 on 2017/11/30.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RxDefs.h"
#import "RxInnerDefs.h"
@class RxSourceEmitter;
@class RxScheduleEmitter;

@interface RxRuntime : NSObject

-(instancetype)initWithRx:(RxOC *)rx;

@property (weak, nonatomic)    RxOC *rx;

@property (assign, nonatomic)  int tagId;
@property (assign, nonatomic)  int tagOverideId;
@property (assign, nonatomic)  int retryCount;
@property (strong, nonatomic)  NSMutableArray<RxCleanOnComplete>* cleanOnComplete;
@property (strong, nonatomic)  NSMutableArray<RxCleanOnError>*    cleanOnError;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnNext>*    consumerBeforeOnNext;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnNext>*    consumerAfterOnNext;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnError>*   consumerBeforeOnError;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnError>*   consumerAfterOnError;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnComplete>*   consumerBeforeOnComplete;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnComplete>*   consumerAfterOnComplete;
@property (strong, nonatomic)  NSMutableArray<ComsumerOnSubscribe>*  consumerOnSubscribe;

@property (assign, nonatomic)  ScheduleMode sourceMode;
@property (assign, nonatomic)  ScheduleMode dstMode;
@property (strong, nonatomic)  RxErrResume rxErrResume;
@property (strong, nonatomic)  RxErrReturn rxErrReturn;
@property (strong, nonatomic)  RxRetryIf rxRetryIf;
@property (strong, nonatomic)  RxRetryWhen rxRetryWhen;
@property (strong, nonatomic)  RxFilter rxFilter;

@property (assign, nonatomic)  int retryedCount;//已经尝试次数

@property (assign, nonatomic) int mergeErrorCount;
@property (assign, nonatomic) int mergeCompleteCount;
@property (strong, nonatomic) NSException *mergeUpError;
@property (strong, nonatomic) NSException *mergeRhError;

@property (weak,   nonatomic)  RxSourceEmitter* sourceEmitter;
@property (weak,   nonatomic)  RxScheduleEmitter* schedulerEmitter;

@property (strong, nonatomic)  NSMutableDictionary *runtimeObjects;//运行时变量

@property (weak, nonatomic) RxRuntime *rootRuntime;
//@property (strong, nonatomic) NSString *rxPath;
//-(void)appendRxPath:(NSString *)path;

-(void)addRuntimeObject:(NSString *)key obj:(id)obj;//给一个变量加上强引用，运行结束将释放引用
//添加的变量千万不要引用RxOC框架中的其他对象
-(id)getRuntimeObject:(NSString *)key;
@end