//
//  NSObject+HLCategory.m
//  guard
//
//  Created by 黎书胜 on 2017/10/25.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#import <WebKit/WebKit.h>
#import <objc/message.h>
#import "NSObject+Rx.h"
#import "RxOC.h"
#import "RxOC+AutoUnsubscribe.h"
#import "RxRunTimeUtil.h"
#import <pthread.h>



@implementation RXObserveObject
@end

@interface GCObjectObserver:NSObject
{
@public
    void *_context;
}
@property (assign, nonatomic) BOOL isDetached;
@property (strong, nonatomic) id<IRxEmitter> emitter;
@property (assign, nonatomic) NSKeyValueObservingOptions op;
@property (strong, nonatomic) NSString* keypath;
@property (nonatomic, unsafe_unretained) NSObject *unsafeTarget;
@property (nonatomic, strong) NSValue* pointTarget;
@property (weak, nonatomic) NSObject *weakTarget;
@property (strong, nonatomic) NSString* className;
@end


@interface _GCKVOObserver:NSObject
+(instancetype)instance;
@property (strong, nonatomic) NSMutableArray<GCObjectObserver*> *obsArr;
@property (strong, nonatomic) NSMutableArray<RxWeakWrapper*> *lastObsArr;
-(void)addObs:(GCObjectObserver*)obs;
-(void)removeObs:(GCObjectObserver*)obs;
-(NSString*)description;
-(void)checkKVO;
@end
@implementation _GCKVOObserver

+(instancetype)instance{
    static _GCKVOObserver* ins = nil;
    @synchronized (self) {
        if(ins==nil){
            ins = [_GCKVOObserver new];
        }
    }
    return ins;
}
-(void)recordObs{
    [_lastObsArr removeAllObjects];
    if(_obsArr){
        for(int i=0;i<_obsArr.count;i++){
            [_lastObsArr addObject:[[RxWeakWrapper alloc] initWithObj:_obsArr[i]]];
        }
    }
}
-(BOOL)findAtLast:(GCObjectObserver*)obs{
    if(_lastObsArr){
        for(int i=0;i<_lastObsArr.count;i++){
            RxWeakWrapper *item = _lastObsArr[i];
            if(obs == item.ref){
                return YES;
            }
        }
    }
    return NO;
}
-(void)checkKVO{

    if(_lastObsArr==nil){
        _lastObsArr = [NSMutableArray new];
    }
    if(_lastObsArr.count==0){
        RxLog(@"_GCKVOObserver:%@",[self description]);
        [self recordObs];
        return;
    }
    NSMutableString *addObs = [NSMutableString new];
    NSMutableString *deletedObs = [NSMutableString new];
    NSMutableString *deallocedObs = [NSMutableString new];
    if(_obsArr){
        for(int i=0;i<_obsArr.count;i++){
            GCObjectObserver* item = _obsArr[i];
            if(item.weakTarget==nil){
                [deallocedObs appendFormat:@"[obj:%p \t class:%@ \t keypath:%@]\r\n",item.pointTarget.pointerValue, item.className,item.keypath];
                continue;
            }
            if(![self findAtLast:item]){
                if([item.weakTarget isKindOfClass:[UILabel class]]){
                    UILabel* label = item.weakTarget;
                    [addObs appendFormat:@"[obj:%p \t class:%@ \t text:%@ \t keypath:%@]\r\n",item.weakTarget,
                                    item.className,label.text,item.keypath];
                }else{
                    [addObs appendFormat:@"[obj:%p \t class:%@ \t keypath:%@]\r\n",item.weakTarget, item.className,item.keypath];
                }

                continue;
            }
        }
        if(_lastObsArr){
            for(int i=0;i<_lastObsArr.count;i++){
                RxWeakWrapper *wrap = _lastObsArr[i];
                GCObjectObserver* item = wrap.ref;
                if(nil == item){
                    [deletedObs appendFormat:@"[obj:%p \t class:%@ \t]\r\n",wrap.unsafeRef.pointerValue, wrap.refClass];
                }
            }
        }
    }
    RxLog(@">>>>>>>增加的KVO \r\n");
    RxLog(addObs);
    RxLog(@">>>>>>>target释放了但是没有回调的KVO \r\n");
    RxLog(deallocedObs);
    RxLog(@">>>>>>>释放的KVO \r\n");
    RxLog(deletedObs);
    [self recordObs];
}
-(NSString*)description{
    NSMutableString *descri = [NSMutableString new];

    if(_obsArr){
        [descri appendFormat:@"%@",@">>>>>>>\r\n"];
        for(int i=0;i<_obsArr.count;i++){
            GCObjectObserver* item = _obsArr[i];
            [descri appendFormat:@"[obj:%p \t class:%@ \t keypath:%@]\r\n",
                            item.weakTarget, item.className,item.keypath];
        }
        [descri appendFormat:@">>>>>>>count:%d\r\n",_obsArr.count];
    }
    return descri;
}
-(void)addObs:(GCObjectObserver*)obs{
    @synchronized(self){
        if(_obsArr==nil){
            _obsArr = [NSMutableArray new];
        }
        obs.className = NSStringFromClass([obs.weakTarget class]);
        //RxLog(@">>addObs:%p obs:%p",obs.weakTarget,obs);
        [_obsArr addObject:obs];
    }
    
}
-(void)cleanObs{
    @synchronized(self){
        if(_obsArr!=nil){
            for(int i=0;i<_obsArr.count;i++){
                if(_obsArr[i].weakTarget==nil){
                    [_obsArr removeObjectAtIndex:i];
                    i--;
                    continue;
                }
            }
        }
    }
}
-(void)removeObs:(GCObjectObserver*)obs{
    @synchronized(self){
        if(_obsArr){
            //RxLog(@">>removeObs:%p obs:%p",obs.weakTarget,obs);
            [_obsArr removeObject:obs];
        }
    }
}
-(void)observeValueForKeyPath:(nullable NSString *)keyPath
                     ofObject:(nullable id)object
                       change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change
                      context:(nullable void *)context {
    @synchronized(self){
        if(_obsArr){
            for (int i = 0; i < _obsArr.count; ++i) {
                GCObjectObserver* obs = _obsArr[i];
                if(obs.weakTarget==nil){
                    [_obsArr removeObjectAtIndex:i];
                    i--;
                    continue;
                }
                if(     context == obs->_context &&
                        [keyPath isEqualToString:obs.keypath] &&
                        object == obs.unsafeTarget){
                    [obs observeValueForKeyPath:keyPath
                                              ofObject:object change:change context:context];
                }
            }
        }
    }
}
@end

@implementation GCObjectObserver
-(instancetype)initWithTarget:(NSObject *)target
                       emiter:(id<IRxEmitter>)emt
                      keypath:(NSString*)keypath
                           op:(NSKeyValueObservingOptions)op{
    return [self initWithTarget:target emiter:emt keypath:keypath op:op context:nil];
}


-(instancetype)initWithTarget:(NSObject *)target
                       emiter:(id<IRxEmitter>)emt
                      keypath:(NSString*)keypath
                           op:(NSKeyValueObservingOptions)op
                      context:(void*)context{
    self = [super init];
    //RxLog(@"GCObjectObserver init 1:%@",self);
    if(context==nil){
        _context = (__bridge void *)self;
    }else{
        _context = context;
    }
    //RxLog(@"GCObjectObserver init 2");
    self.keypath = keypath;
    self.weakTarget = target;
    self.isDetached = NO;
    //RxLog(@"GCObjectObserver init 3");
    self.unsafeTarget = target;
    //self.pointTarget = [NSValue valueWithPointer:(__bridge void*)target];
    self.emitter = emt;
    self.op =op;
    //RxLog(@"GCObjectObserver init 4");
    [[_GCKVOObserver instance] addObs:self];
    [target _gc_addObserver:[_GCKVOObserver instance] forKeyPath:keypath options:op context:_context];
    RXWEAKDECL(ws)
    [target rx_observeDealloc].subcribe(^(id obj){
        //RxLog(@">>>rx_observeDealloc obj:%p isDetach:%d weak:%d self:%@",obj,self.isDetached,self.weakTarget==nil,ws);
        [ws detach];
    });
    //RxLog(@"GCObjectObserver init:%@ target:%@",self,target);
    return self;
}
-(void)detach{
    @synchronized (self) {
        @try {
            if(self.isDetached){
                return;
            }
            self.isDetached = YES;
            [[_GCKVOObserver instance] removeObs:self];
            if(self.weakTarget!=nil){//这里如果weak==nil还remove就会崩溃
                [self.unsafeTarget _gc_removeObserver:[_GCKVOObserver instance] forKeyPath:self.keypath context:_context];
            }
        }@catch (NSException *e){
            //RxLog(@"detach excp msg:%@",e.reason);
        }
    }
}
-(void)dealloc{
    //RxLog(@"GCObjectObserver dealloc:%@",self);
}

-(void)observeValueForKeyPath:(nullable NSString *)keyPath
                     ofObject:(nullable id)object
                       change:(nullable NSDictionary<NSKeyValueChangeKey, id> *)change
                      context:(nullable void *)context {
    //RxLog(@"GCObjectObserver observeValueForKeyPath:%@",keyPath);
    if(_emitter!=nil){
        RXObserveObject* obj = [RXObserveObject new];
        obj.context = [NSValue valueWithPointer:context];
        obj.keypath = keyPath;
        obj.targetObject = object;
        obj.values = change;
        [_emitter onNext:obj];
    }
}
@end



@interface _GC_KVO_SWIZZLE_INFO:NSObject
@property (strong, nonatomic) id<IRxSubscription> sub;
@property (weak, nonatomic) NSObject *observer;
@property (weak, nonatomic) NSObject *weakSelf;
@property (strong, nonatomic) NSString *keypath;
@property (strong, nonatomic) NSValue* context;
@end
@implementation _GC_KVO_SWIZZLE_INFO
@end

@implementation RXKVOHelper
+(instancetype)instance {
    static RXKVOHelper* ins=nil;
    @synchronized (self) {
        if(ins==nil){
            ins = [RXKVOHelper new];
            ins.rx_enableKVOSwizzle = NO;
        }
    }
    return ins;
}
-(void)checkKVO{
    [[_GCKVOObserver instance] checkKVO];
}
@end


@implementation NSObject(Rx)
+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [RxRunTimeUtil swizzleClazzMethod:[NSObject class] ori:@selector(addObserver:forKeyPath:options:context:)
                                    dst:@selector(_gc_addObserver:forKeyPath:options:context:)];
        [RxRunTimeUtil swizzleClazzMethod:[NSObject class] ori:@selector(removeObserver:forKeyPath:)
                                    dst:@selector(_gc_removeObserver:forKeyPath:)];
        [RxRunTimeUtil swizzleClazzMethod:[NSObject class] ori:@selector(removeObserver:forKeyPath:context:)
                                    dst:@selector(_gc_removeObserver:forKeyPath:context:)];
    });
}
-(BOOL)obsFilter:(NSObject *)observer{
    if([observer isKindOfClass:[_GCKVOObserver class]]){
        //如果self类的kvo接口里面迭代调用，那么会再次进入交换后的实现里面,好像不太好判断这种情形，先过滤_GCKVOObserver的使用
        //RxLog(@">>>>obsFilter _GCKVOObserver self:%@  call:%@",self,[NSThread callStackSymbols]);
        return YES;
    }
//    NSString *obsClazz = NSStringFromClass([observer class]);
//    NSString *selfClazz = NSStringFromClass([self class]);
//
//    if([observer isKindOfClass:NSClassFromString(@"MyBaseLayout")]){
//        return NO;
//    }
//    RxLog(@">>>>selfClazz:%@ obsClazz:%@",selfClazz,obsClazz);

    return ![RXKVOHelper instance].rx_enableKVOSwizzle;
}

-(NSMutableArray *)gc_subsArray{
    @synchronized (self) {
        NSMutableArray *kvoSubs = [RxRunTimeUtil getExtraObj:self key:_cmd];
        if(kvoSubs==nil){
            kvoSubs = [NSMutableArray new];
            [RxRunTimeUtil attachExtraObj:self key:_cmd obj:kvoSubs mode:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
        }
        return kvoSubs;
    }

}
-(_GC_KVO_SWIZZLE_INFO*)gc_find_kvo_info:(NSObject *)observer keypath:(NSString*)keypath context:(void *)context{
    @synchronized (self) {
        NSMutableArray<_GC_KVO_SWIZZLE_INFO*> * susArrays = [self gc_subsArray];
        for(NSUInteger i=0;i<susArrays.count;i++) {
            _GC_KVO_SWIZZLE_INFO* info = susArrays[i];
            if(info.observer==nil){
                [info.sub unsubscribe];
                [susArrays removeObjectAtIndex:i];
                i--;
                continue;
            }
            if(     info.observer == observer &&
                    info.context.pointerValue == context &&
                    [info.keypath isEqualToString:keypath]){
                return info;
            }
        }
        return nil;
    }
}
-(void)add_kvo_subscription:(id<IRxSubscription>)subs observer:(NSObject *)observer keypath:(NSString*)keypath context:(void *)context{
    @synchronized (self) {
        _GC_KVO_SWIZZLE_INFO* info = [self gc_find_kvo_info:observer keypath:keypath context:context];
        if(info==nil){
             info =[_GC_KVO_SWIZZLE_INFO new];
             info.keypath = keypath;
             info.observer = observer;
             info.weakSelf = self;
             info.context = [NSValue valueWithPointer:context];
            info.sub = subs;
            [[self gc_subsArray] addObject:info];
        }
    }
}
-(void)remove_kvo_observe:(NSObject *)observer keypath:(NSString*)keypath context:(void *)context{
    @synchronized (self) {
        _GC_KVO_SWIZZLE_INFO* info = [self gc_find_kvo_info:observer keypath:keypath context:context];
        if(info){
            [info.sub unsubscribe];
            [[self gc_subsArray] removeObject:info];
        }
    }
}
- (void)_gc_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context{
    if([self obsFilter:observer]){
         [self _gc_addObserver:observer forKeyPath:keyPath options:options context:context];
         return;
    }
    keyPath = [keyPath copy];
    if([self gc_find_kvo_info:observer keypath:keyPath context:context]){
        return;
    }
    //RxLog(@"_gc_addObserver:%@",self);
    RXWEAKDECLWITH(wsObs, observer)
    RXWEAKDECL(ws)
    //RxLog(@"_gc_addObserver:%@",self);
    id<IRxSubscription> sub = [self rx_observeOnKey:keyPath option:options context:context]
            .subcribeAutoClean(^(RXObserveObject* obj){
                //RxLog(@"change:%@ keypath:%@,%@",obj.values,obj.keypath,keyPath);
                [wsObs observeValueForKeyPath:keyPath
                                     ofObject:ws
                                       change:obj.values
                                      context:obj.context==nil?nil:obj.context.pointerValue];
            },observer);//subcribeAutoClean支持在observer释放的时候自动unsubscribe
//    [observer rx_observeDealloc].subcribe(^(id obj){//这个很重要,监听者释放的时候，自动注销
//        [ws remove_kvo_observe:obj keypath:keyPath context:context];
//    });
    [self add_kvo_subscription:sub observer:observer keypath:keyPath context:context];
}
- (void)_gc_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context{
    if([self obsFilter:observer]){
        [self _gc_removeObserver:observer forKeyPath:keyPath context:context];
        return;
    }
    [self remove_kvo_observe:observer keypath:keyPath context:context];

}
- (void)_gc_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath{
     if([self obsFilter:observer]){
         [self _gc_removeObserver:observer forKeyPath:keyPath];
         return;
     }
    [self remove_kvo_observe:observer keypath:keyPath context:nil];
}


static NSMutableSet *swizzledClasses() {
    static dispatch_once_t onceToken;
    static NSMutableSet *swizzledClasses = nil;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [[NSMutableSet alloc] init];
    });

    return swizzledClasses;
}
static void swizzleDeallocIfNeeded(Class classToSwizzle) {
    @synchronized (swizzledClasses()) {
        NSString *className = NSStringFromClass(classToSwizzle);
        if ([swizzledClasses() containsObject:className]) {
            //RxLog(@">>>containsObject:%@",className);
            return;
        }
        //RxLog(@">>>>swizzleDeallocIfNeeded class:%@ ", classToSwizzle);
        SEL deallocSelector = sel_registerName("dealloc");
        __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;
        id newDealloc = ^(__unsafe_unretained id self) {
            //RxLog(@">>>>dealloc:%@ %p", object_getClass(self),self);
           [self performSelector:@selector(notifyDeallocEmitters)];//释放信号
            //objc_msgSend(self,@selector(notifyDeallocEmitters));
            //RxLog(@">>>>notifyDeallocEmitters class:%@", classToSwizzle);
            if (originalDealloc == NULL) {//类没有实现dealloc的话，应该调用父类的dealloc
                struct objc_super superInfo = {
                        .receiver = self,
                        .super_class = class_getSuperclass(classToSwizzle)
                };
                void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
                msgSend(&superInfo, deallocSelector);
            } else {
                //RxLog(@"===originalDealloc before:%@===",classToSwizzle);
                originalDealloc(self, deallocSelector);
                //RxLog(@"===originalDealloc after:%@===",classToSwizzle);
            }
        };
        IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);//用block生成一个新的实现，这样可以避免父类子类都hook的时候用同一个实现会出现问题
        if (!class_addMethod(classToSwizzle, deallocSelector, newDeallocIMP, "v@:")) {//如果该类没有实现dealloc函数，这里就能添加成功
            // The class already contains a method implementation.
            Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);
            // We need to store original implementation before setting new implementation
            // in case method is called at the time of setting.
            originalDealloc = (__typeof__(originalDealloc))method_getImplementation(deallocMethod);//获取到此类本来的实现
            // We need to store original implementation again, in case it just changed.
            originalDealloc = (__typeof__(originalDealloc))method_setImplementation(deallocMethod, newDeallocIMP);//设置为新实现
        }
        [swizzledClasses() addObject:className];
    }
}

-(RxOC*)rx_observeDealloc{
    @synchronized (self) {
        swizzleDeallocIfNeeded(object_getClass(self));
        RXWEAKDECL(ws)
        return [RxOC create:^(id<IRxEmitter> emitter){
            if(ws==nil){
                [emitter onError:[NSException exceptionWithName:@"ObsOrObjReleasedException" reason:@"observer或者object已经释放" userInfo:nil]];
                return;
            }
            [ws attachDeallocEmitter:emitter];
        }];
    }
}

-(RxOC*)rx_observeOnKey:(NSString *)key{
    return [self rx_observeOnKey:key option:NSKeyValueObservingOptionNew];
}
-(RxOC*)rx_observeOldNewOnKey:(NSString *)key{
    return [self rx_observeOnKey:key option:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld];
}
-(RxOC*)rx_observeOnKey:(NSString *)key option:(NSKeyValueObservingOptions)option{
    return [self rx_observeOnKey:key option:option context:nil];
}
-(RxOC*)rx_observeOnKey:(NSString *)key option:(NSKeyValueObservingOptions)option context:(void*)ct{
    RXWEAKSELF_DECLARE
    return [RxOC createWithDispose:^(id<IRxEmitter> emitter){
        //RxLog(@"gc_observeOnKey source1");
        if(weakself == nil){
            [emitter onError:[NSException exceptionWithName:@"ObsOrObjReleasedException" reason:@"observer或者object已经释放" userInfo:nil]];
            return(void(^)(void))nil;
        }
        GCObjectObserver* obs =[[GCObjectObserver alloc] initWithTarget:weakself emiter:emitter keypath:key op:option context:ct];
        RXWEAKDECLWITH(wsObs, obs)
        return ^(){
            [wsObs detach];
        };
    }];
}
-(RxOC*)rx_observeOnKey:(NSString *)key autoClean:(NSObject*)obj{
    return [self rx_observeOnKey:key option:NSKeyValueObservingOptionNew autoClean:obj];
}
-(RxOC*)rx_observeOldNewOnKey:(NSString *)key autoClean:(NSObject*)obj{
    return [self rx_observeOnKey:key option:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld autoClean:obj];
}
-(RxOC*)rx_observeOnKey:(NSString *)key option:(NSKeyValueObservingOptions)option autoClean:(NSObject*)obj{
    @synchronized (self) {
        RXWEAKSELF_DECLARE
        __weak NSObject* weakAutoClean = obj;
        return [RxOC createWithDispose:^(id<IRxEmitter> emitter){
            //RxLog(@"gc_observeOnKey source1");
            if(weakself == nil){
                [emitter onError:[NSException exceptionWithName:@"ObsOrObjReleasedException" reason:@"observer或者object已经释放" userInfo:nil]];
                return(void(^)(void))nil;
            }
            GCObjectObserver* obs =[[GCObjectObserver alloc] initWithTarget:weakself emiter:emitter keypath:key op:option context:nil];
            RXWEAKDECLWITH(wsObs, obs)
            if(weakAutoClean){
                [weakAutoClean rx_observeDealloc].subcribe(^(id obj){
                    [wsObs detach];
                });
            }
            return ^(){
                [wsObs detach];
            };
        }];
    }
}
static pthread_mutex_t dealloc_emitter_mutex =PTHREAD_MUTEX_INITIALIZER;

-(void)attachDeallocEmitter:(id<IRxEmitter>)emitter{
    pthread_mutex_lock(&dealloc_emitter_mutex);
    [[self deallocEmitters] addObject:emitter];
    pthread_mutex_unlock(&dealloc_emitter_mutex);
}
-(void)notifyDeallocEmitters{
    pthread_mutex_lock(&dealloc_emitter_mutex);
    NSMutableArray *arr = [self newDeallocArrayIfNotExist:YES];
    if(arr==nil){
        pthread_mutex_unlock(&dealloc_emitter_mutex);
        return;
    }
    for(int i =0;i<arr.count;i++){
        id<IRxEmitter> em = arr[i];
        [em onNext:self];
        [em onComplete];
    }
    [arr removeAllObjects];
    pthread_mutex_unlock(&dealloc_emitter_mutex);
}
-(NSMutableArray*)newDeallocArrayIfNotExist:(BOOL)justGet{
    NSMutableArray *arr = [RxRunTimeUtil getExtraObj:self key:_cmd];
    if(justGet){
        return arr;
    }
    if(arr==nil){
        arr = [NSMutableArray new];
        [RxRunTimeUtil attachExtraObj:self key:_cmd obj:arr mode:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
    }
    return arr;
}

-(NSMutableArray *)deallocEmitters{
   return [self newDeallocArrayIfNotExist:NO];
}

//-(BOOL)rx_enableKVOSwizzle {
//    NSNumber *enable = [RunTimeUtil getExtraObj:self key:_cmd];
//    if(enable==nil){
//        return YES;
//    }
//    return enable.boolValue;
//}
//-(void)setRx_enableKVOSwizzle:(BOOL)enable{
//    [self willChangeValueForKey:@"rx_enableKVOSwizzle"];
//    [RunTimeUtil attachExtraObj:self key:@selector(rx_enableKVOSwizzle) obj:@(enable)
//                           mode:OBJC_ASSOCIATION_RETAIN_NONATOMIC];
//    [self didChangeValueForKey:@"rx_enableKVOSwizzle"];
//}
//IMP_CATEGORY_PROPERTY_STRONG_NONATOMIC(NSMutableArray *, gcObserverArr, setGcObserverArr);
@end
