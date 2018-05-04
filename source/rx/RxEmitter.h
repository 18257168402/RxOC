//
// Created by 黎书胜 on 2017/11/24.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RxDefs.h"
#import "RxWeakWrapper.h"
@class RxRuntime;
@protocol EmitterComposite<IRxEmitter>
-(id<EmitterComposite>) getNextEmitter;
-(RxRuntime*) getRx;
@end
@interface RxWeakOCEmitterProxy:NSObject<EmitterComposite>
{
@public
    id<EmitterComposite> _emitter;
    __weak RxRuntime* _runtime;
}
-(instancetype)initWithEmitter:(id<EmitterComposite>)emitter rx:(RxRuntime*)oc;
@end

@interface RxStrongOCEmitterProxy:NSObject<EmitterComposite>
{
@public
    id<EmitterComposite> _emitter;
    RxRuntime* _rxRuntime;
}
-(instancetype)initWithEmitter:(id<EmitterComposite>)emitter rx:(RxRuntime*)oc;
@end

@interface RxWeakOCAndEmitterProxy:NSObject<EmitterComposite>
{
@public
    __weak id<EmitterComposite> _emitter;
    __weak RxRuntime* _runtime;
}
-(instancetype)initWithEmitter:(id<EmitterComposite>)emitter rx:(RxRuntime*)oc;
@end

@interface RxEmitter:RxWeakOCEmitterProxy
{
    ConsumerOnNext _onNext;
    ConsumerOnError _onError;
    ConsumerOnComplete _onComplete;
    BOOL _isOver;
//    ConsumerOnNext _onBeforeNext;
//    ConsumerOnNext _onAfterNext;
//    ConsumerOnError _onBeforeError;
//    ConsumerOnError _onAfterError;
}
-(id)initWithConsumer:(ConsumerOnNext)next error:(ConsumerOnError)e complete:(ConsumerOnComplete)complete rx:(RxRuntime*)rx;
@end


@interface RxErrResumeEmitter:RxWeakOCEmitterProxy
@end
@interface RxErrReturnEmitter:RxWeakOCEmitterProxy
@end
@interface RxErrRetryEmitter:RxWeakOCEmitterProxy
@end
@interface RxErrRetryIfEmitter:RxErrRetryEmitter
@end
@interface RxErrRetryWhenEmitter:RxErrRetryEmitter
@end
@interface RxFilterEmitter:RxWeakOCEmitterProxy
@end

@class RxScheduleEmitter;

@protocol OnScheduleBeCancled<NSObject>
-(void)onCanceled:(RxScheduleEmitter*)emit;
@end
@class RxSourceEmitter;
@interface RxScheduleEmitter:RxWeakOCEmitterProxy//这里负责订阅者的线程调度
{
    ScheduleMode _mode;
    BOOL _cancelled;
}
@property (weak, nonatomic) RxSourceEmitter* sourceEmitter;
@property (weak, nonatomic) id<OnScheduleBeCancled> onCancelListener;
@property (assign,atomic) BOOL cancelled;
-(instancetype)initWithSchedule:(ScheduleMode)mode emitter:(id<EmitterComposite>)emit rx:(RxRuntime *)rx;
@end

@interface RxSourceEmitter:RxStrongOCEmitterProxy
@property (strong, nonatomic) RxRuntime *runtime;
@property (strong, nonatomic) RxOC *rx;
-(void)cancelUpstreams;
-(void)addUpStream:(RxSourceEmitter *)up;
@property (assign, nonatomic) int tagId;
@property (strong, nonatomic) RxSourceEmitter* downStreamEmitterChain;
@property (strong, nonatomic) NSMutableArray<RxWeakWrapper*> * upStreams;//下游的RxSourceEmitter列表，注意这里都是弱引用
@end


/**
 * RxTransEmitter用于某些操作符需要为当前RxOC设置一个下游RxOC的时候，
 * 这个时候在下游的 emitter链的头部插入此emitter
 * 这个emitter主要的作用是，把RxTransEmitter产生的下游RxOC上设置的tagId,
 * 覆盖上游的tagId,
 * 考虑到场景是，上游的RxOC产生可能来自一个其他模块，因此他的tag是未知的
 * 比如
 * [manager getDbData]
 * .map(^(id from){
 *  return to;
 * })
 * 或者
 * [manager getDbData]
 * .flatmap(^(id from){
 *      return [manager getNetData];
 * })
 * 这个时候要分辨产生错误的时候，具体是哪个RxOC,并不需要具体到[manager getDbData]
 * 或者[manager getNetData]所返回的RxOC，只需要在map或者flatmap后返回的下游上设置tag
 * 然后发生错误的时候覆盖上游就好了
 *
 */
@interface RxTransEmitter:RxWeakOCAndEmitterProxy
@end