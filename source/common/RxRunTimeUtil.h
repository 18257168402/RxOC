//
//  RxRunTimeUtil.h
//  guard
//
//  Created by 黎书胜 on 2017/10/31.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "RxWeakWrapper.h"
//以下是cotegory的property实现宏


#define RXIMP_CATEGORY_PROPERTY_STRONG_NONATOMIC(TYPE,GETTER,SETTER) -(TYPE)GETTER{\
    return [RxRunTimeUtil getExtraObj:self key:_cmd];\
}\
-(void)SETTER:(TYPE)extraobj{\
    [self willChangeValueForKey:[NSString stringWithCString:#GETTER]];\
    [RxRunTimeUtil attachExtraObj:self key:@selector(GETTER) obj:extraobj mode:OBJC_ASSOCIATION_RETAIN_NONATOMIC];\
    [self didChangeValueForKey:[NSString stringWithCString:#GETTER]];\
}

@interface RxRunTimeUtil : NSObject
//使用associate可以在category里面给一个类附加成员变量(伪实现)
//mode决定了obj的引用方式
+(void)attachExtraObj:(NSObject*)target key:(void*)key obj:(id)obj mode:(objc_AssociationPolicy)policy;
+(id)getExtraObj:(NSObject*)target key:(void*)key;
+(void)swizzleMethod:(NSObject*)target ori:(SEL)originSelector dst:(SEL)dstSelector;
+(void)swizzleClazzMethod:(Class)target ori:(SEL)originSelector dst:(SEL)dstSelector;
//+(void)swizzleDeallockMethod:(Class)target dst:(SEL)dstSelector;//dealloc不可使用swizzle
@end
