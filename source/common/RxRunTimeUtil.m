//
//  RxRunTimeUtil.m
//  guard
//
//  Created by 黎书胜 on 2017/10/31.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#import "RxRunTimeUtil.h"
#import "RxOCCommonDefs.h"

@implementation RxRunTimeUtil

+(void)attachExtraObj:(NSObject*)target key:(void*)key obj:(id)obj mode:(objc_AssociationPolicy)policy{
    objc_setAssociatedObject(target, key, obj, policy);
}
+(id)getExtraObj:(NSObject*)target key:(void*)key{
   return  objc_getAssociatedObject(target, key);
}
//+(void)swizzleDeallockMethod:(Class)_class dst:(SEL)dstSelector{
//    Method originMethod = class_getInstanceMethod(_class, sel_getUid("dealloc"));
//    Method dstMethod = class_getInstanceMethod(_class, dstSelector);
//    if(originMethod == NULL || dstMethod == NULL){
//        EasyLog(@"==swizzleClazzMethod error,must swizzle two exist method==");
//        return;
//    }
//    IMP originIMP = method_getImplementation(originMethod);
//    IMP dstIMP = method_getImplementation(dstMethod);
//    BOOL add = class_addMethod(_class, sel_getUid("dealloc"), dstIMP, method_getTypeEncoding(dstMethod));
//    if (add) {
//        //如果添加成功，那么覆盖dstSelector-dstIMP为 dstSelector-oriIMP
//        class_replaceMethod(_class, dstSelector, originIMP, method_getTypeEncoding(originMethod));
//    } else {
//        //如果添加失败，那么说明origin-oriIMP已存在，则交换ori和dst的实现
//        method_exchangeImplementations(originMethod, dstMethod);
//    }
//}

+(void)swizzleClazzMethod:(Class)_class ori:(SEL)originSelector dst:(SEL)dstSelector{
    /**
     * class_getInstanceMethod会从本类寻找方法实现，如果找不到，会找父类的对应实现
     **/
    Method originMethod = class_getInstanceMethod(_class, originSelector);
    Method dstMethod = class_getInstanceMethod(_class, dstSelector);
    /**
     * 只有两个方法的实现都是存在的才能交换，否则不可交换
     **/
    if(originMethod == NULL || dstMethod == NULL){
        //EasyLog(@"==swizzleClazzMethod error,must swizzle two exist method==");
        return;
    }
    IMP originIMP = method_getImplementation(originMethod);
    IMP dstIMP = method_getImplementation(dstMethod);
    /**
     * 添加这一步适用于当前类没有方法实现的时候才会成功，
     * 如果父类有实现而当前类没有实现，那么这一步会成功
     *
     * 也就是说，如果交换子类实现，不会影响父类
     * 比如
     * super ori_sel -> ori_imp
     * self  NULL
     * self dst_sel ->dst_imp
     * 那么交换后变成
     * super ori_sel -> ori_imp //父类不受影响
     * self  ori_sel -> dst_imp
     * self  dst_sel -> ori_imp
     *
     * 如果交换父类实现，不会影响子类实现
     * self ori_sel -> ori_imp_self
     * sub  ori_sel -> ori_imp_sub
     * self dst_sel -> dst_imp
     * 交换后变成
     * self ori_sel -> dst_imp
     * sub  ori_sel -> ori_imp_sub //子类不受影响
     * self dst_sel -> ori_imp_self
     **/
    //首先添加，如果origin-oriIMP不存在，那么这里吧origin-dstIMP加上
    BOOL add = class_addMethod(_class, originSelector, dstIMP, method_getTypeEncoding(dstMethod));
    if (add) {
        //如果添加成功，那么覆盖dstSelector-dstIMP为 dstSelector-oriIMP
        class_replaceMethod(_class, dstSelector, originIMP, method_getTypeEncoding(originMethod));
    } else {
        //如果添加失败，那么说明origin-oriIMP已存在，则交换ori和dst的实现
        method_exchangeImplementations(originMethod, dstMethod);
    }
}
+(void)swizzleMethod:(NSObject*)target ori:(SEL)originSelector dst:(SEL)dstSelector{
    Class _class = [target class];
    [self swizzleClazzMethod:_class ori:originSelector dst:dstSelector];
}
@end
