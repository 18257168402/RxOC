#ifndef __RX_INNER_REFS__H
#define __RX_INNER_REFS__H
#import "RxDefs.h"
#import "RxThreadUtil.h"
#import "RxRunTimeUtil.h"
#import "RxScheduler.h"
@class RxOCSource;
@class RxOCTransform;
@class RxSourceEmitter;
@class RxScheduleEmitter;


@interface RxOC()
+(instancetype)createWithUpstream:(RxOCTransform *)transform;


@property (assign, nonatomic)  ScheduleMode sourceMode;
@property (assign, nonatomic)  ScheduleMode dstMode;
@property (strong, nonatomic)  RxErrResume rxErrResume;
@property (strong, nonatomic)  RxErrReturn rxErrReturn;
@property (strong, nonatomic)  RxRetryIf rxRetryIf;
@property (strong, nonatomic)  RxRetryWhen rxRetryWhen;
@property (strong, nonatomic)  RxFilter rxFilter;

@property (assign, nonatomic)  int tagId;
@property (assign, nonatomic)  int tagOverideId;
@property (assign, nonatomic)  int retryCount;
@property (strong, nonatomic)  NSMutableArray<RxCleanOnComplete>* cleanOnComplete;
@property (strong, nonatomic)  NSMutableArray<RxCleanOnError>*    cleanOnError;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnNext>*    consumerBeforeOnNext;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnNext>*    consumerAfterOnNext;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnError>*   consumerBeforeOnError;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnError>*   consumerAfterOnError;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnComplete>*   consumerBeforeOnComplete;
@property (strong, nonatomic)  NSMutableArray<ConsumerOnComplete>*   consumerAfterOnComplete;
@property (strong, nonatomic)  NSMutableArray<ComsumerOnSubscribe>*  consumerOnSubscribe;

@property (strong, nonatomic)  NSString *name;
@property (strong, nonatomic)  RxOCSource* source;

-(id<IRxSubscription>)__retry:(ConsumerOnNext)next error:(ConsumerOnError)err complete:(ConsumerOnComplete)comp
             downEmitterChain:(RxSourceEmitter*)enmitterChain retryed:(int)retryedcount;
-(id<IRxSubscription>)__subcribe:(ConsumerOnNext)next error:(ConsumerOnError)err complete:(ConsumerOnComplete)comp
                downEmitterChain:(RxSourceEmitter*)enmitterChain;
@end

//#define RXOC_WEAK_DECLEARE __weak typeof(self) weakself=self;
#define RXOC_WEAK_DECLEARE typeof(self) weakself=self;

#define  RXTAG @"OC"

extern int key_of_tagid;
#endif
