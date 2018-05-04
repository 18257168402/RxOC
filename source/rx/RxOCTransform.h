//
// Created by 黎书胜 on 2017/11/27.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RxEmitter.h"
@class RxOC;


/**
 * RxOCTransform 属于RxSource的一种，也就是事件源，
 * 不过他是的事件由上游RxOC产生，然后经过某些转换之后作为自己的事件发送
 */
@interface RxOCTransform:NSObject
@property (strong, nonatomic) RxOC* up;
@property (weak, nonatomic)   RxOC* rx;

- (void)run:(RxRuntime *)runtime;
@end

/**
 * RxMapOCTransform将上游的onNext产生的数据通过RxTrans转换后发送
 */
@interface RxMapOCTransform : RxOCTransform
@property (strong, nonatomic) RxTrans trans;
@end

/**
 * RxFlatMapOCTransform将上游的onNext产生的数据通过RxFlatTrans转换后形成一个新的RxOC
 * 然后再将新的RxOC的事件作为自己的事件发送
 */
@interface RxFlatMapOCTransform : RxOCTransform
@property (strong, nonatomic) RxFlatTrans trans;
@end

@interface RxZipTransform:RxOCTransform
@property (strong, nonatomic) RxOC *rh;
@property (strong, nonatomic) RxZip zipFunc;
@end

@interface RxCombineLastTransform:RxZipTransform
@end

@interface RxMergeTransform:RxOCTransform
@property (strong, nonatomic) RxOC *rh;
@end

@interface RxMergeWithDelayErrorTransform:RxMergeTransform
@property (strong, nonatomic) RxMergeError mergeFunc;
@end

@interface RxIntervalTimerTransform:RxOCTransform<OnScheduleBeCancled>
@property (assign, nonatomic) NSTimeInterval sec;
@property (assign, nonatomic) int repeat;
@property (assign, nonatomic) BOOL isMain;
@property (assign, nonatomic) BOOL isHot;
@end