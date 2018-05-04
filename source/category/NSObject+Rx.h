//
//  NSObject+HLCategory.h
//  guard
//
//  Created by 黎书胜 on 2017/10/25.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>


@class RxOC;

@interface RXKVOHelper:NSObject
+(instancetype)instance;
@property (assign, nonatomic) BOOL rx_enableKVOSwizzle;//置为YES的时候，会swizzle所有的kvo变成Rx实现，可以自动注销
-(void)checkKVO;
@end

@interface RXObserveObject:NSObject
@property (strong, nonatomic) NSString *keypath;
@property (strong, nonatomic) id targetObject;
@property (strong, nonatomic) NSValue* context;
@property (strong, nonatomic)  NSDictionary<NSKeyValueChangeKey, id> *values;
@end

@interface NSObject(Rx)
//@property (strong, nonatomic)NSMutableArray *gcObserverArr;

@property (strong, atomic, readonly)NSMutableArray* deallocEmitters;

-(RxOC*)rx_observeDealloc;//回调可能多次，并且这个时候所有weak的引用已经置空了，onNext可以接收这个对象

//如果RxOC启动，那么，RxOC对象的清除要延迟到self的释放,如果使用subscribeAutoClean或者主动unsubscribe则可自动或手动清除
-(RxOC*)rx_observeOnKey:(NSString *)key;
-(RxOC*)rx_observeOldNewOnKey:(NSString *)key;
-(RxOC*)rx_observeOnKey:(NSString *)key option:(NSKeyValueObservingOptions)option;
-(RxOC*)rx_observeOnKey:(NSString *)key option:(NSKeyValueObservingOptions)option context:(void*)ct;

//RxOC启动，如果指定了autoClean对象，那么在obj释放的时候就会清除这个RxOC对象
//如果self为autoClean对象的子孙对象，并且self的引用仅仅被autoClean及其子对象持有，则指定autoClean并无意义
//因为这个时候self会在autoClean清除之前被清除

//以下接口建议不用，用上面几个接口，不过使用subscribeAutoClean接口启动就可以
-(RxOC*)rx_observeOnKey:(NSString *)key autoClean:(NSObject*)obj;
-(RxOC*)rx_observeOldNewOnKey:(NSString *)key autoClean:(NSObject*)obj;
-(RxOC*)rx_observeOnKey:(NSString *)key option:(NSKeyValueObservingOptions)option autoClean:(NSObject*)obj;

- (void)_gc_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;
- (void)_gc_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(nullable void *)context;
- (void)_gc_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;
@end

#define RXObserve(obj,key) [obj rx_observeOnKey:[NSString stringWithCString:#key]]
#define RXObserveOp(obj,key,op) [obj rx_observeOnKey:[NSString stringWithCString:#key option:op]]
