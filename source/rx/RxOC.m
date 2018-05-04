//
//  RxOC.m
//  guard
//
//  Created by 黎书胜 on 2017/10/27.
//  Copyright © 2017年 黎书胜. All rights reserved.
//
#import "RxEmitter.h"
#import "RxInnerDefs.h"
#import "RxSubcription.h"
#import "RxEventSource.h"
#import "RxOCTransform.h"
#import "RxRuntime.h"

/*------------------------------------------*/

@implementation RxOC
-(id)init{
    self = [super init];
    self.retryCount = 0;
    RxLogT(RXTAG,@"RxOC init%@",self);
    return self;
}
-(void)dealloc{
    RxLogT(RXTAG,@"RxOC dealloc:%@ name:%@",self,self.name);
}
+(instancetype)interval:(NSTimeInterval)sec repeat:(int)count isMainThread:(BOOL)isMain{
    return [self interval:sec repeat:count isMainThread:isMain beginAtSubscribe:NO];
}
+(instancetype)interval:(NSTimeInterval)sec repeat:(int)count isMainThread:(BOOL)isMain beginAtSubscribe:(BOOL)hot{
    RxIntervalTimerTransform* timerTransform = [[RxIntervalTimerTransform alloc] init];
    timerTransform.sec =sec;
    timerTransform.repeat = count;
    timerTransform.isMain = isMain;
    timerTransform.isHot = hot;
    RxOC *rx = [self createWithUpstream:timerTransform];
    rx.name = @"interval";
    return rx;
}
+(instancetype)create:(RxSource)src
{
    RxOC* oc = [RxOC new];
    oc.tagId = 0;
    oc.tagOverideId = 0;
    oc.source = [[RxEventSource alloc] initWithRx:oc source:src];
    oc->_sourceMode = ScheduleOnCur;
    oc->_dstMode = ScheduleOnCur;
    oc.name = @"origin";
    return oc;
}
//RxDisposeSource返回的block将被传入RxDisposeSource的emitter强引用，使用时请注意循环引用问题
+(instancetype)createWithDispose:(RxDisposeSource)source{
    RxOC* oc = [RxOC new];
    oc.tagId = 0;
    oc.tagOverideId = 0;
    oc.source = [[RxDisposeEventSource alloc] initWithRx:oc source:source];
    oc->_sourceMode = ScheduleOnCur;
    oc->_dstMode = ScheduleOnCur;
    oc.name = @"origin";
    return oc;
}

+(instancetype)createWithUpstream:(RxOCTransform *)transform{
    RxOC* oc = [RxOC new];
    oc.tagId = 0;
    oc.tagOverideId = 0;
    transform.rx = oc;
    oc.source = [[RxTransFormSource alloc] initWithRx:oc trans:transform];
    oc->_sourceMode = ScheduleOnCur;
    oc->_dstMode = ScheduleOnCur;
    oc.name = @"transform";
    return oc;
}
-(RxOC *)lift{
    RxOCTransform *transform = [[RxOCTransform alloc] init];
    transform.up = self;
    RxOC *opOC = [RxOC createWithUpstream:transform];
    return opOC;
}
-(RxOpDoOnComplete)doAfterComplete{
    RxOpDoOnComplete op = ^(ConsumerOnComplete onComp){
        @synchronized (self) {
            RxOC *opOC = [self lift];
            opOC.name = @"doAfterComplete";
            if(opOC.consumerAfterOnComplete==nil){
                opOC.consumerAfterOnComplete = [NSMutableArray new];
            }
            [opOC.consumerAfterOnComplete addObject:onComp];
            return opOC;
        }
    };
    return op;
}
-(RxOpDoOnComplete)doOnComplete{
    RxOpDoOnComplete op = ^(ConsumerOnComplete onComp){
        @synchronized (self) {
            RxOC *opOC = [self lift];
            opOC.name = @"doOnComplete";
            if(opOC.consumerBeforeOnComplete==nil){
                opOC.consumerBeforeOnComplete = [NSMutableArray new];
            }
            [opOC.consumerBeforeOnComplete addObject:onComp];
            return opOC;
        }
    };
    return op;
}
-(RxOpDoOnError)doOnError{
    RxOpDoOnError op = ^(ConsumerOnError onErr){
        @synchronized (self) {
            RxOC *opOC = [self lift];
            opOC.name = @"doOnError";
            if(opOC.consumerBeforeOnError==nil){
                opOC.consumerBeforeOnError = [NSMutableArray new];
            }
            [opOC.consumerBeforeOnError addObject:onErr];
            return opOC;
        }
    };
    return op;
}
-(RxOpDoOnSubscribe)doOnSubscribe {
    RxOpDoOnSubscribe op = ^(ComsumerOnSubscribe onSub){
        @synchronized (self) {
            RxOC *opOC = [self lift];
            opOC.name = @"doOnSubscribe";
            if(opOC.consumerOnSubscribe==nil){
                opOC.consumerOnSubscribe = [NSMutableArray new];
            }
            [opOC.consumerOnSubscribe addObject:onSub];
            return opOC;
        }
    };
    return op;
}
-(RxOpDoOnError)doAfterError{
    RxOpDoOnError op = ^(ConsumerOnError onErr){
        @synchronized (self) {
            RxOC *opOC = [self lift];
            opOC.name = @"doAfterError";
            if(opOC.consumerAfterOnError==nil){
                opOC.consumerAfterOnError = [NSMutableArray new];
            }
            [opOC.consumerAfterOnError addObject:onErr];
            return opOC;
        }
    };
    return op;
}

-(RxOpDoOnNext)doOnNext{
    RxOpDoOnNext op = ^(ConsumerOnNext onNext){
        @synchronized (self) {
            RxOC *opOC = [self lift];
            opOC.name =@"doOnNext";
            if(opOC.consumerBeforeOnNext==nil){
                opOC.consumerBeforeOnNext = [NSMutableArray new];
            }
            [opOC.consumerBeforeOnNext addObject:onNext];
            return opOC;
        }
    };
    return op;
}
-(RxOpDoOnNext)doAfterNext{
    RxOpDoOnNext op = ^(ConsumerOnNext onNext){
        @synchronized (self) {
            RxOC *opOC = [self lift];
            opOC.name =@"doAfterNext";
            if(opOC.consumerAfterOnNext==nil){
                opOC.consumerAfterOnNext = [NSMutableArray new];
            }
            [opOC.consumerAfterOnNext addObject:onNext];
            return opOC;
        }
    };
    return op;
}

-(RxOpOnErrResumeNext) onErrorResumeNext{
    RxOpOnErrResumeNext op = ^(RxErrResume resume){
        RxOC *opOC = [self lift];
        opOC.name = @"onErrorResumeNext";
        opOC.rxErrResume = resume;
        opOC.rxErrReturn = nil;
        return opOC;
    };
    return op;
};
-(RxOpOnErrReturn)onErrorReturn{
    RxOpOnErrReturn op = ^(RxErrReturn errReturn){
        RxOC *opOC = [self lift];
        opOC.name = @"onErrorReturn";
        opOC.rxErrResume = nil;
        opOC.rxErrReturn = errReturn;
        return opOC;
    };
    return op;
}
-(RxOpOpRetry)retry{
    RxOpOpRetry op = ^(int count){
        RxOC *opOC = [self lift];
        opOC.name = @"retry";
        opOC.retryCount = count;
        return opOC;
    };
    return op;
}
-(RxOpOpRetryIf)retryIf{
    RxOpOpRetryIf op = ^(RxRetryIf retryIf){
        RxOC *opOC = [self lift];
        opOC.name = @"retryIf";
        opOC.rxRetryIf = retryIf;
        opOC.rxRetryWhen = nil;
        opOC.retryCount = 0;
        return opOC;
    };
    return op;
}
-(RxOpOpRetryWhen)retryWhen {
    RxOpOpRetryWhen op = ^(RxRetryWhen retryWhen){
        RxOC *opOC = [self lift];
        opOC.name = @"retryWhen";
        opOC.rxRetryWhen = retryWhen;
        opOC.rxRetryIf = nil;
        opOC.retryCount = 0;
        return opOC;
    };
    return op;
}
-(RxOpFilter)filter{
    RxOpFilter op =^(RxFilter filter){
        RxOC *opOC = [self lift];
        opOC.name = @"filter";
        opOC.rxFilter = filter;
        return opOC;
    };
    return op;
};
-(RxOpCompose)compose{
    RxOpCompose op = ^(RxComposeTrans trans){
        RxOC* opRC = nil;
        @try{
            opRC = trans(self);
        }@catch(NSException* e){
            NSLog(@"compose accour exception:%@",e.description);
        }
        return opRC;
    };
    return op;
}

//
-(RxOpMap)map{
    RxOC* oc = self;
    RxOpMap op = ^(RxTrans trans){
        RxMapOCTransform *mapTransform = [[RxMapOCTransform alloc] init];
        mapTransform.up = oc;
        mapTransform.trans = trans;
        RxOC *opOC = [RxOC createWithUpstream:mapTransform];
        opOC.name=@"map";
        return opOC;
    };
    return op;
}

-(RxOpFlatMap) flatmap{
    RxOC* oc = self;
    RxOpFlatMap op = ^(RxFlatTrans trans){
        RxFlatMapOCTransform *flatmapTransform = [[RxFlatMapOCTransform alloc] init];
        flatmapTransform.up = oc;
        flatmapTransform.trans = trans;
        RxOC *opOC = [RxOC createWithUpstream:flatmapTransform];
        opOC.name=@"flatmap";
        return opOC;
    };
    return op;
}
-(RxOpZipWith)zipWith{
    RxOC* oc = self;
    RxOpZipWith op = ^(RxOC* rh,RxZip zipFunc){
        RxZipTransform* zipTransform = [[RxZipTransform alloc] init];
        zipTransform.up = oc;
        zipTransform.zipFunc = zipFunc;
        zipTransform.rh = rh;
        rh.name = @"zipWith.rh";
        RxOC *opOC = [RxOC createWithUpstream:zipTransform];
        opOC.name=@"zipWith";
        return opOC;
    };
    return op;
}
-(RxOpCombineLatest)combineLatest{
    RxOC * oc = self;
    RxOpCombineLatest op = ^(RxOC * rh,RxZip zipFunc){
        RxCombineLastTransform* combineTransform = [[RxCombineLastTransform alloc] init];
        combineTransform.up = oc;
        combineTransform.zipFunc = zipFunc;
        combineTransform.rh = rh;
        rh.name = @"combineLatest.rh";
        RxOC *opOC = [RxOC createWithUpstream:combineTransform];
        opOC.name=@"combineLatest";
        return opOC;
    };
    return op;
};
-(RxOpMergeWith)mergeWith{
    RxOC * oc = self;
    RxOpMergeWith op = ^(RxOC* rh){
        RxMergeTransform* mergeTransform = [[RxMergeTransform alloc] init];
        mergeTransform.up = oc;
        mergeTransform.rh = rh;
        rh.name = @"mergeWith.rh";
        RxOC *opOC = [RxOC createWithUpstream:mergeTransform];
        opOC.name=@"mergeWith";
        return opOC;
    };
    return op;
}
-(RxOpMergeWithDelayError)mergeWithDelayError{
    RxOC * oc = self;
    RxOpMergeWithDelayError op = ^(RxOC* rh,RxMergeError mergeError){
        RxMergeWithDelayErrorTransform* mergeTransform = [[RxMergeWithDelayErrorTransform alloc] init];
        mergeTransform.up = oc;
        mergeTransform.rh = rh;
        rh.name = @"mergeWithDelayError.rh";
        mergeTransform.mergeFunc = mergeError;
        RxOC *opOC = [RxOC createWithUpstream:mergeTransform];
        opOC.name=@"mergeWithDelayError";
        return opOC;
    };
    return op;
}
-(RxOnNext)subcribe{
    return ^(ConsumerOnNext next){
       return [self __subcribe:next];
    };
}
-(RxSetTag)tag{
    return ^(int tagid){
        RxOC* oc = self;
        oc.tagId = tagid;
        return oc;
    };
}
-(RxSetTag)tagOveride{
    return ^(int tagid){
        RxOC* oc = self;
        oc.tagOverideId = tagid;
        return oc;
    };
}
-(RxOpClean)clean{
    return ^(RxCleanOnComplete comp,RxCleanOnError error){
        @synchronized (self) {
            RxOC *opOC = self;//[self lift];
            //opOC.name = @"clean";//clean不能lift，因为unsubscribe会断开up stream
            if(opOC.cleanOnComplete==nil){
                opOC.cleanOnComplete = [NSMutableArray new];
            }
            [opOC.cleanOnComplete addObject:comp];
            if(opOC.cleanOnError==nil){
                opOC.cleanOnError = [NSMutableArray new];
            }
            [opOC.cleanOnError addObject:error];
            return opOC;
        }
    };
}


-(RxOnTryError)subcribeTryErr{
    return ^(ConsumerOnNext next,ConsumerOnError error){
       return [self __subcribe:next error:error];
    };
}
-(RxOnTryTagError)subcribeTryTagErr{//这里是每个流的终点，_source发出的是起点
    return ^(ConsumerOnNext next,ConsumerOnTagError error){
        return [self __subcribe:next error:^(NSException* e){
            NSNumber* tagNum = [RxRunTimeUtil getExtraObj:e key:&key_of_tagid];
            int tagid = -1;
            if(tagNum!=nil){
                tagid = tagNum.intValue;
            }
            error(e,tagid);
        }];
    };
}
-(RxOnTryTagLife)subcribeTryTagLife{
    return ^(ConsumerOnNext next,ConsumerOnTagError error,ConsumerOnComplete com){
        return [self __subcribe:next error:^(NSException* e){
            NSNumber* tagNum = [RxRunTimeUtil getExtraObj:e key:&key_of_tagid];
            int tagid = -1;
            if(tagNum!=nil){
                tagid = tagNum.intValue;
            }
            error(e,tagid);
        } complete:com downEmitterChain:nil];
    };
}

-(RxOnTryLife)subcribeTryLife{
    return ^(ConsumerOnNext next,ConsumerOnError error,ConsumerOnComplete com){
       return [self __subcribe:next error:error complete:com downEmitterChain:nil];
    };
}
/**
 * 发布线程设置
 * @return df
 */
-(RxSchedule)subcribeOn{
    return ^(ScheduleMode mode){
        RxOC* oc = self;
        oc.sourceMode = mode;
        return oc;
    };
}
/**
 * 订阅线程设置
 * @return dfd
 */
-(RxSchedule)observeOn{
    return ^(ScheduleMode mode){
        RxOC* oc = self;
        oc.dstMode = mode;
        return oc;
    };
}

//typedef void (^RxSource)(RxEmitter* emitter);
-(id<IRxSubscription>)__subcribe:(ConsumerOnNext)next{
  return  [self __subcribe:next error:nil];
}
-(id<IRxSubscription>)__subcribe:(ConsumerOnNext)next error:(ConsumerOnError)err{
   return [self __subcribe:next error:err complete:nil downEmitterChain:nil];
}

/**
 
 +----+ sourceEmitter          scheduleEmitter     rxEmitter       +------+  sourceEmitter
 |  s |-------------------->----------------->-------------------> |   d  | --------------->......
 +----+  附加onError tagid       选择发送线程         发送给目标      +------+
 
 一个流 我们的定义是 s(事件源)加上 中间所有的emitter(发送器)
 s我们将他叫做 事件源(RxSrouce,也就是create函数传入的那个参数)，
 他负责产生事件，在上图总我们用
                         +----+
                         |    |
                         +----+ 表示，当然，他所在的线程，由__subcribe函数根据subscribeOn这个函数所设置的模式选择，
 
 事件源产生的事件有三种
 onNext,onError,onComplete
 每个事件源可以有多个onNext，但是只能有一个或0个onError,当所有的onNext事件产生完毕要发送一个onComplete事件
 那么典型的事件源写法如下
 {
     ---执行一些函数---
     if(执行成功){
         emitter.onNext(obj1);
         emitter.onNext(obj2);
         emitter.onNext(obj3);
         emitter.onNext(obj4);
         ......
         emitter.onComplete();
     }else{
         emitter.onError();
     }
 }
 这样，从上游的事件源s产生的事件，通过发送器emitter 就能发送到 下游 d
 
 发送器 是一个特殊的事件源，---【他不产生事件，他只转发事件】----
 在RxOC的实现中，我们总共用到的发送器有三种，当然后续还有可能会添加很多种
 RxSourceEmitter,他负责给事件源的onError事件加上tagid（当然后续为了代码结构更加明晰，这个功能可能放到另一个Emitter比如说TagEmitter中）
 RxScheduleEmitter,这个发送器负责为后续的发送器选择发送线程(这个线程当然后ObserveOn函数设置的模式决定)
 RxEmitter,这个发送器负责把事件发送到相应的目标 比如说下游设置的onNext onError onComplete，doOnNext,onAfterNext监听等
 
 在RxOC的实现中，发送器是一个链式的结构，从事件源产生的事件会交给这个 发送器链 进行处理后最终发送到下游 s
 
 一个发送器应当继承IEmitter函数，并且要本着不产生事件的原则，不产生任何额外的事件,只对这些事件进行相应的处理，然后转发
 添加一个IEmitter的位置很重要。请务必要注意，比如在scheduleEmitter前插入一个发送器，与在scheduleEmitter后插入，他所在的线程就有可能不一样
 
 
 每一个操作符，例如map flatMap等都会生成一个 流 ，这个新产生的流，会在上一个流(我们叫他 上游）的
 1 onNext事件发送到他这里的时候 开始触发，然后进行相应的处理，
 可能产生新的事件，在把这些事件发送给下游(flatMap),也可能仅仅把上游的onNext的结果值转换一下再发送给下游(map)。
 2 或者上游的onError 事件发送到他这里，一般操作符都不会对错误事件进行处理，而是直接发送给下游，
 这样当一个事件源产生错误之后，我们下游的事件源不会被触发，而是直接通过发送器把onError事件发送出去
 
 所以，用于标识流的tagId仅仅在onError中使用，用于标识这个错误的流
 
     +----+ RxSourceEmitter      RxScheduleEmitter     RxEmitter       +------+
.....|  d |-------------------->----------------->-------------------> |  d1  |
     +----+  附加onError tagid       选择发送线程         发送给目标      +------+
                                                                           |----RxSourceEmitter-...-->onNext-------->observer
                                                                           |----RxSourceEmitter-...-->onNext-------->observer
                                                                           ......
                                                                           |----RxSourceEmitter-...-->onError------->observer
                                                                           |----RxSourceEmitter-...-->onComplete---->observer
 当然中间的emitter可能还会有更多，我们叫他emitter链
 对于map或者flatmap产生的下游，下游的emitter链是这样的

 RxTransEmitter -> RxSourceEmitter -> RxScheduleEmitter -> RxEmitter
其中RxSourceEmitter持有对RxOC的强引用，其他的emitter如果需要引用RxOC，只需要弱引用

 经过map过后的上下游关系

   down -> RxTransformSouce -> RxMapOCTransform -> up ->RxEventSource->RxSource
    ^ ^          |                    |   |  ^       ^        |
    | |          |                    |   |  |       |         ->RxScheduleEmitter->RxEmitter->ConsumerOnNext
    | |           ->RxScheduleEmitter |   |  |       |                   ^                           |
    | |                               |   |  |       |                   |                           |
    | |                               |   |  |       ----RxSourceEmitter-                            |
    | |                               |   |  |                  |                                    |
    | |                               |   |   - - - -  - - - - -|- 弱引用- -- - - - - - - - - - - - -
    | |                               |   强                     --------------------------
    |  - - - - -弱引用- - - - - - - - -     ->RxTransEmitter- - - - - - - - - - - - - -     |
    |                                                                                 |    |
    |                                                                                 |    |
     ------强引用---RxSourceEmitter->RxScheduleEmitter->RxEmitter->ConsumerOnNext      |    |
                     ^   ^                                                             |   |
                     |   |                                                             |   |
                     |    - - -弱引用- - -  - - - - - - - - -  - - - - -  - - - - - - -     |
                     -------------------------强引用-----------------------------------------

 注意几个弱引用，这几个弱引用是避免循环引用的关键，因为这里面的关系很复杂，中间可能有超过7个对象的循环引用，所以一定要注意


 一个数据从上游发到下游路径是这样的
 up.RxOCSource -> up.RxSourceEmitter(RxSourceEmitter可能还存在RxTransEmitter这样辅助性的emitter)
 ->up.ScheduleEmitter -> up.RxEmitter -> ConsumerOnNext->(下游选择将数据转换，或者利用数据形成另一个RxOC继续发送)
 down.RxSourceEmitter -> down.RxScheduleEmitter -> down.RxEmitter -> ConsumerOnNext->...

 RxSourceEmitter的引用是比较特殊的，这个对象是唯一对RxOC持有强引用的emitter，其他所有的emitter对RxOC都是弱引用
 RxOC的生命周期依赖于订阅他的时候所生成的那个RxSourceEmitter，只要RxSourceEmitter不被释放，那么对应的emitter链
 和RxOC都是有效的，
 上游的RxSourceEmitter持有下游的RxSourceEmitter,形成了以下的链

 stream1 ->stream1.RxOCSouce->stream1.RxScheduleEmitter
    ^
    |
    ----stream1.RxSourceEmitter->stream1.RxScheduleEmitter->stream1.RxEmitter...
            |
            |      stream2->stream2.RxOCSouce->stream2.RxScheduleEmitter
            |       ^
            |       |
             ----->stream2.RxSourceEmitter->stream2.RxScheduleEmitter->stream2.RxEmitter...
                          |
                          |      stream3->stream3.RxOCSouce->stream3.RxScheduleEmitter
                          |       ^
                          |       |
                           ----->stream3.RxSourceEmitter->stream3.RxScheduleEmitter->stream3.RxEmitter...
 stream1属于最上游，然后依次是stream2 stream3
 这个关键的RxSourceEmitter的downStreamEmitterChain成员引用了下游的RxSourceEmitter

 这样做的目的在于，RxOC框架并不管理RxOC对象，RxOC对象随着事件源对RxSourceEmitter的计数而存在或者消失，
 这样就意味着，RxOC对象，在事件源把事件发送完毕，对RxSourceEmitter计数为0的时候，自动销毁

 还有关于RxOC的引用计数问题
 RxOC的引用计数分为两个阶段讨论，
    （1）在订阅过后，事件源启动前。这个时候TaskHandle持有RxOC的引用
         当这个Task执行过后，对RxOC的引用结束了，如果事件源是异步的，那么事件源中的线程应当对传入的emitter持有引用
         才能保证自身RxOC以及下游的RxOC对象不被释放
    （2）事件源执行完毕，将事件通过emitter发送，然后最终会经过RxScheduleEmitter进行调度
    这个时候，RxScheduleEmitter会递交一个Task到线程池，这个Task持有了RxScheduleEmitter的引用
    同时持有了一份RxSourceEmitter的引用，这样在事件分发的时候，RxOC仍然是可访问的，但是事件分发完毕，RxOC的引用计数降为0，释放


 **/
-(id<IRxSubscription>)__subcribe:(ConsumerOnNext)next error:(ConsumerOnError)err complete:(ConsumerOnComplete)comp downEmitterChain:(RxSourceEmitter*)enmitterChain{
    @synchronized (self) {
        return [self __retry:next error:err complete:comp downEmitterChain:enmitterChain retryed:0];
    }
}

//这个方法只在内部调用，请确认好原先的emit链已经断开，然后再调用，否则会有问题
-(id<IRxSubscription>)__retry:(ConsumerOnNext)next error:(ConsumerOnError)err complete:(ConsumerOnComplete)comp
             downEmitterChain:(RxSourceEmitter*)enmitterChain retryed:(int)retryedcount{
    //RxLog(@"__retry:error:complete:retryed:  %@  retryedcount:%d",self,retryedcount);

    //RxLog(@"__retry symbols:%@",[NSThread callStackSymbols]);
    RxRuntime *runtime = [[RxRuntime alloc] initWithRx:self];
    RxSourceEmitter *rootSourceEmitter = enmitterChain;
    while(rootSourceEmitter!=nil && rootSourceEmitter.downStreamEmitterChain!=nil){
        rootSourceEmitter = rootSourceEmitter.downStreamEmitterChain;
    }
    if(rootSourceEmitter==nil){
        runtime.rootRuntime = runtime;
    } else{
        runtime.rootRuntime = rootSourceEmitter.runtime;
    };


    runtime.retryedCount = retryedcount;
    id<EmitterComposite> tail = [[RxEmitter alloc] initWithConsumer:next error:err complete:comp rx:runtime];
    id<EmitterComposite> scheduleEmitterChain = [self buildSchedulerEmitChain:tail runtime:runtime];
    RxScheduleEmitter* scheduleEmitter = [[RxScheduleEmitter alloc] initWithSchedule:_dstMode emitter:scheduleEmitterChain rx:runtime];
    runtime.schedulerEmitter =  scheduleEmitter;
    id<EmitterComposite> dispatchEmitterChain = [self buildFilterChain:scheduleEmitter runtime:runtime];
    RxSourceEmitter* retEmitter = [[RxSourceEmitter alloc] initWithEmitter:dispatchEmitterChain rx:runtime];
    retEmitter.rx = self;
    retEmitter.runtime = runtime;

    schedule_inmode(^(){
        @try{
            for (NSUInteger i=0;i<runtime.consumerOnSubscribe.count;i++){
                runtime.consumerOnSubscribe[i]();
            }
        }@catch(NSException* e){
            err(e);
        }
    },_dstMode);

    TaskHandle* handle = schedule_inmode(^(){//这里负责发布者的线程调度
        @try{
            if(retEmitter!=nil){
                if(enmitterChain!=nil){
                    retEmitter.downStreamEmitterChain = enmitterChain;
                    [enmitterChain addUpStream:retEmitter];
                }
            }
            scheduleEmitter.sourceEmitter = retEmitter;
            runtime.sourceEmitter = retEmitter;
            [self runSource:runtime];//开启
        }@catch(NSException* e){
            RxLog(@"__retry NSException:%@",e);
            schedule_inmode(^{
                err(e);
            }, self->_dstMode);
        }
    }, _sourceMode);

    //id<IRxSubscription> 对scheduleEmitter和handle都是弱引用,因此长期持有并不会导致RxOC无法释放
    id<IRxSubscription> conn = [[RxSubscription alloc] initWithSchedulersAndTaskHandle:scheduleEmitter taskhandle:handle];
    //收集所有的连接，可以通过，在flatmap以及map操作的时候，设置RxOC的上下游关系（也就是下游保存一个上游的引用）
    //然后在__subcribe中，RxOC将连接保存
    //这样就可以通过上游引用取消所有的连接
    //由于任务执行到一半就退出，那么清理任务必须要调用者负责安排，也就是说每个RxOC都应该支持设置一个清理函数，来负责在流断开的时候这个RxOC的清理工作
    return conn;//这里的IRxSubscription仅仅是最顶层的stream的连接，应该吧每个node的连接都返回，（使用代理模式收集连接队列提供统一处理）
}
-(id<EmitterComposite>)buildFilterChain:(id<EmitterComposite>)header runtime:(RxRuntime *)runtime{
    id<EmitterComposite> filterChain = header;
    if(self.filter!=nil){
        RxFilterEmitter* filterEmitter = [[RxFilterEmitter alloc] initWithEmitter:header rx:runtime];
        filterChain = filterEmitter;
    }
    return filterChain;
}

-(id<EmitterComposite>)buildSchedulerEmitChain:(id<EmitterComposite>)tail runtime:(RxRuntime *)runtime{
    id<EmitterComposite> scheduleEmitterChain=tail;
    if(self.retryCount>0){
        RxErrRetryEmitter* retryEmitter = [[RxErrRetryEmitter alloc] initWithEmitter:scheduleEmitterChain rx:runtime];
        scheduleEmitterChain = retryEmitter;
    }
    if(self.rxRetryIf!=nil){
        RxErrRetryIfEmitter* retryEmitter = [[RxErrRetryIfEmitter alloc] initWithEmitter:scheduleEmitterChain rx:runtime];
        scheduleEmitterChain = retryEmitter;
    }
    if(self.rxRetryWhen!=nil){
        RxErrRetryWhenEmitter* retryEmitter = [[RxErrRetryWhenEmitter alloc] initWithEmitter:scheduleEmitterChain rx:runtime];
        scheduleEmitterChain = retryEmitter;
    }
    if(self.rxErrResume){
        RxErrResumeEmitter* errResumeEmitter = [[RxErrResumeEmitter alloc] initWithEmitter:scheduleEmitterChain rx:runtime];
        scheduleEmitterChain = errResumeEmitter;
    }
    if(self.rxErrReturn){
        RxErrReturnEmitter* errReturnEmitter = [[RxErrReturnEmitter alloc] initWithEmitter:scheduleEmitterChain rx:runtime];
        scheduleEmitterChain = errReturnEmitter;
    }
    return scheduleEmitterChain;
}

-(void)runSource:(RxRuntime *)runtime{
    if(self.source!=nil){
        [self.source run:runtime];
    }
}
@end
