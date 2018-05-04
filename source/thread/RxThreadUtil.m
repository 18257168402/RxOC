//
//  RxThreadUtil.m
//  guard
//
//  Created by 黎书胜 on 2017/10/26.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#import "RxThreadUtil.h"
#import<objc/runtime.h>
#import "RxWeakWrapper.h"
#import "RxProxyUtil.h"
#import "RxRunTimeUtil.h"

static BOOL isGlobalSerialCreated = NO;
static dispatch_queue_t g_serial_queue;

@implementation TaskHandle
-(id)initWithBlk:(dispatch_block_t)blk lock:(id)lck{
    self= [super init];
    self->_task = blk;
    self->Lck = lck;
    _cancel = NO;
    //NSLog(@"=====initWithBlk==TaskHandle=");
    return self;
}
-(void)dealloc{
    //NSLog(@"=====dealloc==TaskHandle=");
}
-(void)invalidate{
    @synchronized(Lck){
        _cancel = YES;
    }
}
-(void)run{
    if(!_cancel){
        @synchronized(Lck){
            if(_cancel){
                return;
            }
        }
        self->_task();
    }
}

@end

//typedef void(^OnTimerInvalidate)();
//@interface MyTimer:NSTimer
//@property (strong, nonatomic) OnTimerInvalidate invalidateLis;
//@end
//@implementation MyTimer
//+(instancetype)timerWithTimeInterval:(NSTimeInterval)interval repeats:(BOOL)repeats block:(void (^)(NSTimer *timer))block {
//
//}
//-(void)invalidate{
//    [super invalidate];
//    if(self.invalidateLis){
//        self.invalidateLis();
//    }
//}
//@end

@interface MyTimerInvocation:NSObject
@property (weak, nonatomic) NSTimer *timer;
@property (strong, nonatomic) RxEasyProxy* proxy;
@property (assign, nonatomic) int repeatCount;
@property (assign, nonatomic) int count;
@property (strong, nonatomic) HLTimerBlock blk;
@property (weak, nonatomic) NSInvocation *proxyInvocation;
@end
@implementation MyTimerInvocation
+(void)placeholer{

}
-(instancetype)init{
    self = [super init];
    //EasyLog(@"MyTimerInvocation init");
    return self;
}
-(void)dealloc{
    //EasyLog(@"MyTimerInvocation dealloc");
}
+(instancetype)newTimerInvocation{
    MyTimerInvocation *instance = [MyTimerInvocation new];
    return instance;
}
-(NSInvocation *)getInvocation{
    NSMethodSignature* sig = [NSMethodSignature signatureWithObjCTypes:"v@:v"];
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
    invocation.target = [MyTimerInvocation class];
    invocation.selector = @selector(placeholer);
    RxEasyProxy *invocationProxy = [RxEasyProxy newStrongProxy:invocation];

    [invocationProxy setInterceptBeforeInvoke:@[@"invoke",@"invokeWithTarget:"] intercept:^(NSObject *target,SEL sel,NSInvocation *invo){
        [self invoke];
        return YES;
    }];
    self.proxyInvocation = (NSInvocation *)invocationProxy;
    return self.proxyInvocation;
}
-(void)invoke {
    //EasyLog(@"===MyTimerInvocation invoke====!!");
    self.count++;
    NSTimer *proxyTimer =(NSTimer *)self.proxy;
    self.blk(proxyTimer,self.count);
    if(self.count == self.repeatCount){
        [proxyTimer invalidate];
    }
}
@end


@interface MyDisplayRunInfo:NSObject
-(instancetype)initWithBlk:(HLDisplayLinkBlock)blk framecount:(int)framecount;
-(void)run;
@property (strong, nonatomic)HLDisplayLinkBlock blk;
@property (assign, nonatomic)int curCount;
@property (assign, nonatomic)int frameCount;
@property (weak, nonatomic)CADisplayLink *displayLink;
@end
@implementation MyDisplayRunInfo
-(instancetype)initWithBlk:(HLDisplayLinkBlock)blk framecount:(int)framecount{
    self = [super init];
    self.curCount = 0;
    self.frameCount = framecount;
    self.blk = blk;
    //EasyLog(@"==MyDisplayRunInfo init:%d %d ",self.curCount,self.frameCount);
    return self;
}
-(void)dealloc{
   // EasyLog(@"==MyDisplayRunInfo dealloc");
}
-(void)run{
    //EasyLog(@"==MyDisplayRunInfo run:%d",self.curCount);
    self.curCount++;
    if(self.curCount == self.frameCount){
        [self.displayLink invalidate];
    }
    if(self.blk!=nil){
        //long long timeBefore = [TimeUtil currentTimeMillis];
        self.blk(self.displayLink,self.frameCount,self.curCount);
        //EasyLog(@"MyDisplayRunInfo runtime:%lld",([TimeUtil currentTimeMillis] - timeBefore));
    }
}
@end

@implementation RxThreadUtil
+(BOOL)isOnMainThread{
    return [NSThread isMainThread];
}
+(TaskHandle*)runOnMainThread:(dispatch_block_t) task{
    TaskHandle* handle = [[TaskHandle alloc] initWithBlk:task lock:self];
    dispatch_async(dispatch_get_main_queue(),^(){
        if(handle!=nil){
            [handle run];
        }
    });
    return handle;
}


+(TaskHandle*)runOnBackground:(dispatch_block_t) task{
    
    //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), task);
    TaskHandle* handle = [[TaskHandle alloc] initWithBlk:task lock:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^(){
        if(handle!=nil){
            [handle run];
        }
    });
    return handle;
}

+(TaskHandle*)runOnMainThread:(dispatch_block_t) task after:(int)ms{
    TaskHandle* handle = [[TaskHandle alloc] initWithBlk:task lock:self];
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ms * NSEC_PER_MSEC));
    dispatch_after(delayTime,dispatch_get_main_queue(),^(){
        if(handle!=nil){
            [handle run];
        }
    });
    return handle;
}
+(TaskHandle*)runOnBackground:(dispatch_block_t) task after:(int)ms{
    TaskHandle* handle = [[TaskHandle alloc] initWithBlk:task lock:self];
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ms * NSEC_PER_MSEC));
    dispatch_after(delayTime,dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0),^(){
        if(handle!=nil){
            [handle run];
        }
    });
    return handle;
}
+(void)buildSerialQueue{
    @synchronized(self){
        if(!isGlobalSerialCreated){
            g_serial_queue = dispatch_queue_create("com.hl.serial.gcd", DISPATCH_QUEUE_SERIAL);
        }
    }
}
+(TaskHandle*)runOnBackgroundSerial:(dispatch_block_t) task{//放入全局串行队列执行
    [self buildSerialQueue];
    TaskHandle* handle = [[TaskHandle alloc] initWithBlk:task lock:self];
    dispatch_async(g_serial_queue,^(){
        if(handle!=nil){
            [handle run];
        }
    });
    return handle;
}
+(TaskHandle*)runOnBackgroundSerial:(dispatch_block_t) task after:(int)ms{
    [self buildSerialQueue];
    TaskHandle* handle = [[TaskHandle alloc] initWithBlk:task lock:self];
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ms * NSEC_PER_MSEC));
    dispatch_after(delayTime,g_serial_queue,^(){
        if(handle!=nil){
            [handle run];
        }
    });
    return handle;
}

+(HLThreadHandler*) buildUIHandler:(id<MessageHandler>)handle{
    if(![RxThreadUtil isOnMainThread]){
        __block HLThreadHandler* retHandler;
        dispatch_sync(dispatch_get_main_queue(), ^(){
            retHandler = [RxThreadUtil buildUIHandler:handle];
        });
        return retHandler;
    }
    HLThreadHandler* handler = [[HLThreadHandler alloc] initWithHandle:handle];
    return handler;
}

+(HLThreadHandler*)buildNewThreadHandler:(id<MessageHandler>)handle{
    HLThreadHandler* handler = [[HLThreadHandler alloc] initWithHandle:handle];
    HLThreadForLoop* thread=[[HLThreadForLoop alloc] initWithTarget:handler selector:@selector(thread_entry_point:) object:nil];
    thread.isNeedQuitLoop = NO;
    [thread start];
    [handler setThreadMode:thread];
    return handler;
}

/**
 有两种情况会导致NSTimer不被回调
 1 当使用scheduledTimerWithTimeInterval启动。但是启动的线程不是主线程（使用timerWithTimeInterval然后加入mainRunloop则无此限制）
 2 当timer启动后，主线程一直被阻塞，则NSTimer不被回调
 **/
+(NSTimer*) buildTimer:(int)ms repeat:(int)repeat blk:(HLTimerBlock)blk{
//    __block int count=0;
//    NSTimer* timer = [NSTimer timerWithTimeInterval:[TimeUtil intervalFromMs:ms] repeats:YES block:^(NSTimer* t){
//        count++;
//        blk(t,count);
//        if(count == repeat){
//            [t invalidate];
//        }
//    }];
//    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];


    MyTimerInvocation* invocation = [MyTimerInvocation newTimerInvocation];
    invocation.repeatCount = repeat;
    invocation.count =0;
    invocation.blk = blk;

    NSTimer* timer =[NSTimer timerWithTimeInterval:(ms*1.0f)/1000 invocation:[invocation getInvocation] repeats:YES];
    invocation.timer = timer;
    RxEasyProxy *proxy = [RxEasyProxy newWeakProxy:timer];
    invocation.proxy = proxy;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
//    NSTimer* timer = [NSTimer scheduledTimerWithTimeInterval:[TimeUtil intervalFromMs:ms] repeats:repeat block:^(NSTimer * _Nonnull timer) {
//        count++;
//        blk(timer,count);
//    }];
    
    return (NSTimer*)proxy;
}
+(CADisplayLink *)buildDisplayLink:(int)frameCount blk:(HLDisplayLinkBlock)blk{
    return [self buildDisplayLink:frameCount blk:blk per:1];
}
+(CADisplayLink *)buildDisplayLink:(int)frameCount blk:(HLDisplayLinkBlock)blk per:(int)perframe{
    MyDisplayRunInfo* info = [[MyDisplayRunInfo alloc] initWithBlk:blk framecount:frameCount];
    CADisplayLink* display = [CADisplayLink displayLinkWithTarget:info selector:@selector(run)];
    info.displayLink = display;
    [RxRunTimeUtil attachExtraObj:display key:@selector(buildDisplayLink:blk:) obj:info mode:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
    display.frameInterval = perframe;//每多少帧刷新
    [display addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    RxEasyProxy *proxy = [RxEasyProxy newWeakProxy:display];
    return proxy;
}
+(NSTimer *)buildThreadTimer:(int)ms repeat:(int)repeat blk:(HLTimerBlock)blk{
     static HLThreadHandler *threadHandler = nil;
     static int timerCount = 0;
     static NSTimer *stopTimer=nil;
    @synchronized ([RxThreadUtil class]) {
        if(threadHandler == nil){
            RxLog(@"buildNewThreadHandler!");
            threadHandler = [RxThreadUtil buildNewThreadHandler:nil];
            timerCount = 0;
        }
        if(stopTimer != nil){
            RxLog(@"invalidate stopTimer!!");
            [stopTimer invalidate];
            stopTimer = nil;
        }
        /**
            MyTimerInvocation负责具体的timer逻辑
            传递给NSTimer是一个NSInvocation的代理，代理截获NSInvocation的invoke和invokeWithTarget:函数
            转发到MyTimerInvocation的invoke函数
         */
        MyTimerInvocation* invocation = [MyTimerInvocation newTimerInvocation];
        invocation.repeatCount = repeat;
        invocation.count =0;
        invocation.blk = blk;

        NSTimer* timer =[NSTimer timerWithTimeInterval:(ms*1.0f)/1000 invocation:[invocation getInvocation] repeats:YES];
        invocation.timer = timer;
        /**
         返回的NSTimer*也是一个代理，这个代理弱引用真正的NSTimer，然后拦截invalidate函数，
         通过这个invalidate来进行计算当前有多少个NStimer工作，
         如果没有NSTimer在工作，那么就新建一个10秒的停止线程循环的任务
         当然，如果这个期间需要新建新的thread timer，就取消这个stopTimer就好了
         */
        RxEasyProxy *proxy = [RxEasyProxy newWeakProxy:timer];
        [proxy setInterceptAfterInvoke:@[@"invalidate"] intercept:^(NSObject *target,SEL sel,NSInvocation *invo){
            RxLog(@"== invalidate ==timerCount:%d",timerCount);
            @synchronized ([RxThreadUtil class]) {
                timerCount--;
                if(timerCount == 0){//十秒后如果还是没有运行其他timer则退出
                    NSMethodSignature* sig = [NSMethodSignature signatureWithObjCTypes:"v@:v"];
                    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
                    invocation.target = [MyTimerInvocation class];
                    invocation.selector = @selector(placeholer);
                    RxEasyProxy *invocationProxy = [RxEasyProxy newStrongProxy:invocation];
                    [invocationProxy setInterceptBeforeInvoke:@[@"invoke",@"invokeWithTarget:"] intercept:^(NSObject *target,SEL sel,NSInvocation *invo){
                        @synchronized ([RxThreadUtil class]) {
                            RxLog(@"no timer run will destory threadHandler!!");
                            [threadHandler destory];
                            stopTimer = nil;
                            threadHandler = nil;
                        }
                        return YES;
                    }];
                    stopTimer = [NSTimer timerWithTimeInterval:10 invocation:(NSInvocation*)invocationProxy repeats:NO];
//                    stopTimer = [NSTimer timerWithTimeInterval:10 repeats:NO block:^(NSTimer* t){
//                        @synchronized ([RxThreadUtil class]) {
//                            EasyLog(@"no timer run will destory threadHandler!!");
//                            [threadHandler destory];
//                            stopTimer = nil;
//                            threadHandler = nil;
//                        }
//                    }];
                    [threadHandler.loop addTimer:stopTimer forMode:NSRunLoopCommonModes];
                }
            }
        }];
        invocation.proxy = proxy;
        timerCount++;
        [threadHandler.loop addTimer:timer forMode:NSRunLoopCommonModes];
        return (NSTimer *)proxy;
    }
}

@end





@implementation HLThreadHandler
-(id)initWithHandle:(id<MessageHandler>)hd{
    self = [super init];
    _handler= hd;
    _threadMode = NO;
    _thread =nil;
    _loop = nil;
    _loopCondition = [NSCondition new];
    return self;
}
-(void)setThreadMode:(HLThreadForLoop*)th{
    _threadMode =YES;
    _thread = th;
}
-(void)sendMessage:(HLMessage*)message{
    if(!_threadMode){
        [self performSelectorOnMainThread:@selector(handleMessage:) withObject:message waitUntilDone:NO];
    }else{
        //NSLog(@"====performSelector _thread:%@===",_thread);
        [self performSelector:@selector(handleMessage:) onThread:_thread withObject:message waitUntilDone:NO];
    }
}
-(void)sendMessage:(HLMessage*)message after:(int)ms{
    if(!_threadMode){
        RXWEAKSELF_DECLARE
        [RxThreadUtil runOnMainThread:^{
            [weakself handleMessage:message];
        } after:ms];
    }else{
        RXWEAKSELF_DECLARE
        [RxThreadUtil runOnBackground:^{
            [weakself sendMessage:message];
        } after:ms];
    }
}
-(void)removeMessage:(HLMessage*)message{
    @synchronized(self){
        if(_removeMsgs==nil){
            _removeMsgs = [NSMutableArray new];
        }
        [_removeMsgs addObject:[[RxWeakWrapper alloc]initWithObj:message]];
    }
}
-(void)handleMessage:(HLMessage *)message{
    //NSLog(@"====handlePortMessage===");
    if(_handler!=nil){
        //NSLog(@"====handleMessage 1===");
        @synchronized(self){
            if(_removeMsgs!=nil){
                for (int i=0;i<_removeMsgs.count;i++) {
                    RxWeakWrapper* wrap = _removeMsgs[i];
                    if((wrap.ref != nil && wrap.ref==message)){
                        //NSLog(@"====handleMessage 2===");
                        [_removeMsgs removeObject:wrap];
                        return;
                    }
                    if(wrap.ref==nil){
                        //NSLog(@"====handleMessage 3===");
                        [_removeMsgs removeObject:wrap];
                        i--;
                        continue;
                    }
                }
            }
        }
        //NSLog(@"====handleMessage 4===");
        [_handler handleMessage:message];
    }
}
-(void)destory{
    if(!_threadMode){//不处理
        
    }else{//退出线程loop
        if(_thread!=nil){
            _thread.isNeedQuitLoop = YES;
        }
        [self performSelector:@selector(quitRunLoop) onThread:_thread withObject:nil waitUntilDone:NO];
    }
}
- (void)quitRunLoop {
    CFRunLoopStop(CFRunLoopGetCurrent());
}
-(NSRunLoop*)loop {
    if(_loop == nil){
        [_loopCondition lock];
        if(_loop==nil){
            [_loopCondition wait];
        }
        [_loopCondition unlock];
    }
    return _loop;
}
-(void)thread_entry_point:(id)obj{
    @autoreleasepool{
        [[NSThread currentThread] setName:@"HLThreadHandler"];
        //为了不让runloop run起来没事干导致消失
        //所以给runloop加了一个NSMachPort，给它一个mode去监听
        //实际上port什么也没干，就是让runloop一直在等，目的就是让runloop一直活着
        //这是一个创建常驻服务线程的好方法
        [NSThread sleepForTimeInterval:1];
        _loop = [NSRunLoop currentRunLoop];
        _port = [NSMachPort port];
        [_loop addPort:_port forMode:NSDefaultRunLoopMode];
        [_loopCondition lock];
        [_loopCondition broadcast];
        [_loopCondition unlock];
        NSLog(@"=======NSRunLoop begin=======");
        //当不需要退出的时候,一直处在循环中
        while(!_thread.isNeedQuitLoop){
            @autoreleasepool{
                //这种方式运行的loop，会在处理完一件事件之后返回，因此需要反复运行
                if(![_loop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]){
                    break;
                }
            }
        }
        NSLog(@"=======NSRunLoop end=======");
    }
}
@end

@implementation HLThreadForLoop

@end

@implementation NSRunLoop (Hook)
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self _swizzleImpWithOrigin:@selector(runMode:beforeDate:) swizzle:@selector(xd_runMode:beforeDate:)];
    });//交换runMode:beforeDate:方法
}
+ (void)_swizzleImpWithOrigin:(SEL)originSelector swizzle:(SEL)swizzleSelector {
    Class _class = [self class];
    Method originMethod = class_getInstanceMethod(_class, originSelector);
    Method swizzleMethod = class_getInstanceMethod(_class, swizzleSelector);
    
    IMP originIMP = method_getImplementation(originMethod);
    IMP swizzleIMP = method_getImplementation(swizzleMethod);
    
    BOOL add = class_addMethod(_class, originSelector, swizzleIMP, method_getTypeEncoding(swizzleMethod));
    
    if (add) {
        class_addMethod(_class, swizzleSelector, originIMP, method_getTypeEncoding(originMethod));
    } else {
        method_exchangeImplementations(originMethod, swizzleMethod);
        //交换SEL对应的IMP
    }
}
- (BOOL)xd_runMode:(NSRunLoopMode)mode beforeDate:(NSDate *)limitDate {//run方法启动的loop会通过这个询问来决定是否退出loop
    NSThread *thread = [NSThread currentThread];
    // 这里我们只对自己创建的线程runloop的`runMode:beforeDate:`方法进行修改.
    if ([thread.name isEqualToString:@"HLThreadHandler"] &&( [[NSThread currentThread] isKindOfClass:[HLThreadForLoop class]])) {
        HLThreadForLoop* thread=(HLThreadForLoop*)[NSThread currentThread];
        //NSLog(@"runloop+hook: HLThreadHandler线程 ");
        if(thread.isNeedQuitLoop){
            //return NO;//如果这里返回`NO`, runloop会立刻退出
        }
    }
    return [self xd_runMode:mode beforeDate:limitDate];
}
@end

@implementation HLMessage
-(id)init{
    self=[super init];
    NSLog(@"==HLMessage=init======");
    return self;
}
-(void)dealloc{
    NSLog(@"==HLMessage=dealloc======");
}

@end

