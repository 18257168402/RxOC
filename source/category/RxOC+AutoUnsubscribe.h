//
//  RxOC+AutoUnsubscribe.h
//  easylib
//
//  Created by 黎书胜 on 2018/1/20.
//  Copyright © 2018年 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RxOC.h"

typedef id<IRxSubscription> (^AutoCleanRxOnNext)(ConsumerOnNext next,NSObject *cleanOnDealloc);
typedef id<IRxSubscription> (^AutoCleanRxOnTryError)(ConsumerOnNext next,ConsumerOnError error,NSObject *cleanOnDealloc);
typedef id<IRxSubscription> (^AutoCleanRxOnTryTagError)(ConsumerOnNext next,ConsumerOnTagError error,NSObject *cleanOnDealloc);
typedef id<IRxSubscription> (^AutoCleanRxOnTryLife)(ConsumerOnNext next,ConsumerOnError error,ConsumerOnComplete complete,NSObject *cleanOnDealloc);
typedef id<IRxSubscription> (^AutoCleanRxOnTryTagLife)(ConsumerOnNext next,ConsumerOnTagError error,ConsumerOnComplete complete,NSObject *cleanOnDealloc);

@interface RxOC(AutoUnsubscribe)
@property (readonly) AutoCleanRxOnNext subcribeAutoClean;
@property (readonly) AutoCleanRxOnTryError subcribeTryErrAutoClean;
@property (readonly) AutoCleanRxOnTryTagError subcribeTryTagErrAutoClean;
@property (readonly) AutoCleanRxOnTryLife subcribeTryLifeAutoClean;
@property (readonly) AutoCleanRxOnTryTagLife subcribeTryTagLifeAutoClean;
@end
