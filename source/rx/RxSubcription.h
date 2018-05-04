//
// Created by 黎书胜 on 2017/11/24.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RxEmitter.h"
#import "RxThreadUtil.h"
@interface RxSubscription:NSObject<IRxSubscription>
{
    __weak RxScheduleEmitter* _scheduler;
    __weak TaskHandle* _handle;

}
-(id)initWithSchedulersAndTaskHandle:(RxScheduleEmitter*)scheduler taskhandle:(TaskHandle*)handle;
@end
