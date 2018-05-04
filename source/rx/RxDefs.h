//
//  RxDefs.h
//  guard
//
//  Created by 黎书胜 on 2017/10/27.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#ifndef RxDefs_h
#define RxDefs_h
#import "RxOCCommonDefs.h"
typedef NS_ENUM(NSUInteger, ScheduleMode) {
    ScheduleOnCur = 1,
    ScheduleOnMain,
    ScheduleOnIO
};

@protocol IRxEmitter<NSObject>
-(void)onNext:(id)value;
-(void)onError:(NSException*)value;
-(void)onComplete;
@end


@protocol IRxSubscription
-(void)unsubscribe;
-(void)breakStream;
@end

@class RxOC;
typedef void(^ConsumerOnNext)(id value);
typedef void(^ConsumerOnError)(__kindof NSException* value);
typedef void(^ConsumerOnTagError)(__kindof NSException* value,int tag);
typedef void(^ConsumerOnComplete)(void);
//typedef void(^RxTag)(int tagid);
typedef void (^RxSource)(id<IRxEmitter> emitter);

typedef ConsumerOnComplete (^RxDisposeSource)(id<IRxEmitter> emitter);

typedef id (^RxTrans)(id from);
typedef RxOC* (^RxFlatTrans)(id from);
typedef RxOC* (^RxErrResume)(__kindof NSException* value);
typedef id (^RxErrReturn)(__kindof NSException* value);
typedef BOOL (^RxRetryIf)(int retryed,__kindof NSException* value);
typedef RxOC* (^RxRetryWhen)(int retryed,__kindof NSException* value);
typedef id (^RxZip)(id value1,id value2);
typedef __kindof NSException * (^RxMergeError)(__kindof NSException *err1,__kindof NSException *err2);
typedef BOOL (^RxFilter)(id value);

typedef void (^RxCleanOnComplete)(void);
typedef void (^RxCleanOnError)(__kindof NSException *e);

typedef void (^ComsumerOnSubscribe)(void);
typedef RxOC* (^RxComposeTrans)(RxOC* upstream);
typedef RxOC* (^RxOpMap)(RxTrans);
typedef RxOC* (^RxOpFlatMap)(RxFlatTrans);
typedef RxOC* (^RxOpCompose)(RxComposeTrans);
typedef RxOC* (^RxSchedule)(ScheduleMode );
typedef RxOC* (^RxOpDoOnNext)(ConsumerOnNext next);
typedef RxOC* (^RxOpDoOnError)(ConsumerOnError err);
typedef RxOC* (^RxOpDoOnComplete)(ConsumerOnComplete complete);

typedef RxOC* (^RxOpDoOnSubscribe)(ComsumerOnSubscribe comsumerOnSubscribe);
typedef RxOC* (^RxSetTag)(int tagid);

typedef RxOC* (^RxOpOnErrReturn)(RxErrReturn errReturn);//错误捕获，然后将返回值作为特殊的一项数据，通过onNext发送，然后调用onComplete结束
typedef RxOC* (^RxOpOnErrResumeNext)(RxErrResume resume);//错误捕获，然后切换到备用的RxOC继续发送,备用RxOC默认是在当前RxOC的发布线程启动
typedef RxOC* (^RxOpOpRetry)(int count);//当发生错误的时候，重新订阅
typedef RxOC* (^RxOpOpRetryIf)(RxRetryIf retryCondition);//当发生错误的时候，由RxRetryIf来决定是否重试，返回YES重试否则不重试
typedef RxOC* (^RxOpOpRetryWhen)(RxRetryWhen retryCondition);//当发生错误的时候，由RxRetryWhen决定何时重试，他返回一个RxOC*对象，将会在这个对象通知onNext的时候重试，onError转发错误
typedef RxOC* (^RxOpZipWith)(RxOC* rh,RxZip zipFunc);
//两个RxOC的结果，将会一对一的合并（也就是说，必须满足两个RxOC发送相同数量的数据，否则会导致其中一个数据永远阻塞不能发出）
// ,然后将这个结果传递给RxZip返回一个结果，然后把合并结果发出，如果其中任何一个RxOC发出onError，都立即断开连接
typedef RxOC* (^RxOpCombineLatest)(RxOC * rh,RxZip zipFunc);
//CombineLatest同样是合并操作，但是不同在于，任何一个RxOC的数据发出后，都会与另一个RxOC的最近的一个数据合并，然后发出
//也就是说，他不需要一一对应,只需要另一个RxOC有数据就行，他会就近选择数据（如果数据发出的时候另一个RxOC有数据，则直接合并这个数据，否则等另一个RxOC发出数据再立即合并）
typedef RxOC* (^RxOpSerialize)(void);
//当RxOC发送的数据来自不同线程，可能会让数据的发出的顺序混乱，这个操作符用来加锁数据的发出，以保证数据序列的先后顺序

typedef RxOC* (^RxOpMergeWith)(RxOC* rh);//将两个RxOC的结果统一发送给订阅者，要求两个订阅者的结果类型是一致的，其中任何一个RxOC发出onError，都断开连接
typedef RxOC* (^RxOpMergeWithDelayError)(RxOC* rh,RxMergeError mergeError);
//将两个RxOC的结果统一发送给订阅者，要求两个订阅者的结果类型是一致的，其中任何一个RxOC发出onError，都会等待另一个RxOC结束，然后通过RxMergeError合并错误
//当然可能只有其中一个出现了错误另一个没出现，这个时候传递给RxMergeError的参数，有一个是nil，以此判断谁成功谁失败
typedef RxOC* (^RxOpFilter)(RxFilter filter);//发出的数据需要filter返回true才能进入onNext,否则丢弃

//当IRxSubscription调用unsubscribe的时候，onComplete onError等函数不会被回调，
//转而回调clean设置的函数
typedef RxOC* (^RxOpClean)(RxCleanOnComplete cleanOnComplete,RxCleanOnError cleanOnError);


typedef id<IRxSubscription> (^RxOnNext)(ConsumerOnNext next);
typedef id<IRxSubscription> (^RxOnTryError)(ConsumerOnNext next,ConsumerOnError error);
typedef id<IRxSubscription> (^RxOnTryTagError)(ConsumerOnNext next,ConsumerOnTagError error);
typedef id<IRxSubscription> (^RxOnTryLife)(ConsumerOnNext next,ConsumerOnError error,ConsumerOnComplete complete);
typedef id<IRxSubscription> (^RxOnTryTagLife)(ConsumerOnNext next,ConsumerOnTagError error,ConsumerOnComplete complete);

#endif /* RxDefs_h */
