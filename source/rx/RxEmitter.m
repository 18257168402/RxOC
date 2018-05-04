//
// Created by 黎书胜 on 2017/11/24.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import "RxEmitter.h"
#import "RxInnerDefs.h"
#import "RxRuntime.h"
int key_of_tagid = 0;

@implementation RxEmitter//这里将最终结果返回给各个block
-(id)initWithConsumer:(ConsumerOnNext)next error:(ConsumerOnError)e complete:(ConsumerOnComplete)complete rx:(RxRuntime*)rx{
    self=[super initWithEmitter:nil rx:rx];
    _onNext = next;
    _onError = e;
    _onComplete =complete;
    _isOver = NO;
    return self;
}
-(void)onNext:(id)value{
    if(_isOver){
        return;
    }
    @try {
        if(self->_runtime!=nil && self->_runtime.consumerBeforeOnNext!=nil){
            [self->_runtime.consumerBeforeOnNext enumerateObjectsUsingBlock:^(ConsumerOnNext obj,NSUInteger idx,BOOL* stop){
                if(obj){
                    obj(value);
                }
            }];
        }
        if(_onNext!=nil){
            _onNext(value);//通知回调
        }
        if(self->_runtime!=nil && self->_runtime.consumerAfterOnNext!=nil){
            [self->_runtime.consumerAfterOnNext enumerateObjectsUsingBlock:^(ConsumerOnNext obj,NSUInteger idx,BOOL* stop){
                if(obj){
                    obj(value);
                }
            }];
        }
    }@catch (NSException *e){
        [self onError:e];
    }
}
-(void)onError:(NSException*)value{
    if(_isOver){
        return;
    }
    _isOver = YES;
    @try {
        @try {
            if (self->_runtime != nil && self->_runtime.consumerBeforeOnError != nil) {
                [self->_runtime.consumerBeforeOnError enumerateObjectsUsingBlock:^(ConsumerOnError obj, NSUInteger idx, BOOL *stop) {
                    if (obj) {
                        obj(value);
                    }
                }];
            }
        }@catch (NSException *e){
            value = e;
        }
        if(_onError){
            _onError(value);
        }
        if(self->_runtime!=nil && self->_runtime.consumerAfterOnError!=nil){
            [self->_runtime.consumerAfterOnError enumerateObjectsUsingBlock:^(ConsumerOnError obj,NSUInteger idx,BOOL* stop){
                if(obj){
                    obj(value);
                }
            }];
        }
    }@catch (NSException *e){
        if(_onError){
            _onError(e);
        }
    }
}
-(void)onComplete{
    if(_isOver){
        return;
    }
    _isOver = YES;
    @try {
        if(self->_runtime!=nil && self->_runtime.consumerBeforeOnComplete!=nil){
            [self->_runtime.consumerBeforeOnComplete enumerateObjectsUsingBlock:^(ConsumerOnComplete obj,NSUInteger idx,BOOL* stop){
                if(obj){
                    obj();
                }
            }];
        }
        if(_onComplete){
            _onComplete();
        }
        if(self->_runtime!=nil && self->_runtime.consumerAfterOnComplete!=nil){
            [self->_runtime.consumerAfterOnComplete enumerateObjectsUsingBlock:^(ConsumerOnComplete obj,NSUInteger idx,BOOL* stop){
                if(obj){
                    obj();
                }
            }];
        }
    }@catch (NSException *e){
        [self onError:e];
    }
}
@end
/*------------------------------------------*/


@implementation RxWeakOCAndEmitterProxy
-(id<EmitterComposite>) getNextEmitter{
    return _emitter;
}
-(RxRuntime*) getRx{
    return _runtime;
}
-(instancetype)initWithEmitter:(id<EmitterComposite>)emitter rx:(RxRuntime*)oc{
    self = [super init];
    _emitter = emitter;
    _runtime = oc;
    return self;
}
-(void)onNext:(id)value{

    if(_emitter != nil){
        [_emitter onNext:value];
    }
}
-(void)onError:(NSException*)value{//

    if(_emitter !=nil){
        [_emitter onError:value];
    }
//    _emitter=nil;
//    _rxRuntime = nil;
}
-(void)onComplete{

    if(_emitter != nil){
        [_emitter onComplete];
    }
//    _emitter=nil;
//    _rxRuntime = nil;
}
@end

@implementation RxWeakOCEmitterProxy
-(id<EmitterComposite>) getNextEmitter{
    return _emitter;
}
-(RxRuntime*) getRx{
    return _runtime;
}
-(instancetype)initWithEmitter:(id<EmitterComposite>)emitter rx:(RxRuntime*)oc{
    self = [super init];
    _emitter = emitter;
    _runtime = oc;
    return self;
}
-(void)onNext:(id)value{
    if(_emitter != nil){
        [_emitter onNext:value];
    }
}
-(void)onError:(NSException*)value{//
    if(_emitter !=nil){
        [_emitter onError:value];
    }
//    _emitter=nil;
//    _rxRuntime = nil;
}
-(void)onComplete{
    if(_emitter != nil){
        [_emitter onComplete];
    }
//    _emitter=nil;
//    _rxRuntime = nil;
}
@end


@implementation RxStrongOCEmitterProxy
-(instancetype)initWithEmitter:(id<EmitterComposite>)emitter rx:(RxRuntime*)oc{
    self = [super init];
    _emitter = emitter;
    _rxRuntime = oc;
    return self;
}
-(id<EmitterComposite>) getNextEmitter{
    return _emitter;
}
-(RxRuntime*) getRx{
    return _rxRuntime;
}
-(void)onNext:(id)value{
    if(_emitter != nil){
        [_emitter onNext:value];
    }
}
-(void)onError:(NSException*)value{//
    if(_emitter !=nil){
        [_emitter onError:value];
    }
//    _emitter=nil;
//    _rxRuntime = nil;
}
-(void)onComplete{
    if(_emitter != nil){
        [_emitter onComplete];
    }
//    _emitter=nil;
//    _rxRuntime = nil;
}
@end



@implementation RxScheduleEmitter  //source发送的消息都到这里调度
-(void)setCancelled:(BOOL)cancelled{//取消之后，后续emitter将被释放
    //RxLog(@"RxScheduleEmitter.setCancelled %d",cancelled);
    @synchronized (self) {
        self->_cancelled = cancelled;
        if(cancelled){
            if(self.sourceEmitter!=nil){
                [self.sourceEmitter cancelUpstreams];
            }
            if(self.onCancelListener){
                [self.onCancelListener onCanceled:self];
            }
        }
    }
}
-(BOOL)cancelled{
    @synchronized (self) {
        return self->_cancelled;
    }
}
-(instancetype)initWithSchedule:(ScheduleMode)mode emitter:(id<EmitterComposite>)emit rx:(RxRuntime *)rx{
    self = [super initWithEmitter:emit rx:rx];
    _mode = mode;
    self.cancelled=NO;
    return self;
}

-(void)onNext:(id)value{
    //RxLog(@"onNext:%@ canceld:%d self:%@",value,self.cancelled,self);
    @synchronized (self) {
        if (self.cancelled) {
            return;
        }
        RxSourceEmitter *source = self->_runtime.sourceEmitter;
        schedule_inmode(^{
            [self->_emitter onNext:value];
            RxSourceEmitter *emitter = source;
        }, _mode);
    }
}
-(void)onError:(NSException*)value{
    @synchronized (self) {
        if (self.cancelled) {
            //[self->_emitter onError:value];
            //RxLog(@"onError cancelled:%@",self);
            if(self->_runtime!=nil&&self->_runtime.cleanOnError!=nil){
                [self->_runtime.cleanOnError enumerateObjectsUsingBlock:^(RxCleanOnError obj,NSUInteger idx,BOOL* stop){
                    if(obj){
                        obj(value);
                    }
                }];
            }
            return;
        }
        RxSourceEmitter *source = self->_runtime.sourceEmitter;
        schedule_inmode(^{
            [self->_emitter onError:value];
            RxSourceEmitter *emitter = source;
        }, _mode);
    }
}

-(void)onComplete{
    @synchronized (self) {
        if([self->_runtime.rx.name isEqualToString:@"clean"]){
            RxLog(@"clean schduler:%d %@",self.cancelled,self->_runtime.cleanOnComplete);
        }
        if (self.cancelled) {
            //[self->_emitter onComplete];
            RxLog(@"onComplete cancelled");
            if(self->_runtime!=nil&&self->_runtime.cleanOnComplete!=nil){
                [self->_runtime.cleanOnComplete enumerateObjectsUsingBlock:^(RxCleanOnComplete obj,NSUInteger idx,BOOL* stop){
                    if(obj){
                        obj();
                    }
                }];
            }
            return;
        }
        RxSourceEmitter *source = self->_runtime.sourceEmitter;
        schedule_inmode(^{
            [self->_emitter onComplete];
            RxSourceEmitter *emitter = source;
        }, _mode);
    }
}
@end
/*------------------------------------------*/



@implementation RxSourceEmitter
-(instancetype)initWithEmitter:(id<EmitterComposite>)emitter rx:(RxRuntime *)oc{
    self = [super initWithEmitter:emitter rx:oc];
    //NSLog(@"=RxSourceEmitter==initWithEmitter:%@===",self);
    self.upStreams = [NSMutableArray new];
    return self;
}
-(void)dealloc{
    //NSLog(@"=RxSourceEmitter==dealloc:%@===",self);
}
-(void)addUpStream:(RxSourceEmitter *)up{
    @synchronized (self) {
        [self.upStreams addObject:[[RxWeakWrapper alloc] initWithObj:up]];
    }
}
-(void)cancelSchedule{
    id<EmitterComposite> emitter = [self getNextEmitter];
    while (emitter!=nil){
        if([emitter isKindOfClass:[RxScheduleEmitter class]]){
            RxScheduleEmitter* scheduler = (RxScheduleEmitter*)emitter;
            scheduler.cancelled = YES;
            break;
        }
        emitter = [emitter getNextEmitter];
    }
}
-(void)cancelUpstreams{
    @synchronized (self) {
        for (int i = 0; i < self.upStreams.count; ++i) {
            RxSourceEmitter *sourceEmitter = self.upStreams[i].ref;
            if(sourceEmitter!=nil){
                [sourceEmitter cancelSchedule];
            }
        }
    }
}

-(void)onNext:(id)value {
    [super onNext:value];
}
-(void)onError:(NSException*)value{//
    NSException* realException=value;
    if(value==nil){//记住，继承NSException的话，一定要调用initWithName，不然这里onError进来会变成nil
        realException = [[NSException alloc] initWithName:@"RxError" reason:@"auto build at rxsource emitter" userInfo:nil];
    }
    if([RxRunTimeUtil getExtraObj:realException key:&key_of_tagid]==nil){//如果已经有了tagid在value上，那么说明这个事件是从上一个流中发出的，不应该再加
        int tagid = _runtime.tagId;
        [RxRunTimeUtil attachExtraObj:realException key:&key_of_tagid obj:@(tagid) mode:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
    }
    int tagOveride = 0;
    if(_runtime!=nil){
        tagOveride = _runtime.tagOverideId;
    }
    if(tagOveride!=0){
        [RxRunTimeUtil attachExtraObj:value key:&key_of_tagid obj:@(tagOveride) mode:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
    }
    if(_emitter !=nil){
        [_emitter onError:realException];
    }
}
@end

@implementation RxErrResumeEmitter
-(void)onError:(NSException *)value {
    if(self->_runtime!=nil &&self->_runtime.rxErrResume){
        RxOC* bakRx = nil;
        @try {
            bakRx = self->_runtime.rxErrResume(value);
            if(bakRx){
                bakRx.name = @"rxErrResume";
                self->_runtime.schedulerEmitter.cancelled = YES;
                [bakRx __subcribe:^(id resumevalue){
                    [super onNext:resumevalue];
                } error:^(NSException *resumeerr){
                    [super onError:resumeerr];
                } complete:^(){
                    [super onComplete];
                } downEmitterChain:self->_runtime.sourceEmitter];
            }
        }@catch (NSException *e){
            [super onError:value];
        }
        return;
    }
    [super onError:value];
}
@end

@implementation RxErrReturnEmitter
-(void)onError:(NSException *)value {
    if(self->_runtime!=nil &&self->_runtime.rxErrReturn){
        id bakObj = nil;
        @try {
            bakObj = self->_runtime.rxErrReturn(value);
            [_emitter onNext:bakObj];
            [_emitter onComplete];
            self->_runtime.schedulerEmitter.cancelled = YES;
        }@catch (NSException *e){
            [_emitter onError:value];
        }
        return;
    }
    [_emitter onError:value];
}
@end

@implementation RxErrRetryEmitter
-(void)retrySubscribe{
    self->_runtime.retryedCount= self->_runtime.retryedCount + 1;
    RxSourceEmitter *downEmitter = self->_runtime.sourceEmitter;
    __weak id<IRxEmitter> emitterTo=_emitter;
    self->_runtime.schedulerEmitter.cancelled = YES;//取消当前链接，要注意，取消之前应该先强引用一下后续要用的链接，否则取消的时候就已经释放了这些emitter了
    [self->_runtime.rx __retry:^(id retryvalue){
        //RxLog(@"retry onnext:%@",retryvalue);
        [emitterTo onNext:retryvalue];
    } error:^(NSException *retrye){
        //RxLog(@"retry onerror:%@ emitterTo:%@",retrye,emitterTo);
        [emitterTo onError:retrye];
    } complete:^(){
        //RxLog(@"retry oncomplete");
        [emitterTo onComplete];
    } downEmitterChain:downEmitter retryed:self->_runtime.retryedCount];
}
-(void)onError:(NSException *)value {
    if(self->_runtime!=nil && self->_runtime.retryCount>0 && self->_runtime.retryCount > self->_runtime.retryedCount){
        @try {
            [self retrySubscribe];
        }@catch (NSException *e){
            [super onError:value];
        }
        return;
    }
    //RxLog(@"onError retry over:%@",value);
    [super onError:value];
}
@end

@implementation RxErrRetryIfEmitter
-(void)onError:(NSException *)value {
    if(self->_runtime!=nil && self->_runtime.rxRetryIf!=nil && self->_runtime.rxRetryIf(self->_runtime.retryedCount,value)){
        @try {
            [self retrySubscribe];
        }@catch (NSException *e){
            [super onError:value];
        }
        return;
    }
    [super onError:value];
}
@end

@implementation RxErrRetryWhenEmitter
-(void)onError:(NSException *)value {
    if(self->_runtime!=nil && self->_runtime.rxRetryWhen){
        @try {
            RxOC *rxOC = self->_runtime.rxRetryWhen(self->_runtime.retryedCount, value);
            if(rxOC==nil){
                [super onError:value];
            } else{
                rxOC.name = @"rxRetryWhen";
                self->_runtime.schedulerEmitter.cancelled = YES;//取消当前链接
                __weak id<IRxEmitter> weakemitter = _emitter;
                RxSourceEmitter *downSourceEmitter = self->_runtime.sourceEmitter;
                [rxOC __subcribe:^(id from){
                    [self retrySubscribe];
                } error:^(NSException *e){
                    [weakemitter onError:e];
                } complete:^(){
                    [weakemitter onComplete];
                } downEmitterChain:downSourceEmitter];
            }
        }@catch (NSException *e){
            [super onError:value];
        }
        return;
    }
    [super onError:value];
}
@end

@implementation RxFilterEmitter
-(void)onNext:(id)value {
    if(self->_runtime!=nil && self->_runtime.rxFilter){
        @try {
            BOOL filtered = self->_runtime.rxFilter(value);
            if(!filtered){
                return;
            }else{
                [super onNext:value];
            }
        }@catch (NSException *e){
            [super onError:value];
        }
        return;
    }
    [super onNext:value];
}
@end


@implementation RxTransEmitter
-(void)onError:(NSException *)value {
    int tagId = 0;
    if(_runtime!=nil){
        tagId = _runtime.tagId;
    }
    if(tagId!=0){
        [RxRunTimeUtil attachExtraObj:value key:&key_of_tagid obj:@(tagId) mode:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
    }
    [super onError:value];
}
@end
