//
// Created by 黎书胜 on 2017/11/30.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import "RxRuntime.h"
#import "RxInnerDefs.h"

@implementation RxRuntime

-(instancetype)initWithRx:(RxOC *)rx{
    self = [super init];
    self.rx = rx;
    self.tagId = rx.tagId;
    self.tagOverideId = rx.tagOverideId;
    if(rx.cleanOnComplete!=nil){
        self.cleanOnComplete = [[NSMutableArray alloc] initWithArray:rx.cleanOnComplete];
    }
    if(rx.cleanOnError!=nil){
        self.cleanOnError = [[NSMutableArray alloc] initWithArray:rx.cleanOnError];
    }
    if(rx.consumerBeforeOnNext!=nil){
        self.consumerBeforeOnNext = [[NSMutableArray alloc] initWithArray:rx.consumerBeforeOnNext];
    }
    if(rx.consumerAfterOnNext!=nil){
        self.consumerAfterOnNext = [[NSMutableArray alloc] initWithArray:rx.consumerAfterOnNext];
    }
    if(rx.consumerBeforeOnError!=nil){
        self.consumerBeforeOnError = [[NSMutableArray alloc] initWithArray:rx.consumerBeforeOnError];
    }
    if(rx.consumerAfterOnError!=nil){
        self.consumerAfterOnError = [[NSMutableArray alloc] initWithArray:rx.consumerAfterOnError];
    }
    if(rx.consumerOnSubscribe!=nil){
        self.consumerOnSubscribe = [[NSMutableArray alloc] initWithArray:rx.consumerOnSubscribe];
    }
    if(rx.consumerBeforeOnComplete){
        self.consumerBeforeOnComplete = [[NSMutableArray alloc] initWithArray:rx.consumerBeforeOnComplete];
    }
    if(rx.consumerAfterOnComplete){
        self.consumerAfterOnComplete = [[NSMutableArray alloc] initWithArray:rx.consumerAfterOnComplete];
    }
    self.sourceMode = rx.sourceMode;
    self.dstMode = rx.dstMode;
    self.rxErrResume = rx.rxErrResume;
    self.rxErrReturn = rx.rxErrReturn;
    self.rxRetryIf = rx.rxRetryIf;
    self.rxRetryWhen = rx.rxRetryWhen;
    self.rxFilter = rx.rxFilter;

    self.retryCount = rx.retryCount;
    self.retryedCount = 0;

    self.runtimeObjects = [NSMutableDictionary new];

    self.mergeErrorCount = 0;
    self.mergeCompleteCount = 0;
    //RxLogT(RXTAG,@"RxRuntime init:%@",self);
    return self;
}
-(void)dealloc{
    //RxLogT(RXTAG,@"RxRuntime dealloc:%@",self);
}
-(void)addRuntimeObject:(NSString *)key obj:(id)obj{
    @synchronized (self) {
        self.runtimeObjects[key] = obj;
    }

}
//-(void)appendRxPath:(NSString *)path{
//    if(self.rootRuntime.rxPath==nil){
//        self.rootRuntime.rxPath = path;
//    }else{
//        self.rootRuntime.rxPath = [self.rootRuntime.rxPath stringByAppendingFormat:@"%@",path];
//    }
//}
-(id)getRuntimeObject:(NSString *)key{
    @synchronized (self) {
        return self.runtimeObjects[key];
    }
}
@end