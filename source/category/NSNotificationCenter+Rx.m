//
//  NSNotificationCenter+HLCategory.m
//  easylib
//
//  Created by 黎书胜 on 2018/1/8.
//  Copyright © 2018年 黎书胜. All rights reserved.
//

#import "NSNotificationCenter+Rx.h"
#import "RxOC.h"
#import "RxRunTimeUtil.h"
#import "NSObject+Rx.h"
@interface GCMyNotificationObserver:NSObject
@property (strong, nonatomic) id<IRxEmitter> emitter;
@end
@implementation GCMyNotificationObserver
-(instancetype)init{
    self = [super init];
   // EasyLog(@"GCMyNotificationObserver init:%@",self);
    return self;
}
-(void)dealloc{
   // EasyLog(@"GCMyNotificationObserver dealloc:%@",self);
}
-(void)onNotification:(NSNotification *)note{
    if(self.emitter){
        [self.emitter onNext:note];
    }
}
@end
@implementation NSNotificationCenter(Rx)
-(RxOC*)rx_observeNotificationForName:(NSString *)notificationName object:(id)object{
    RXWEAKSELF_DECLARE
    return [RxOC createWithDispose:^(id<IRxEmitter> emitter){
        GCMyNotificationObserver* observer = [GCMyNotificationObserver new];
        if(weakself.gcObserverArr==nil){
            weakself.gcObserverArr = [NSMutableArray new];
        }
        [weakself.gcObserverArr addObject:observer];
        observer.emitter = emitter;
        [weakself addObserver:observer selector:@selector(onNotification:) name:notificationName object:object];
        __weak GCMyNotificationObserver* weakObser = observer;
        return ^(){
            [weakself removeObserver:weakObser];
            [weakself.gcObserverArr removeObject:weakObser];
        };
    }];
}
-(RxOC*)rx_observeNotificationForName:(NSString *)notificationName object:(id)object autoClean:(NSObject*)obj{
    RXWEAKSELF_DECLARE
    __weak NSObject* weakAutoClean=obj;
    return [RxOC createWithDispose:^(id<IRxEmitter> emitter){
        if(weakAutoClean== nil){
            return (void(^)(void))nil;//如果清除器已经被释放，则不再监听
        }
        GCMyNotificationObserver* observer = [GCMyNotificationObserver new];
        if(weakself.gcObserverArr==nil){
            weakself.gcObserverArr = [NSMutableArray new];
        }
        [weakself.gcObserverArr addObject:observer];
        observer.emitter = emitter;
        [weakself addObserver:observer selector:@selector(onNotification:) name:notificationName object:object];
        __weak GCMyNotificationObserver* weakObser = observer;
        [weakAutoClean rx_observeDealloc]
                .subcribe(^(id obj){
                    if(weakself){//weakAutoClean生命周期可能比weakself更长
                        [weakself removeObserver:weakObser];
                        [weakself.gcObserverArr removeObject:weakObser];
                    }
                });
        return ^(){
            [weakself removeObserver:weakObser];
            [weakself.gcObserverArr removeObject:weakObser];
        };
    }];
}
RXIMP_CATEGORY_PROPERTY_STRONG_NONATOMIC(NSMutableArray *, gcObserverArr, setGcObserverArr);
@end
