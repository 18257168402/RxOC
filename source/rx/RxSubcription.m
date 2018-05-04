//
// Created by 黎书胜 on 2017/11/24.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import "RxSubcription.h"


/*------------------------------------------*/
@implementation RxSubscription
-(id)initWithSchedulersAndTaskHandle:(RxScheduleEmitter*)scheduler taskhandle:(TaskHandle*)handle{
    self=[super init];
    self->_scheduler = scheduler;
    self->_handle = handle;
    return self;
}
-(void)unsubscribe{
    if(_handle!=nil){
        [_handle invalidate];
    }
    if(_scheduler!=nil){
        _scheduler.cancelled = YES;
        [_scheduler onError:[NSException exceptionWithName:@"UnsubscribeException" reason:@"unsubscribed" userInfo:nil]];
    }
}
-(void)breakStream{
    [self unsubscribe];
}
@end