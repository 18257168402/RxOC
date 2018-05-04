//
//  ProxyUtil.h
//  guard
//
//  Created by 黎书胜 on 2017/11/20.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger,RxEncodeType){
    EncodeCharType = 1,//char
    EncodeIntType,//int
    EncodeShortType,//short
    EncodeLongType,//long
    EncodeLongLongType,//long long
    EncodeUCharType,//unsigned char
    EncodeUIntType,//unsigned int
    EncodeUShortType,//unsigned short
    EncodeULongType,//unsigned long
    EncodeULongLongType,//unsigned long long
    EncodeFloatType,//float
    EncodeDoubleType,//double
    EncodeBoolType,//bool
    EncodeVoidType,//void

    EncodeCCharStrType,//char*

    EncodeIdType,//id类型 （所有NSObject*类型）
    EncodeBlockType,//block类型
    EncodeClassType,//class类型（isa类型）

    EncodeSELType,//selector类型

    EncodeArrayType,//数组类型 例如int intarr[4]={1,2,3,4}; @encode(typeof(intarr))
    EncodeStructType,//结构体类型
    EncodeUnionType,//联合体类型

    EncodePointerType,//指针类型
    EncodeFuncType,//函数指针类型
    EncodeMultiPointerType,//多重指针类型

    EncodeUnKnownType
};

typedef union _RxValue{
    BOOL B;
    char c;
    int i;
    short s;
    long l;
    long long q;
    float f;
    double d;
    unsigned char C;
    unsigned short S;
    unsigned int I;
    unsigned long L;
    unsigned long long Q;
    void* p;
}RxValue;

@interface RxProxyMem:NSObject
{
@public
    void* _addr;
    RxValue _value;
    BOOL needFreeValuePoint;
}
@end


@interface RxEncodeTypeUtil:NSObject
/**
 将Type encode转换成EncodeType Enum
 比如 \@encode(int) --> EncodeIntType
 int intArr[3] = {1,2,3}
     \@encode(typeof(intArr))---->EncodeArrayType
 typedef void (*Func)()
     \@encode(Func)  ---> EncodeFuncType
 
 **/
+(RxEncodeType)getEncodeType:(const char*)code;
@end


/**
 实现一个对象的动态代理，对对象持有弱引用，当引用为空的时候，发送给代理的消息将不被处理
 **/
//返回值代表是否进行拦截，返回true的话不会讲selector转发给target
typedef BOOL (^RxInvokeBeforeIntercept)(NSObject *target,SEL sel,NSInvocation *invocation);
typedef void (^RxInvokeAfterIntercept)(NSObject *target,SEL sel,NSInvocation *invocation);
/**
 * 替代一个调用,
 * 参数returnValue为返回值
 * 分几种情况
 * 1 基本数据类型int char short long float double用NSNumber封装
 * 2 结构体,联合体,基本数据类型数组,结构体数组，联合体数组 用NSValue封装
 *          (函数是[NSValue value:&v withObjCType:@ encode(struct MyStru)])
 *          int intarr[4]={1,2,3,4}; --->[NSValue value:&intarr withObjCType:@ encode(intarr)]
 * 3 指针类型用NSValue封装 [NSValue valueWithPointer:@selector(doDefaultAction:)]
 * 4 OC对象直接写入
 * 5 如果已经自己写了invocation的returnValue，可不设置返回值到returnValue
 */
typedef void (^RxInvokeReplace)(NSObject* target,SEL sel,NSInvocation* invocation,id* returnValue);
//如果有返回值，请将返回值- (void)setReturnValue:(void *)retLoc;

@interface RxEasyProxy:NSProxy
+(id)newWeakProxy:(NSObject*)target;
+(id)newStrongProxy:(NSObject*)target;
+(id)newProtoProxy:(NSString*)proto;
/**
 *
 * @param selectors selecotor列表，注意是string列表 使用 NSStringFromSelector(sel)转化
 * @param intercept 拦截器，决定是否拦截
 */
-(void)setInterceptBeforeInvoke:(NSArray *)selectors intercept:(RxInvokeBeforeIntercept)intercept;
-(void)setInterceptAfterInvoke:(NSArray *)selectors intercept:(RxInvokeAfterIntercept)intercept;
-(void)setReplaceInvoke:(NSArray *)selectors intercept:(RxInvokeReplace)replace;


@property(weak,nonatomic) NSObject* weakTarget;
@property (strong, nonatomic)NSObject *strongTraget;
@property (strong, nonatomic)Protocol * protoTraget;
@property (strong, nonatomic)id blockTarget;
@property (assign, nonatomic)NSUInteger proxyType;//1 weak 2 strong 3 clazz 4 block

@property (strong, nonatomic)NSArray *beforeSelectors;
@property (strong, nonatomic)NSArray *afterSelectors;
@property (strong, nonatomic)RxInvokeBeforeIntercept beforeIntercept;
@property (strong, nonatomic)RxInvokeAfterIntercept afterIntercept;

@property (strong, nonatomic)NSArray *replaceSelectors;
@property (strong, nonatomic)RxInvokeReplace replaceInvoke;
@end


@interface ChainImpItem:NSObject
+(instancetype)makeWithTarget:(NSObject*)target;
-(void)setInterceptBeforeInvoke:(NSArray *)selectors intercept:(RxInvokeBeforeIntercept)intercept;
-(void)setInterceptAfterInvoke:(NSArray *)selectors intercept:(RxInvokeAfterIntercept)intercept;
@property (strong, nonatomic)NSObject *target;
@property (strong, nonatomic)NSArray *beforeSelectors;
@property (strong, nonatomic)NSArray *afterSelectors;
@property (strong, nonatomic)RxInvokeBeforeIntercept beforeIntercept;
@property (strong, nonatomic)RxInvokeAfterIntercept afterIntercept;
@end

/**
 * 将发送给ChainProxy的selector消息，转发到impChain实现
 * 比如有一个proto A,A有四个接口需要实现，头两个接口是ChainImpItem1实现的后两个是ChainImpItem2实现的
 * 那么，这里只要把ChainImpItem1 ChainImpItem2数组作为实现的chain就好了
 * 注意chain的前面的对象对方法有更高的执行优先级
 */
@interface ChainProxy:NSProxy
+(instancetype)  newStrongChainProxy:(NSArray<ChainImpItem*> *)impChain;
@property (strong, nonatomic) NSArray<ChainImpItem*> *chain;
@end


@interface InvokeUtil:NSObject
/*
 参数必须传入参数地址，然后强转成void*类型，最后一个参数传nil
 比如如果一个函数的原型是 -(NSString*)func:(int)p1 str:(NSString*)p2;
 那么要这样调用
 int p1=100;
 NSString* p2 = @"321313";
 NSString* ret=(NSString*)[InvokeUtil invoke:target selector:selector args:(void*)&p1,(void*)&p2,nil];

 也就是说，如果是基本数据类型，如 int short... 以及struct这种，都是传入地址值
 而OC对象类型，也是取其地址值


 返回一个id，也就是说，如果函数的返回值是一个数字(int short ...)那么会转换成NSNumber
 如果是一个OC对象(NSObject Class Block)，会直接返回
 如果是一个结构体，那么返回NSValue，需要使用其getValue函数拿到具体的值
 其他类型，返回NSValue
 */
+(id)invoke:(id)target selector:(SEL)seletor args:(void*)arg,...NS_REQUIRES_NIL_TERMINATION;
+(id)invoke:(id)target selector:(SEL)seletor firstArg:(void*)arg arglist:(va_list)list;
+(id)invoke:(id)target selector:(SEL)seletor arglist:(va_list)list;

/**
 *
 * 1 参数类型必须都是id
 * 2 有多少个参数，argArr长度就必须是多长，也就是说每个参数都必须有
 * 3 如果有参数为空，那么使用[NSNull null]占位
 */
+(id)invoke:(id)target selector:(SEL)seletor argsList:(NSArray *)argArr;//参数都是id类型


+(id)invokeBlock:(id)block argsList:(NSArray *)argArr;

/**
 *
 *
 * @return
 * int short char float double...等基本值用KQProxyMem封装
 * id block class直接返回
 *如果参数或者返回值有struct union或者基本类型跟struct union等类型的数组类型的话，会直接返回错误
 *
 */
+(BOOL)checkBlockInvokeable:(id)block;
+(NSArray *)packBlockArgToId:(id)block args:(va_list)list;
+(id)invokeBlock:(id)block args:(va_list)list error:(NSError**)err invocation:(NSInvocation **)invo;
@end

