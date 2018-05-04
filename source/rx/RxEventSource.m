//
// Created by 黎书胜 on 2017/11/27.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import "RxEventSource.h"
#import "RxInnerDefs.h"
#import "RxOCTransform.h"
#import "RxRuntime.h"
@implementation RxOCSource
-(void)run:(RxRuntime *)runtime{

}
@end


@implementation RxEventSource
-(instancetype)initWithRx:(RxOC*)rx source:(RxSource)rxSource{
    self = [super init];
    self.rx = rx;
    self.source = rxSource;
    //RxLogT(RXTAG,@" RxEventSource initWithRx :%@",self);
    return self;
}
-(void)dealloc{
    //RxLogT(RXTAG,@" RxEventSource dealloc :%@",self);
}
-(void)run :(RxRuntime *)runtime{
    if(self.rx==nil){
        RxLogT(RXTAG,@"rx was dealloc at RxEventSource!");
        return;
    }
    RxSourceEmitter* sourceemitter = runtime.sourceEmitter;
    //这里RxSourceEmitter必须强引用RxOC，因为source可能是异步执行，所以回调的时候，如果对rx的引用是弱引用，rx可能已经释放了，对传入的emitter的引用也是同理，也必须强引用
    //可是强引用又会导致 oc->_source强引用sourceEmitter 而sourceEmitter 强引用rx，
    //如果此RxOC进行了map或者flatMap操作，那么在map flatMap下游中的事件源中，又会对sourceEmitter进行一层包裹（flatMapEmitter），
    //而如果flatMapEmitter对souceEmitter是强引用，那么这里容易形成 map流中的 sourceEmitter 强引用 rx，然后flatMapEmitter强引用sourceEmitter
    //而flatMapEmitter又被rx->_source引用(这个引用比较绕，首先rx->_source会对map的事件源RxSource强引用(也就是现在这个block对source的包裹)).
    //就形成了rx->RxEventSource -> RxSource ->  flatMapEmitter  -> SourceEmitter  -> rx 的循环引用，
    //因此，如果SourceEmitter对rx必须强引用，那么在map，flatMapEmitter中就必须弱引用sourceEmitter和rx

    //也就是说一旦涉及到RxSource事件源Block需要对传入他的emitter引用的情况，必须转为弱引用
    sourceemitter.tagId = self.rx.tagId;

    if(self.source != nil) {
        self.source(sourceemitter);//对于map操作，事件源RxSource 里面还会对sourceEmitter包裹一层FlatMapEmitter
        //注意这里面的回调可能是异步的，所以，要保证Rx不被释放
    }
    return;
}
@end

@implementation RxDisposeEventSource
-(instancetype)initWithRx:(RxOC*)rx source:(RxDisposeSource)rxSource{
    self = [super init];
    self.rx = rx;
    self.source = rxSource;
    //RxLogT(RXTAG,@" RxEventSource initWithRx :%@",self);
    return self;
}
-(void)dealloc{
    //RxLogT(RXTAG,@" RxEventSource dealloc :%@",self);
}
-(void)run :(RxRuntime *)runtime{
    if(self.rx==nil){
        RxLogT(RXTAG,@"rx was dealloc at RxEventSource!");
        return;
    }
    RxSourceEmitter* sourceemitter = runtime.sourceEmitter;
    //这里RxSourceEmitter必须强引用RxOC，因为source可能是异步执行，所以回调的时候，如果对rx的引用是弱引用，rx可能已经释放了，对传入的emitter的引用也是同理，也必须强引用
    //可是强引用又会导致 oc->_source强引用sourceEmitter 而sourceEmitter 强引用rx，
    //如果此RxOC进行了map或者flatMap操作，那么在map flatMap下游中的事件源中，又会对sourceEmitter进行一层包裹（flatMapEmitter），
    //而如果flatMapEmitter对souceEmitter是强引用，那么这里容易形成 map流中的 sourceEmitter 强引用 rx，然后flatMapEmitter强引用sourceEmitter
    //而flatMapEmitter又被rx->_source引用(这个引用比较绕，首先rx->_source会对map的事件源RxSource强引用(也就是现在这个block对source的包裹)).
    //就形成了rx->RxEventSource -> RxSource ->  flatMapEmitter  -> SourceEmitter  -> rx 的循环引用，
    //因此，如果SourceEmitter对rx必须强引用，那么在map，flatMapEmitter中就必须弱引用sourceEmitter和rx

    //也就是说一旦涉及到RxSource事件源Block需要对传入他的emitter引用的情况，必须转为弱引用
    sourceemitter.tagId = self.rx.tagId;

    if(self.source != nil) {
        ConsumerOnComplete dispose = self.source(sourceemitter);//对于map操作，事件源RxSource 里面还会对sourceEmitter包裹一层FlatMapEmitter
        //注意这里面的回调可能是异步的，所以，要保证Rx不被释放
        if(dispose!=nil){
            if(runtime.cleanOnComplete==nil){
                runtime.cleanOnComplete = [NSMutableArray new];
            }
            [runtime.cleanOnComplete addObject:dispose];

            if(runtime.cleanOnError==nil){
                runtime.cleanOnError = [NSMutableArray new];
            }
            [runtime.cleanOnError addObject:^(NSException *e){
                dispose();
            }];
            if(runtime.consumerBeforeOnComplete==nil){
                runtime.consumerBeforeOnComplete = [NSMutableArray new];
            }
            [runtime.consumerBeforeOnComplete addObject:dispose];
            if(runtime.consumerBeforeOnError==nil){
                runtime.consumerBeforeOnError = [NSMutableArray new];
            }
            [runtime.consumerBeforeOnError addObject:^(NSException *e){
                dispose();
            }];
        }
    }
    return;
}
@end

@implementation RxTransFormSource
-(instancetype)initWithRx:(RxOC*)rx trans:(RxOCTransform*)rxTrans{
    self = [super init];
    self.rx = rx;
    self.trans = rxTrans;
    return self;
}
-(void)run :(RxRuntime *)runtime{
    if(self.rx==nil){
        RxLogT(RXTAG,@"rx was dealloc at RxEventSource!");
        return;
    }
    RxSourceEmitter* sourceemitter = runtime.sourceEmitter;
    sourceemitter.tagId = self.rx.tagId;
    if(self.trans != nil) {
        [self.trans run:runtime];
    }
    return;
}
@end
