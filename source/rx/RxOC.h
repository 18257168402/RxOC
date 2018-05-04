//
//  RxOC.h
//  guard
//
//  Created by 黎书胜 on 2017/10/27.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RxDefs.h"
#import "NSObject+Rx.h"
#import "NSNotificationCenter+Rx.h"

@interface RxOC<T> : NSObject
+(instancetype)create:(RxSource)source;
//RxDisposeSource返回的block将被传入RxDisposeSource的emitter强引用，使用时请注意循环引用问题
+(instancetype)createWithDispose:(RxDisposeSource)source;
/**
 * 创建一个RxOC,会以sec秒为周期，发送onNext count次，当count为0的时候，会一直发送
 * 直到调用了IRxSubscription的unSubcribe
 * 可以选择定时器是否是在主线程，如果不是主线程，那么会新建一个线程来进行定时器操作（多个定时器会使用同一个线程）
 *
 */
+(instancetype)interval:(NSTimeInterval)sec repeat:(int)count isMainThread:(BOOL)isMain;
+(instancetype)interval:(NSTimeInterval)sec repeat:(int)count isMainThread:(BOOL)isMain beginAtSubscribe:(BOOL)hot;
//RxSource block不可对传入参数id<IRxEmitter>形成强引用，否则会造成泄露，
//比如block对某变量x 强引用，而x又强引用了传入的id<IRxEmitter>参数，那么就形成block对id<IRxEmitter>的强引用了
//block块内直接使用id<IRxEmitter>是可以的，因为block块结束后对其引用就释放了，不会造成块对象对id<IRxEmitter>的强引用
@property (readonly) RxOpDoOnNext doOnNext;
@property (readonly) RxOpDoOnNext doAfterNext;
@property (readonly) RxOpDoOnError doOnError;
@property (readonly) RxOpDoOnError doAfterError;
@property (readonly) RxOpDoOnComplete doOnComplete;
@property (readonly) RxOpDoOnComplete doAfterComplete;

@property (readonly) RxOpDoOnSubscribe doOnSubscribe;

@property (readonly) RxOpMap map;//map操作生成的流的tag会覆盖上游的tag
@property (readonly) RxOpFlatMap flatmap;//flatMap操作生成的流的tag会覆盖 RxFlatTrans返回的流的tag但是不会覆盖上游的tag
@property (readonly) RxOpCompose compose;
//组合操作符,这个操作符主要应用于把多个相同操作应用到同一个流上面，比如.subscribeOn(SchdulerIO).observeOn(ScheduleMain)这种操作，可以统一处理
//如果在使用compose操作符的时候，你返回的RxOC与上游不一样,可能中间经过了多个操作符，而又需要用tag区分这些RxOC，那么请给这些新的RxOC设置单独的tag吉姆尼
@property (readonly) RxOnNext subcribe;
@property (readonly) RxOnTryError subcribeTryErr;
@property (readonly) RxOnTryTagError subcribeTryTagErr;
@property (readonly) RxOnTryLife subcribeTryLife;
@property (readonly) RxOnTryTagLife subcribeTryTagLife;

@property (readonly) RxOpOnErrResumeNext onErrorResumeNext;
//onErrorResumeNext 如果要设置tag请勿在RxOpOnErrResumeNext返回的RxOC中设置，而是在RxErrResume返回的RxOC中设置
@property (readonly) RxOpOnErrReturn onErrorReturn;
@property (readonly) RxOpOpRetry retry;
@property (readonly) RxOpOpRetryIf retryIf;
@property (readonly) RxOpOpRetryWhen retryWhen;
@property (readonly) RxOpZipWith zipWith;
@property (readonly) RxOpCombineLatest combineLatest;
@property (readonly) RxOpMergeWith mergeWith;
@property (readonly) RxOpMergeWithDelayError mergeWithDelayError;
@property (readonly) RxOpFilter filter;

@property (readonly) RxSetTag tag;//设置一个标签，如果subcribeTryTagErr来订阅，那么onError的时候会附加上发生错误的tag
@property (readonly) RxSetTag tagOveride;//覆盖标签，也就是rx链中此节点之前的错误，经过这个节点的时候都被覆盖

//当IRxSubscription调用unsubscribe的时候，onComplete onError等函数不会被回调，
//转而回调clean设置的函数
@property (readonly) RxOpClean clean;

@property (readonly) RxSchedule subcribeOn;
@property (readonly) RxSchedule observeOn;
@end
