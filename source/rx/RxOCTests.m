//
// Created by 黎书胜 on 2017/11/27.
// Copyright (c) 2017 黎书胜. All rights reserved.
//

#import "RxOCTests.h"
#import "RxOC.h"
#import "RxThreadUtil.h"
@implementation RxOCTests
+(void)testMapAndFlatMap{
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            //RxLogT(@"RxOC", @"==run1 %@",emitter);
            [emitter onNext:@"123456"];
            [emitter onComplete];
        } after:3000];

    }]
            .tag(1)
            .map(^(NSString *from){
                return @"654321";
            }).tag(2)
            .flatmap(^(NSString *from){
                return [RxOC create:^(id<IRxEmitter> e){
                    [RxThreadUtil runOnBackground:^(){
                        //RxLogT(@"RxOC", @"==run3");
                        [e onNext:@"11111"];
                        [e onComplete];
                    } after:3000];
                }];
            }).tag(3)
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                [NSThread sleepForTimeInterval:2];
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d excep:%@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}

+(void)testDoAfterAndBefore{
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            //RxLogT(@"RxOC", @"==run1 %@",emitter);
            [emitter onNext:@"123456"];
            [emitter onError:[[NSException alloc] initWithName:@"ffdf" reason:@"kkkkkk" userInfo:nil]];
        } after:3000];

    }]
            .tag(1)
            .map(^(NSString *from){
                return @"654321";
            }).tag(2)
            .flatmap(^(NSString *from){
                return [RxOC create:^(id<IRxEmitter> e){
                    [RxThreadUtil runOnBackground:^(){
                        //RxLogT(@"RxOC", @"==run3");
                        [e onNext:@"11111"];
                    } after:3000];
                }];
            }).tag(3)
            .doOnNext(^(NSString *value){
                RxLogT(@"RxOCTest",@"doOnNext:%@",value);
            })
            .doAfterNext(^(NSString *value){
                RxLogT(@"RxOCTest",@"doAfterNext:%@",value);
            })
            .doOnError(^(NSException *value){
                RxLogT(@"RxOCTest",@"doOnError:%@",value.reason);
            })
            .doAfterError(^(NSException *value){
                RxLogT(@"RxOCTest",@"doAfterError:%@",value.reason);
            })
            .compose(CommonIORxTrans)
            .subcribeTryTagErr(^(NSString *str){
                [NSThread sleepForTimeInterval:2];
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d",tag);
            });
}


+(void)testonErrorResumeNext{
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            //RxLogT(@"RxOC", @"==run1 %@",emitter);
            [emitter onNext:@"123456"];
            [emitter onError:[[NSException alloc] initWithName:@"ffdf" reason:@"kkkkkk" userInfo:nil]];
        } after:3000];

    }]
            .tag(1)
            .map(^(NSString *from){
                return @"654321";
            }).tag(2)
            .flatmap(^(NSString *from){
                return [RxOC create:^(id<IRxEmitter> e){
                    [RxThreadUtil runOnBackground:^(){
                        //RxLogT(@"RxOC", @"==run3");
                        [e onNext:@"11111"];
                    } after:3000];
                }];
            }).tag(3)
            .onErrorResumeNext(^(NSException *err){
                return [RxOC create:^(id<IRxEmitter> emitter){
                    [emitter onNext:@"from error resume!!"];
                    [emitter onError:[[NSException alloc] initWithName:@"ffdf" reason:@"from error resume!!" userInfo:nil]];
                    [emitter onComplete];
                }].tag(4);
            })
            .doOnNext(^(NSString *value){
                RxLogT(@"RxOCTest",@"doOnNext:%@",value);
            })
            .doAfterNext(^(NSString *value){
                RxLogT(@"RxOCTest",@"doAfterNext:%@",value);
            })
            .doOnError(^(NSException *value){
                RxLogT(@"RxOCTest",@"doOnError:%@",value.reason);
            })
            .doAfterError(^(NSException *value){
                RxLogT(@"RxOCTest",@"doAfterError:%@",value.reason);
            })
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                [NSThread sleepForTimeInterval:2];
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d excep:%@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}


+(void)testOnErrorReturn{
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            RxLogT(@"RxOC", @"==onNext 1");
            [emitter onNext:@"onNext 1"];
            RxLogT(@"RxOC", @"==onNext 2");
            [emitter onNext:@"onNext 2"];
            RxLogT(@"RxOC", @"==onError");
            [emitter onError:[[NSException alloc] initWithName:@"testOnErrorReturn" reason:@"error from begin!" userInfo:nil]];
        } after:3000];

    }]
            .tag(1)
            .map(^(NSString *from){
                RxLogT(@"RxOC", @"==map from:%@",from);
                return [NSString stringWithFormat:@"map:%@",from];
            }).tag(2)
            .flatmap(^(NSString *from){
                return [RxOC create:^(id<IRxEmitter> e){
                    [RxThreadUtil runOnBackground:^(){
                        RxLogT(@"RxOC", @"==flatmap from:%@",from);
                        [e onNext:[NSString stringWithFormat:@"flatmap:%@",from]];
                    } after:3000];
                }];
            }).tag(3)
            .onErrorReturn(^(NSException *from){
                RxLogT(@"RxOCTest",@"error accoured:%@",from.reason);
                return @"return from onErrorReturn!!";
            })
            .doOnNext(^(NSString *value){
                RxLogT(@"RxOCTest",@"doOnNext:%@",value);
            })
            .doAfterNext(^(NSString *value){
                RxLogT(@"RxOCTest",@"doAfterNext:%@",value);
            })
            .doOnError(^(NSException *value){
                RxLogT(@"RxOCTest",@"doOnError:%@",value.reason);
            })
            .doAfterError(^(NSException *value){
                RxLogT(@"RxOCTest",@"doAfterError:%@",value.reason);
            })
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                [NSThread sleepForTimeInterval:2];
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d excep:%@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}

+(void)testRetry{
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            RxLogT(@"RxOC", @"==onNext 1");
            [emitter onNext:@"onNext 1"];
            RxLogT(@"RxOC", @"==onNext 2");
            [emitter onNext:@"onNext 2"];
            RxLogT(@"RxOC", @"==onError");
            [emitter onError:[[NSException alloc] initWithName:@"testOnErrorReturn" reason:@"error from begin!" userInfo:nil]];
        } after:3000];
    }].map(^(NSString * from){
                return [NSString stringWithFormat:@"map from:%@",from];
            }).retry(3)
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d excep:%@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}
+(void)testRetryIf{
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            RxLogT(@"RxOC", @"==onNext 1");
            [emitter onNext:@"onNext 1"];
            RxLogT(@"RxOC", @"==onNext 2");
            [emitter onNext:@"onNext 2"];
            RxLogT(@"RxOC", @"==onError");
            [emitter onError:[[NSException alloc] initWithName:@"testOnErrorReturn" reason:@"error from begin!" userInfo:nil]];
        } after:3000];
    }].map(^(NSString * from){
                return [NSString stringWithFormat:@"map from:%@",from];
            }).retryIf(^(int retryed,NSException *e){
                if(retryed<2){
                    return YES;
                }else{
                    return NO;
                }
            })
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d excep:%@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}

+(void)testRetryWhen{
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            RxLogT(@"RxOC", @"==onNext 1");
            [emitter onNext:@"onNext 1"];
            RxLogT(@"RxOC", @"==onNext 2");
            [emitter onNext:@"onNext 2"];
            RxLogT(@"RxOC", @"==onError");
            [emitter onError:[[NSException alloc] initWithName:@"testOnErrorReturn" reason:@"error from begin!" userInfo:nil]];
        } after:3000];
    }].map(^(NSString * from){
                return [NSString stringWithFormat:@"map from:%@",from];
            })
            .retryWhen(^(int retryed,NSException *e){
                return [RxOC create:^(id<IRxEmitter> emitter){
                    [RxThreadUtil runOnBackground:^(){
                        if(retryed<2){
                            [emitter onNext:@(retryed)];
                        } else{
                            [emitter onError:e];
                        }
                    } after:1000];
                }];
            })
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d excep:%@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}

+(RxOC*)zipOC{
    return  [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            [emitter onNext:@"zip 1"];
            [NSThread sleepForTimeInterval:2];
            [emitter onNext:@"zip 2"];
            [NSThread sleepForTimeInterval:2];
            [emitter onNext:@"zip 3"];
            [NSThread sleepForTimeInterval:2];
            [emitter onNext:@"zip 4"];
            [NSThread sleepForTimeInterval:2];
            [emitter onComplete];
        } after:2000];
    }];
}

+(void)testZipWith{
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            [emitter onNext:@"onNext 1"];
            [NSThread sleepForTimeInterval:1];
            [emitter onNext:@"onNext 2"];
            [NSThread sleepForTimeInterval:1];
            [emitter onNext:@"onNext 3"];
            [NSThread sleepForTimeInterval:10];
            [emitter onNext:@"onNext 4"];
            [NSThread sleepForTimeInterval:1];
            [emitter onComplete];
        } after:1000];
    }].zipWith([self zipOC],^(id from,id rhFrom){
        return [NSString stringWithFormat:@"%@+%@",from,rhFrom];
    }) .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d excep:%@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}

+(void)testZipWithError{
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            [emitter onNext:@"onNext 1"];
            [emitter onError:[NSException exceptionWithName:@"zipException" reason:@"zip exceptino!!" userInfo:nil]];
        } after:1000];
    }].tag(1)
            .zipWith([self zipOC].tag(2),^(id from,id rhFrom){
                return [NSString stringWithFormat:@"%@+%@",from,rhFrom];
            }).tag(3)
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d exception:%@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}


+(void)testCombine{
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            [emitter onNext:@"onNext 1"];
            [emitter onComplete];
        } after:3000];
    }].combineLatest([self zipOC],^(id from,id rhFrom){
                return [NSString stringWithFormat:@"%@+%@",from,rhFrom];
            }) .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d excep:%@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}
+(void)testMerge{
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            [emitter onNext:@"onNext 1"];
            [NSThread sleepForTimeInterval:1];
            [emitter onNext:@"onNext 2"];
            [emitter onError:[NSException exceptionWithName:@"mergeExcp" reason:@"mergeError" userInfo:nil]];
            [NSThread sleepForTimeInterval:1];
            [emitter onNext:@"onNext 3"];
            [NSThread sleepForTimeInterval:1];
            [emitter onNext:@"onNext 4"];
            [NSThread sleepForTimeInterval:1];
            [emitter onComplete];
        } after:1000];
    }].mergeWith([self zipOC])
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d %@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}
+(void)testMergeErrorDelay {
    [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            [emitter onNext:@"onNext 1"];
            [NSThread sleepForTimeInterval:1];
            [emitter onNext:@"onNext 2"];
            [emitter onError:[NSException exceptionWithName:@"mergeExcp" reason:@"mergeError" userInfo:nil]];
            [NSThread sleepForTimeInterval:1];
            [emitter onNext:@"onNext 3"];
            [NSThread sleepForTimeInterval:1];
            [emitter onNext:@"onNext 4"];
            [NSThread sleepForTimeInterval:1];
            [emitter onComplete];
        } after:1000];
    }].mergeWithDelayError([self zipOC],^(NSException *e1,NSException *e2){
                return [NSException exceptionWithName:@"mergeDelayError" reason:@"mergeDelayError exception" userInfo:nil];
            })
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d %@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}
+(void)testFilter{
    [RxOC create:^(id<IRxEmitter> emitter){
        [emitter onNext:@(1)];
        [emitter onNext:@(2)];
        [emitter onNext:@(3)];
        [emitter onNext:@(4)];
        [emitter onNext:@(5)];
        [emitter onComplete];
    }].filter(^(NSNumber *num){
                return (BOOL)(num.intValue%2==0);
    }).filter(^(NSNumber *num){
                RxLog(@"====filter num:%@",num);
                return (BOOL)(num.intValue==2);
            })
            .map(^(NSNumber *num){
                return @(num.intValue+100);
            })
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSNumber *num){
                RxLogT(@"OCTest",@">>num:%@",num);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d %@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
}

+(void)testInterval{
    RxOC* interval = [RxOC interval:1 repeat:10 isMainThread:NO];
    id<IRxSubscription> subscription = interval
            .clean(^(){},^(NSException *e){
                RxLogT(@"OCTest",@">>clean:%@",e);
            })
            .map(^(NSNumber *num){
                return @(num.intValue+100);
            })
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSNumber *num){
                RxLogT(@"OCTest",@">>testInterval:%@",num);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d %@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
    [RxThreadUtil runOnBackground:^(){
        interval.
        doOnNext(^(NSNumber *num){
            RxLogT(@"OCTest",@">>interval_1 doOnNext_1:%@",num);
        }).doOnNext(^(NSNumber *num){
            RxLogT(@"OCTest",@">>interval_1 doOnNext_2:%@",num);
        }).map(^(NSNumber *num){
            return [NSString stringWithFormat:@"interval str:%@",num];
        }).subcribeTryTagLife(^(NSNumber *num){
            RxLogT(@"OCTest",@">>testInterval_1:%@",num);
        },^(NSException *excep,int tag){
            RxLogT(@"OCTest",@">>tag_1:%d %@",tag,excep);
        },^(){
            RxLogT(@"OCTest",@">>onComplete_1");
        });
    } after:4000];
    [RxThreadUtil runOnBackground:^(){
        RxLogT(@"OCTest",@">>unsubscribe:%@",subscription);
        [subscription unsubscribe];
    } after:6000];
}

+(void)testThreadMode{
   [RxOC create:^(id<IRxEmitter> emitter){
         RxLogT(@"OCTest",@"rxoc1 thread:%@",[NSThread currentThread]);
       [RxThreadUtil runOnBackground:^(){
           [emitter onNext:@"onNext 1"];
           [emitter onComplete];
       }];
   }].subcribeOn(ScheduleOnIO).observeOn(ScheduleOnMain)
    .subcribeTryTagLife(^(NSString *str){
                RxLogT(@"OCTest",@">>testThreadMode:%@",[NSThread currentThread]);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d %@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });

}

+(void)testClean{
   id<IRxSubscription> sub= [RxOC create:^(id<IRxEmitter> emitter){
        [RxThreadUtil runOnBackground:^(){
            [emitter onNext:@"onNext 1"];
            [NSThread sleepForTimeInterval:1];
            [emitter onNext:@"onNext 2"];
            [NSThread sleepForTimeInterval:1];
            [emitter onNext:@"onNext 3"];
            [NSThread sleepForTimeInterval:10];
            [emitter onNext:@"onNext 4"];
            [NSThread sleepForTimeInterval:1];
            [emitter onComplete];
        } after:1000];
    }]
           .clean(^(){
                RxLog(@"clean source onComplete");
            },^(NSException *e){})

            .zipWith([self zipOC].clean(^(){
                RxLog(@"clean zip onComplete");
            },^(NSException *e){}),^(id from,id rhFrom){
                return [NSString stringWithFormat:@"%@+%@",from,rhFrom];
            })
            .compose(CommonIORxTrans)
            .subcribeTryTagLife(^(NSString *str){
                RxLogT(@"OCTest",@">>str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>tag:%d excep:%@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>onComplete");
            });
    [RxThreadUtil runOnBackground:^(){
        [sub unsubscribe];
    } after:7000];
}

+(void)testMultiCall{
    RxOC *zip=[self zipOC];
            zip.doAfterNext(^(NSString *from){
                RxLogT(@"OCTest",@">>doAfterNext1:%@",from);
            }).doAfterNext(^(NSString *from){
                RxLogT(@"OCTest",@">>doAfterNext2:%@",from);
            }).subcribeTryTagLife(^(NSString *str){
                RxLogT(@"OCTest",@">>subcribe 1 str:%@",str);
            },^(NSException *excep,int tag){
                RxLogT(@"OCTest",@">>subcribe 1 tag:%d excep:%@",tag,excep);
            },^(){
                RxLogT(@"OCTest",@">>subcribe 1 onComplete");
            });
    zip.doAfterNext(^(NSString *from){
        RxLogT(@"OCTest",@">>doAfterNext3:%@",from);
    }).subcribeTryTagLife(^(NSString *str){
        RxLogT(@"OCTest",@">>subcribe 2 str:%@",str);
    },^(NSException *excep,int tag){
        RxLogT(@"OCTest",@">>subcribe 2 tag:%d excep:%@",tag,excep);
    },^(){
        RxLogT(@"OCTest",@">>subcribe 2 onComplete");
    });
}

@end





