//
// Created by 黎书胜 on 2017/11/27.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RxDefs.h"
#import "RxEmitter.h"
@class RxOC;
@class RxOCTransform;
@class RxRuntime;
/**
 * RxOCSource是事件源，一个RxOC只有一个事件源对象，当然事件源的事件可能是由多个其他事件源组成的
 */

@interface RxOCSource:NSObject
@property (strong, nonatomic) id<EmitterComposite> emitter;
-(void)run:(RxRuntime *)runtime;
@end

@interface RxEventSource : RxOCSource
-(instancetype)initWithRx:(RxOC*)rx source:(RxSource)rxSource;
@property (weak, nonatomic) RxOC* rx;
@property (strong, nonatomic) RxSource source;
@end

@interface RxDisposeEventSource : RxOCSource
-(instancetype)initWithRx:(RxOC*)rx source:(RxDisposeSource)rxSource;
@property (weak, nonatomic) RxOC* rx;
@property (strong, nonatomic) RxDisposeSource source;
@end

@interface RxTransFormSource: RxOCSource
-(instancetype)initWithRx:(RxOC*)rx trans:(RxOCTransform*)rxTrans;
@property (weak, nonatomic) RxOC* rx;
@property (strong, nonatomic) RxOCTransform* trans;
@end
