//
// Created by 黎书胜 on 2017/11/27.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import "RxOCTransform.h"
#import "RxOC.h"
#import "RxInnerDefs.h"
#import "RxEmitter.h"
#import "RxRuntime.h"
@interface RxOCTransform()

@end


@implementation RxOCTransform
- (void)run:(RxRuntime *)runtime{
    __weak typeof(self) weakSelf = self;
    [self.up __subcribe:^(id next){//upstream
        [runtime.sourceEmitter onNext:next];
    } error:^(NSException* e){
        [runtime.sourceEmitter onError:e];
    } complete:^(){
        [runtime.sourceEmitter onComplete];
    } downEmitterChain:runtime.sourceEmitter];
}
@end

@implementation RxMapOCTransform
-(void)transDataAndEmit:(id)from emitter:(RxTransEmitter*)transEmitter{//不知为何，这个@try catch块放到block里面会导致内存泄露
    id transed = nil;
    @try{
        transed = self.trans(from);
    }@catch(NSException* e){
        [transEmitter onError:e];
        return;
    }
    //NSLog(@"==transDataAndEmit emitter:%@==",self.emitter);
    [transEmitter onNext:transed];
}
- (void)run:(RxRuntime *)runtime{
    __weak typeof(self) weakSelf = self;
    RxTransEmitter *transEmitter= [[RxTransEmitter alloc] initWithEmitter:runtime.sourceEmitter rx:runtime];
    [runtime addRuntimeObject:@"RxMapOCTransform.transEmitter" obj:transEmitter];

    [self.up __subcribe:^(id next){//upstream
        [weakSelf transDataAndEmit:next emitter:transEmitter];
    } error:^(NSException* e){
        [transEmitter onError:e];
    } complete:^(){
        [transEmitter onComplete];
    } downEmitterChain:runtime.sourceEmitter];
    //self.up = nil;
    // 此处对__subcribe传入的block必须对RxMapOCTransform持有弱引用
    //RxMapOCTransform -> upstream -> RxEventSource -> RxScheduleEmitter -> RxEmitter -> OnNext(就是此处的传入__subcribe的block)
    // -> RxMapOCTransform
}
@end

@interface RxFlatMapOCTransform()
@property (assign, atomic) NSInteger streamCount;
@end

@implementation RxFlatMapOCTransform
-(instancetype)init{
    self = [super init];
    self.streamCount = 0;
    return self;
}
-(void)transDataAndEmit:(id)from emitter:(RxTransEmitter*)transEmitter{
    RxOC* flated = nil;
    @try{
        flated = self.trans(from);//新生成的流的事件源的事件由 RxFlatTrans生成的流和上游提供
        flated.name = @"flatmap.trans";
    }@catch(NSException* e){
        [transEmitter onError:e];
        return;
    }
    [self runNewStream:flated emitter:transEmitter];
}
-(void)runNewStream:(RxOC*)flated emitter:(RxTransEmitter*)transEmitter{
    @synchronized (self) {
        self.streamCount++;
    }
    __weak typeof(self) weakSelf = self;
    [flated __subcribe:^(id value) {//新的流的结果也要由flatmap流来发
        [transEmitter onNext:value];
    } error:^(NSException *value) {
        //这里应该把tagid设给value，因为如果不设，那么flatMap产生的tagid就被丢弃了，这里必须要覆盖
        RxLog(@"RxFlatMapOCTransform ==onError %@",[transEmitter getNextEmitter]);
        [transEmitter onError:value];//上游发送的onError应直接送出
    } complete:^{
        @synchronized (weakSelf) {
            weakSelf.streamCount--;
            if(weakSelf.streamCount==0){
                [transEmitter onComplete];
            }
        }
    } downEmitterChain:(RxSourceEmitter *)[transEmitter getNextEmitter]];
}
- (void)run:(RxRuntime *)runtime{
    __weak typeof(self) weakSelf = self;
    RxTransEmitter *transEmitter= [[RxTransEmitter alloc] initWithEmitter:runtime.sourceEmitter rx:runtime];
    [runtime addRuntimeObject:@"RxFlatMapOCTransform.transEmitter" obj:transEmitter];
    [self.up __subcribe:^(id value) {//上游
       [weakSelf transDataAndEmit:value emitter:transEmitter];
    } error:^(NSException *value) {
        [runtime.sourceEmitter onError:value];
    } complete:^{
        @synchronized (weakSelf) {
            if (weakSelf.streamCount == 0) {
                [runtime.sourceEmitter onComplete];
            }
        }
    } downEmitterChain:runtime.sourceEmitter];
    //self.up = nil;
    // 此处对__subcribe传入的block必须对RxMapOCTransform持有弱引用
    //RxFlatMapOCTransform -> upstream -> RxEventSource -> RxScheduleEmitter -> RxEmitter -> OnNext(就是此处的传入__subcribe的block)
    // -> RxFlatMapOCTransform
}
@end


@interface RxZipTransform()
@end
@implementation RxZipTransform

-(void)inputData:(id)from arr:(NSMutableArray *)arr{
    @synchronized (self) {
        [arr addObject:from];
    }
}
-(void)outputData:(RxTransEmitter *)transEmitter runtime:(RxRuntime *)runtime{
    @synchronized (self) {
        NSMutableArray* upArr = [runtime getRuntimeObject:@"RxZipTransform.upArr"];
        NSMutableArray* rhArr = [runtime getRuntimeObject:@"RxZipTransform.rhArr"];
        if(upArr.count>0 && rhArr.count>0){
            id upValue = upArr[0];
            id rhValue = rhArr[0];
            [upArr removeObjectAtIndex:0];
            [rhArr removeObjectAtIndex:0];
            @try {
                id zipValue = self.zipFunc(upValue,rhValue);
                [transEmitter onNext:zipValue];
            }@catch (NSException *e){
                [transEmitter onError:e];
            }
        }
    }
}
-(void)notifyError:(NSException *)e emitter:(RxTransEmitter *)transEmitter{
    @synchronized (self) {
        [transEmitter onError:e];
    }
}
-(void)notifyComplete:(RxTransEmitter *)transEmitter runtime:(RxRuntime *)runtime{
    @synchronized (self) {
        NSMutableArray* upArr = [runtime getRuntimeObject:@"RxZipTransform.upArr"];
        NSMutableArray* rhArr = [runtime getRuntimeObject:@"RxZipTransform.rhArr"];
        if(upArr.count==0 && rhArr.count==0){
            [transEmitter onComplete];
        }
    }
}
- (void)run:(RxRuntime *)runtime{
    __weak typeof(self) weakSelf = self;
    RxTransEmitter *transEmitter= [[RxTransEmitter alloc] initWithEmitter:runtime.sourceEmitter rx:runtime];
    [runtime addRuntimeObject:@"RxZipTransform.transEmitter" obj:transEmitter];
    NSMutableArray* upArr = [NSMutableArray new];
    NSMutableArray* rhArr = [NSMutableArray new];
    [runtime addRuntimeObject:@"RxZipTransform.upArr" obj:upArr];
    [runtime addRuntimeObject:@"RxZipTransform.rhArr" obj:rhArr];

    id<IRxSubscription> upSub =[self.up __subcribe:^(id from){
        [weakSelf inputData:from arr:upArr];
        [weakSelf outputData:transEmitter runtime:runtime];
    } error:^(NSException * e){
        [weakSelf notifyError:e emitter:transEmitter];
    } complete:^(){
        [weakSelf notifyComplete:transEmitter runtime:runtime];
    } downEmitterChain:runtime.sourceEmitter];
    [runtime addRuntimeObject:@"RxZipTransform.upSubscription" obj:upSub];

    id<IRxSubscription> rhSub = [self.rh __subcribe:^(id from){
        [weakSelf inputData:from arr:rhArr];
        [weakSelf outputData:transEmitter runtime:runtime];
    } error:^(NSException * e){
        [weakSelf notifyError:e emitter:transEmitter];
    } complete:^(){
        [weakSelf notifyComplete:transEmitter runtime:runtime];
    } downEmitterChain:runtime.sourceEmitter];
    [runtime addRuntimeObject:@"RxZipTransform.rhSubscription" obj:rhSub];
}
@end

@interface RxCombineLastTransform()
//@property (assign, atomic) int completeCount;
@end

@implementation RxCombineLastTransform
-(void)inputData:(id)from arr:(NSMutableArray *)arr{
    @synchronized (self) {
        [arr addObject:from];
    }
}
-(void)outputData:(RxTransEmitter *)transEmitter runtime:(RxRuntime *)runtime{
    @synchronized (self) {
        NSMutableArray* upArr = [runtime getRuntimeObject:@"RxZipTransform.upArr"];
        NSMutableArray* rhArr = [runtime getRuntimeObject:@"RxZipTransform.rhArr"];
        if(upArr.count>0 && rhArr.count>0){
            id upValue = upArr[upArr.count-1];
            id rhValue = rhArr[rhArr.count-1];
            @try {
                id zipValue = self.zipFunc(upValue,rhValue);
                [transEmitter onNext:zipValue];
            }@catch (NSException *e){
                [transEmitter onError:e];
            }
        }
    }
}

-(void)notifyComplete:(RxTransEmitter *)transEmitter runtime:(RxRuntime *)runtime{
    @synchronized (self) {
        NSNumber *completeCount = [runtime getRuntimeObject:@"RxZipTransform.completeCount"];
        completeCount = @(completeCount.intValue+1);
        [runtime addRuntimeObject:@"RxZipTransform.completeCount" obj:completeCount];
        if(completeCount.intValue==2){
            [transEmitter onComplete];
        }
    }
}
-(void)run:(RxRuntime *)runtime{
    NSNumber *completeCount=@(0);
    [runtime addRuntimeObject:@"RxZipTransform.completeCount" obj:completeCount];
    [super run:runtime];
}
@end

@interface RxMergeTransform()
@end
@implementation RxMergeTransform
-(void)notifyError:(NSException *)e emitter:(RxTransEmitter *)transEmitter runtime:(RxRuntime *)runtime{
    @synchronized (self) {
        runtime.mergeErrorCount = runtime.mergeErrorCount+1;
        [transEmitter onError:e];
    }
}
-(void)notifyComplete:(RxTransEmitter *)transEmitter runtime:(RxRuntime *)runtime{
    @synchronized (self) {
        runtime.mergeCompleteCount = runtime.mergeCompleteCount+1;
        if(runtime.mergeCompleteCount ==2){
            [transEmitter onComplete];
        }
    }
}
- (void)run:(RxRuntime *)runtime{
    __weak typeof(self) weakSelf = self;
    RxTransEmitter *transEmitter= [[RxTransEmitter alloc] initWithEmitter:runtime.sourceEmitter rx:runtime];
    [runtime addRuntimeObject:@"RxFlatMapOCTransform.transEmitter" obj:transEmitter];
    [self.up __subcribe:^(id from){
        [transEmitter onNext:from];
    } error:^(NSException * e){
        runtime.mergeUpError = e;
        [weakSelf notifyError:e emitter:transEmitter runtime:runtime];
    } complete:^(){
        [weakSelf notifyComplete:transEmitter runtime:runtime];
    } downEmitterChain:runtime.sourceEmitter];

    [self.rh __subcribe:^(id from){
        [transEmitter onNext:from];
    } error:^(NSException * e){
        runtime.mergeRhError = e;
        [weakSelf notifyError:e emitter:transEmitter runtime:runtime];
    } complete:^(){
        [weakSelf notifyComplete:transEmitter runtime:runtime];
    } downEmitterChain:runtime.sourceEmitter];
}
@end

@implementation RxMergeWithDelayErrorTransform
-(void)notifyError:(NSException *)e emitter:(RxTransEmitter *)transEmitter runtime:(RxRuntime *)runtime{
    @synchronized (self) {
        runtime.mergeErrorCount = runtime.mergeErrorCount+1;
        [self realNotifyError:transEmitter runtime:runtime];
    }
}
-(void)realNotifyError:(RxTransEmitter *)transEmitter runtime:(RxRuntime *)runtime{
    if((runtime.mergeErrorCount + runtime.mergeCompleteCount) == 2){
        @try {
            NSException *merge = self->_mergeFunc(runtime.mergeUpError,runtime.mergeRhError);
            [transEmitter onError:merge];
        }@catch(NSException *e1){
            [transEmitter onError:e1];
        }
    }
}
-(void)notifyComplete:(RxTransEmitter *)transEmitter runtime:(RxRuntime *)runtime{
    [super notifyComplete:transEmitter runtime:runtime];
    [self realNotifyError:transEmitter runtime:runtime];
}
@end

@implementation RxIntervalTimerTransform
-(void)onCanceled:(RxScheduleEmitter *)emit {
    NSTimer *timer = [[emit getRx] getRuntimeObject:@"RxIntervalTimerTransform.timer"];
    if(timer!=nil){
        //RxLogT(@"OCTest",@">>RxIntervalTimerTransform onCanceled");
        //注意，这里并不会回调到subscribe函数设置的onError而是clean设置的
        [[emit getRx].sourceEmitter onError:[[NSException alloc] initWithName:@"RxError" reason:@"unsubsribed,timer will invalidate!" userInfo:nil]];
        [timer invalidate];
    }
}
- (void)run :(RxRuntime *)runtime{
    RxSourceEmitter *sourceEmitter = runtime.sourceEmitter;//这里必须强引用，保证timer运行期间RxOC不被释放
    runtime.schedulerEmitter.onCancelListener = self;
    if(self.isHot){
        [sourceEmitter onNext:@(1)];
        self.repeat = self.repeat-1;
    }
    RXWEAKDECL(ws)
    if(self.isMain){
        //这里NSTimer因为返回的是动态代理，所以不会产生循环引用
        NSTimer *timer = [RxThreadUtil buildTimer:(int)self.sec*1000 repeat:self.repeat blk:^(NSTimer *t,int repeatcount){
            //RxLogT(@"OCTest",@">>buildThreadTimer:%d", repeatcount);
            [sourceEmitter onNext:@(repeatcount+(ws.isHot?1:0))];
        }];
        [runtime addRuntimeObject:@"RxIntervalTimerTransform.timer" obj:timer];
    }else{
        //RxLogT(@"OCTest",@">>buildThreadTimer in:%@",[NSThread currentThread]);
        NSTimer *timer = [RxThreadUtil buildThreadTimer:(int)self.sec*1000 repeat:self.repeat blk:^(NSTimer *t,int repeatcount){
            //RxLogT(@"OCTest",@">>buildThreadTimer:%d",repeatcount);
            [sourceEmitter onNext:@(repeatcount+(ws.isHot?1:0))];
        }];
        [runtime addRuntimeObject:@"RxIntervalTimerTransform.timer" obj:timer];
    }
}
@end
