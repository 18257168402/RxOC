//
//  RxWeakWrapper.m
//  guard
//
//  Created by 黎书胜 on 2017/10/27.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#import "RxWeakWrapper.h"

@implementation RxWeakWrapper
-(id)initWithObj:(id)ref{
    self = [super init];
    self.ref = ref;
    self.refClass = NSStringFromClass([ref class]);
    self.unsafeRef = [NSValue valueWithPointer:(__bridge void*)ref];
    return self;
}
@end
