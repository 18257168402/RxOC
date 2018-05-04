//
// Created by 黎书胜 on 2017/11/24.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import "RxScheduler.h"

TaskHandle* schedule_inmode(dispatch_block_t block,ScheduleMode _mode){
    if(_mode == ScheduleOnCur){
        block();
        return nil;
    }else if(_mode == ScheduleOnMain){
        return [RxThreadUtil runOnMainThread:block];
    }else if(_mode == ScheduleOnIO){
        return [RxThreadUtil runOnBackground:block];
    }
    return nil;
}