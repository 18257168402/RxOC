//
//  RxOC+AutoUnsubscribe.m
//  easylib
//
//  Created by 黎书胜 on 2018/1/20.
//  Copyright © 2018年 黎书胜. All rights reserved.
//

#import "RxOC+AutoUnsubscribe.h"

#import "NSObject+Rx.h"
@implementation RxOC(AutoUnsubscrib)
-(AutoCleanRxOnNext)subcribeAutoClean{
    return ^(ConsumerOnNext next,NSObject *cleanOnDealloc){
        id<IRxSubscription> sub = self.subcribe(next);
        [cleanOnDealloc rx_observeDealloc]
                .subcribe(^(id obj){
                    [sub unsubscribe];
                });
      return sub;
    };
}
-(AutoCleanRxOnTryError)subcribeTryErrAutoClean{
    return ^(ConsumerOnNext next,ConsumerOnError error,NSObject *cleanOnDealloc){
        id<IRxSubscription> sub = self.subcribeTryErr(next,error);
        [cleanOnDealloc rx_observeDealloc]
                .subcribe(^(id obj){
                    [sub unsubscribe];
                });
        return sub;
    };
}
-(AutoCleanRxOnTryTagError)subcribeTryTagErrAutoClean{
    return ^(ConsumerOnNext next,ConsumerOnTagError error,NSObject *cleanOnDealloc){
        id<IRxSubscription> sub = self.subcribeTryTagErr(next,error);
        [cleanOnDealloc rx_observeDealloc]
                .subcribe(^(id obj){
                    [sub unsubscribe];
                });
        return sub;
    };
}
-(AutoCleanRxOnTryLife)subcribeTryLifeAutoClean{
    return ^(ConsumerOnNext next,ConsumerOnError error,ConsumerOnComplete complete,NSObject *cleanOnDealloc){
        id<IRxSubscription> sub = self.subcribeTryLife(next,error,complete);
        [cleanOnDealloc rx_observeDealloc]
                .subcribe(^(id obj){
                    [sub unsubscribe];
                });
        return sub;
    };
}
-(AutoCleanRxOnTryTagLife)subcribeTryTagLifeAutoClean{
    return ^(ConsumerOnNext next,ConsumerOnTagError error,ConsumerOnComplete complete,NSObject *cleanOnDealloc){
        id<IRxSubscription> sub = self.subcribeTryTagLife(next,error,complete);
        [cleanOnDealloc rx_observeDealloc]
                .subcribe(^(id obj){
                    [sub unsubscribe];
                });
        return sub;
    };
}
@end
