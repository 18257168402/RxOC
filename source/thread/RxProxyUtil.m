///Users/lishusheng/Desktop/workspace/guard/guard.xcodeproj
//  ProxyUtil.m
//  guard
//
//  Created by 黎书胜 on 2017/11/20.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#import <objc/runtime.h>
#import <CoreData/CoreData.h>
#import "RxProxyUtil.h"
#import "NSInvocation+RxBlock.h"
#import "RxOCCommonDefs.h"
#import "NSMethodSignature+RxBlock.h"

@interface PlaceObj:NSObject
@end
@implementation PlaceObj
@end
@interface MyBool:NSObject{
@public
    BOOL boolValue;
}

@end
@implementation MyBool
@end

@interface MyMem:NSObject{
@public
    void* memAddr;
}
@end
@implementation MyMem
-(instancetype)init{
    self = [super init];
    memAddr = 0;
    return self;
}
-(void)dealloc{
    //EasyLog(@"==MyMem dealloc:%d",memAddr);
    if(memAddr!=0){
        free(memAddr);
    }
}
@end



@implementation RxProxyMem
-(instancetype)init{
    self = [super init];
    _addr = &_value;
    memset(&_value, 0, sizeof(_value));
    needFreeValuePoint = NO;
    return self;
}
-(void)dealloc{
    if(needFreeValuePoint&&_value.p!=NULL){
        free(_value.p);
    }
}
@end



@interface RxEasyProxy()
@property (strong, nonatomic) PlaceObj* placeObj;
@end

@implementation RxEasyProxy
-(NSString *)description {
    return [NSString stringWithFormat:@"<class:%@ weaktarget:%@ strongtarget:%@>",
                    [self class],self.weakTarget,self.strongTraget];
}
+(id)newWeakProxy:(NSObject*)target{
    RxEasyProxy* proxy = [RxEasyProxy alloc];
    proxy.weakTarget = target;
    proxy.proxyType = 1;
    return proxy;
}
+(id)newStrongProxy:(NSObject*)target{
    RxEasyProxy* proxy = [RxEasyProxy alloc];
    proxy.strongTraget = target;
    proxy.proxyType = 2;
    return proxy;
}
+(id)newProtoProxy:(NSString *)proto{
    RxEasyProxy* proxy = [RxEasyProxy alloc];
    proxy.protoTraget = NSProtocolFromString(proto);
    proxy.proxyType = 3;
    proxy.placeObj = [PlaceObj new];
    if(![proxy.placeObj conformsToProtocol:proxy.protoTraget]){
        class_addProtocol([PlaceObj class], proxy.protoTraget);
    }
    return proxy;
}

-(void)setInterceptBeforeInvoke:(NSArray *)selectors intercept:(RxInvokeBeforeIntercept)intercept{
    self.beforeSelectors = selectors;
    self.beforeIntercept = intercept;
}
-(void)setInterceptAfterInvoke:(NSArray *)selectors intercept:(RxInvokeAfterIntercept)intercept{
    self.afterSelectors = selectors;
    self.afterIntercept = intercept;
}
-(void)setReplaceInvoke:(NSArray *)selectors intercept:(RxInvokeReplace)replace{
    self.replaceSelectors = selectors;
    self.replaceInvoke = replace;
}
-(NSMethodSignature*) methodSignatureForSelector:(SEL)sel {
    //NSLog(@"===methodSignatureForSelector:%@", NSStringFromSelector(sel));
    if (self.proxyType==1) {
        if (self.weakTarget == nil) {//不能返回nil,否则会直接认为找不到相应的IMP而崩溃
            return [NSMethodSignature signatureWithObjCTypes:"@@:iiiiiiiiiiiiiiiiiiiii"];
            //构造一个假的NSMethodSignature，使用的是TypeEncode 格式为 返回值+参数类型
            //这里返回值类型是@也就是id类型，因为IMP的第一个参数必定是id 第二个参数必定是SEL，所以后面跟着@:
            //后面的i都是占位，用int类型的TypeEncode占位，也就是说被代理的方法的参数数量超过21个，还是可能崩溃
        }
        return [self.weakTarget methodSignatureForSelector:sel];
    }else  if (self.proxyType==2){
        return [self.strongTraget methodSignatureForSelector:sel];
    }else  if (self.proxyType==3){
        NSMethodSignature* sig = [[PlaceObj class] instanceMethodSignatureForSelector:sel];
        //NSLog(@"===sig:%@", sig);
        return sig;
    }
    return nil;
}


-(BOOL)callBeforeIntercept:(SEL)sel{
    if(self.beforeIntercept!=nil &&self.beforeSelectors!=nil &&self.beforeSelectors.count>0){
        for (int i = 0; i < self.beforeSelectors.count; ++i) {
            NSString *selStr = self.beforeSelectors[i];
            SEL curSel = NSSelectorFromString(selStr);
            if(curSel == sel){
                return YES;
            }
        }
    }
    return NO;
}
-(BOOL)callReplaceIntercept:(SEL)sel{
    if(self.replaceInvoke!=nil &&self.replaceSelectors!=nil &&self.replaceSelectors.count>0){
        for (int i = 0; i < self.replaceSelectors.count; ++i) {
            NSString *selStr = self.replaceSelectors[i];
            SEL curSel = NSSelectorFromString(selStr);
            if(curSel == sel){
                return YES;
            }
        }
    }
    return NO;
}
-(BOOL)callAfterIntercept:(SEL)sel{
    if(self.afterIntercept!=nil &&self.afterSelectors!=nil &&self.afterSelectors.count>0){
        for (int i = 0; i < self.afterSelectors.count; ++i) {
            NSString *selStr = self.afterSelectors[i];
            SEL curSel = NSSelectorFromString(selStr);
            if(curSel == sel){
               return YES;
            }
        }
    }
    return NO;
}
-(void)replaceReturnValueAtInvocation:(NSInvocation *)invocation value:(id)value{
    if(value == nil){
        return;
    }
    NSMethodSignature *sig = invocation.methodSignature;
    if([value isKindOfClass:[NSNull class]]){
        return;
    }
    RxEncodeType retType = [RxEncodeTypeUtil getEncodeType:invocation.methodSignature.methodReturnType];
    if(     retType == EncodeIdType ||
            retType == EncodeBlockType ||
            retType == EncodeClassType){
        [invocation setReturnValue:&value];
        return;
    }
    if([value isKindOfClass:[NSValue class]]){
        NSValue* v = value;
        void* mem = malloc(sig.methodReturnLength);
        __autoreleasing MyMem* mymem = [MyMem new];
        [v getValue:mem size:sig.methodReturnLength];
        mymem->memAddr =mem;
        [invocation setReturnValue:mem];
        return;
    }
    [invocation setReturnValue:&value];
}
-(void)forwardInvocation:(NSInvocation *)invocation{
    NSString *selectorName = NSStringFromSelector(invocation.selector);
    //NSLog(@"===forwardInvocation selectorName:%@ %ld %ld===",selectorName,invocation.methodSignature.numberOfArguments,invocation.methodSignature.frameLength);
    NSObject* target = nil;
    if(self.proxyType == 1){
        target = self.weakTarget;
        if(target == nil){
            return;
        }
    }else if(self.proxyType == 2){
        target = self.strongTraget;
    }else if(self.proxyType == 3){
        target = self.placeObj;
    }
    if(invocation.methodSignature!=nil){
        NSObject* obj = target;
        BOOL haveBeforeIntercept = [self callBeforeIntercept:invocation.selector];
        BOOL haveReplaceIntercept = [self callReplaceIntercept:invocation.selector];
        BOOL haveAfterIntercept = [self callAfterIntercept:invocation.selector];
        if(self.proxyType == 3){
            if([selectorName isEqualToString:@"respondsToSelector:"]){
                SEL sel = nil;
                [invocation getArgument:&sel atIndex:2];
                //NSLog(@"respondsToSelector target:%@ %d", NSStringFromSelector(sel), invocation.methodSignature.numberOfArguments);
                BOOL haveBeforeTarget = [self callBeforeIntercept:sel];
                BOOL haveReplaceTarget = [self callReplaceIntercept:sel];
                BOOL haveAfterTarget = [self callAfterIntercept:sel];
                if(haveBeforeTarget||haveReplaceTarget||haveAfterTarget){
                    __autoreleasing MyBool* gcBool = [MyBool new];//利用一下自动释放池，否则这个值不好释放
                    gcBool->boolValue = YES;
                    [invocation setReturnValue:&gcBool->boolValue];
                    return;
                }
            }
        }

        BOOL needIntercept = NO;//询问是否需要拦截
        if(haveBeforeIntercept){
            needIntercept = self.beforeIntercept(obj,invocation.selector,invocation);
        }
        if(!needIntercept){
            if(haveReplaceIntercept){
                id ret =nil;
                self.replaceInvoke(obj,invocation.selector,invocation,&ret);
                [self replaceReturnValueAtInvocation:invocation value:ret];
            }else{
                if(obj!=nil && [obj respondsToSelector:invocation.selector]){
                    [invocation invokeWithTarget:obj];
                }
            }
            void* res = nil;//要用的时候转换回正确类型的值
            if(invocation.methodSignature.methodReturnLength!=0){
                [invocation getReturnValue:&res];
            }
        }
        if(haveAfterIntercept){
            self.afterIntercept(obj,invocation.selector,invocation);
        }
    }else{
        //NSLog(@"===forwardInvocation target = nil ===");
    }
}
@end


@implementation ChainImpItem
+(instancetype)makeWithTarget:(NSObject*)target{
    ChainImpItem* item = [ChainImpItem new];
    item.target = target;
    return item;
}
-(void)setInterceptBeforeInvoke:(NSArray *)selectors intercept:(RxInvokeBeforeIntercept)intercept{
    self.beforeSelectors = selectors;
    self.beforeIntercept = intercept;
}
-(void)setInterceptAfterInvoke:(NSArray *)selectors intercept:(RxInvokeAfterIntercept)intercept{
    self.afterSelectors = selectors;
    self.afterIntercept = intercept;
}
-(NSMethodSignature*) methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}
-(void)forwardInvocation:(NSInvocation *)invocation{
    if(self.target!=nil && invocation.methodSignature!=nil){
        NSObject* obj = self.target;
        if([obj respondsToSelector:invocation.selector]){
            BOOL needIntercept = NO;
            if(self.beforeIntercept!=nil &&self.beforeSelectors!=nil &&self.beforeSelectors.count>0){
                for (int i = 0; i < self.beforeSelectors.count; ++i) {
                    NSString *selStr = self.beforeSelectors[i];
                    SEL curSel = NSSelectorFromString(selStr);
                    if(curSel == invocation.selector){
                        needIntercept = self.beforeIntercept(obj,curSel,invocation);
                        break;
                    }
                }
            }
            if(!needIntercept){
                [invocation invokeWithTarget:obj];
                void* res = nil;//要用的时候转换回正确类型的值
                if(invocation.methodSignature.methodReturnLength!=0){
                    [invocation getReturnValue:&res];
                }
            }
            if(self.afterIntercept!=nil &&self.afterSelectors!=nil &&self.afterSelectors.count>0){
                for (int i = 0; i < self.afterSelectors.count; ++i) {
                    NSString *selStr = self.afterSelectors[i];
                    SEL curSel = NSSelectorFromString(selStr);
                    if(curSel == invocation.selector){
                        self.afterIntercept(obj,curSel,invocation);
                        break;
                    }
                }
            }
        }
    }
}
@end

@interface ChainProxy()
{
    ChainImpItem* selectedItem;
}
@end
@implementation ChainProxy
+(instancetype)  newStrongChainProxy:(NSArray<ChainImpItem*> *)impChain{
    ChainProxy* proxy = [ChainProxy alloc];
    proxy.chain = impChain;
    return proxy;
}
-(NSMethodSignature*) methodSignatureForSelector:(SEL)sel {
    for (NSUInteger i = 0; i < self.chain.count; ++i) {
        if([self.chain[i].target respondsToSelector:sel]) {
            NSMethodSignature *sig = [self.chain[i] methodSignatureForSelector:sel];
            if (sel != nil) {
                selectedItem = self.chain[i];
                return sig;
            }
        }
    }
    return [NSMethodSignature signatureWithObjCTypes:"@@:iiiiiiiiiiiiiiiiiiiii"];
}
-(void)forwardInvocation:(NSInvocation *)invocation{
    if(selectedItem!=nil){
        [selectedItem forwardInvocation:invocation];
    }
    return;
}
@end

@implementation RxEncodeTypeUtil
+(RxEncodeType)getEncodeType:(const char*)code{
    if(!strcmp(code, @encode(char))){//"c"
        return EncodeCharType;
    }else if(!strcmp(code, @encode(int))){//"i"
        return EncodeIntType;
    }else if(!strcmp(code, @encode(short))){//"s"
        return EncodeShortType;
    }else if(!strcmp(code, @encode(long))){//"l"
        return EncodeLongType;
    }else if(!strcmp(code, @encode(long long))){//"q"
        return EncodeLongLongType;
    }else if(!strcmp(code, @encode(unsigned char))){//"C"
        return EncodeUCharType;
    }else if(!strcmp(code, @encode(unsigned int))){//"I"
        return EncodeUIntType;
    }else if(!strcmp(code, @encode(unsigned short))){//"S"
        return EncodeUShortType;
    }else if(!strcmp(code, @encode(unsigned long))){//"L"
        return EncodeULongType;
    }else if(!strcmp(code, @encode(unsigned long long))){//"Q"
        return EncodeULongLongType;
    }else if(!strcmp(code, @encode(float))){//"f"
        return EncodeFloatType;
    }else if(!strcmp(code, @encode(double))){//"d"
        return EncodeDoubleType;
    }else if(!strcmp(code, @encode(BOOL))){//"B"
        return EncodeBoolType;
    }else if(!strcmp(code, @encode(void))){//"v"
        return EncodeVoidType;
    }else if(!strcmp(code, @encode(char*))){//"*"
        return EncodeCCharStrType;
    }else if(!strcmp(code, "@?")){//"@?"
        return EncodeBlockType;
    }else if(strstr(code, "@")==code){//"@" "@"类名""
        return EncodeIdType;
    }else if(!strcmp(code, "#")){//"#"
        return EncodeClassType;
    }else if(!strcmp(code, ":")){//":"
        return EncodeSELType;
    }else if(strstr(code, "[")==code){//"[array type]" 例如int intArray[5] = {1,2,3,4,5}; 那么@encode(typeof(intArray))就是数组类型
        return EncodeArrayType;
    }else if(strstr(code, "{")==code){//"{name=type}"
        return EncodeStructType;
    }else if(strstr(code, "(")==code){//"(name=type)"
        return EncodeUnionType;
    }else if(strstr(code, "^^")==code){//多重指针类型
        return EncodeMultiPointerType;
    }else if(!strcmp(code, "^?")){//"^?"
        return EncodeFuncType;
    }else if(strstr(code, "^")==code){//"^type"指针类型
        return EncodePointerType;
    }

    return EncodeUnKnownType;//"?"
}
@end


@implementation InvokeUtil

+(id)returnValueChange:(NSInvocation *)invocation{
    if(invocation.methodSignature.methodReturnLength != 0){//返回值的字节长度
        //EasyLog(@"---methodReturnLength:%d",invocation.methodSignature.methodReturnLength);
        RxEncodeType retType = [RxEncodeTypeUtil getEncodeType:invocation.methodSignature.methodReturnType];
        __autoreleasing id retObj;
        if(     retType == EncodeIdType ||
                retType == EncodeBlockType ||
                retType == EncodeClassType){
            [invocation getReturnValue:&retObj];
        }
        else if(retType == EncodeCharType){
            char value;[invocation getReturnValue:&value];retObj = @(value);
        }else if(retType == EncodeIntType){
            int value;[invocation getReturnValue:&value];retObj = @(value);
        }else if(retType == EncodeShortType){
            short value;[invocation getReturnValue:&value];retObj = @(value);
        }else if(retType == EncodeLongType){
            long value;[invocation getReturnValue:&value];retObj = @(value);
        }else if(retType == EncodeLongLongType){
            long long value;[invocation getReturnValue:&value];retObj = @(value);
        }else if( retType == EncodeULongLongType){
            unsigned long long value;[invocation getReturnValue:&value];retObj = @(value);
        }else if(retType == EncodeUCharType){
            unsigned char value;[invocation getReturnValue:&value];retObj = @(value);
        }else if(retType == EncodeUIntType){
            unsigned int value;[invocation getReturnValue:&value];retObj = @(value);
        }else if(retType == EncodeUShortType){
            unsigned short value;[invocation getReturnValue:&value];retObj = @(value);
        }else if(retType == EncodeULongType){
            unsigned long value;[invocation getReturnValue:&value];retObj = @(value);
        }else if(retType == EncodeFloatType){
            float value;[invocation getReturnValue:&value];retObj = @(value);
        }else if(retType == EncodeDoubleType){
            double value;[invocation getReturnValue:&value];retObj = @(value);
        }else if(retType == EncodeBoolType){
            BOOL value;[invocation getReturnValue:&value];retObj = @(value);
        } else{
            void* res= malloc(invocation.methodSignature.methodReturnLength);
            __autoreleasing MyMem *mem = [MyMem new];//
            mem->memAddr = res;
            [invocation getReturnValue:res];
            return [NSValue value:res withObjCType:invocation.methodSignature.methodReturnType];
        }
        return retObj;
    }
    return nil;
}
#define PAC_NUM_TYPE(CODE,TYPE) if(typeCode == CODE){TYPE v = va_arg(list, TYPE);[arr addObject:@(v)];}
+(NSArray *)packBlockArgToId:(id)block args:(va_list)list{
    NSMutableArray *arr = [NSMutableArray new];
    if(![self checkBlockInvokeable:block]){
        return arr;
    }
    NSMethodSignature *sig = [NSMethodSignature rx_methodSignatureWithBlock:block];
    for(int i=1;i<sig.numberOfArguments;i++){
        const char* type = [sig getArgumentTypeAtIndex:i];
        RxEncodeType typeCode = [RxEncodeTypeUtil getEncodeType:type];
        PAC_NUM_TYPE(EncodeCharType,int);
        PAC_NUM_TYPE(EncodeIntType,int);
        PAC_NUM_TYPE(EncodeShortType,int);
        PAC_NUM_TYPE(EncodeLongType,long);
        PAC_NUM_TYPE(EncodeLongLongType,long long);
        PAC_NUM_TYPE(EncodeUCharType, int);
        PAC_NUM_TYPE(EncodeUIntType, unsigned int);
        PAC_NUM_TYPE(EncodeUShortType, int);
        PAC_NUM_TYPE(EncodeULongType, unsigned long);
        PAC_NUM_TYPE(EncodeULongLongType, unsigned long long);
        PAC_NUM_TYPE(EncodeFloatType,double);
        PAC_NUM_TYPE(EncodeDoubleType,double);
        PAC_NUM_TYPE(EncodeBoolType,int);
        if(typeCode == EncodeSELType || typeCode == EncodePointerType ||
                typeCode==EncodeFuncType || typeCode==EncodeMultiPointerType){
            void* point = va_arg(list, void*);
            [arr addObject:[NSValue valueWithPointer:point]];
        }else if(typeCode == EncodeIdType || typeCode == EncodeBlockType ||
                typeCode==EncodeClassType){
            id arg = va_arg(list,id);
            [arr addObject:arg];
        }
    }
    return arr;
}
+(BOOL)checkBlockInvokeable:(id)block{
    if(block==nil){
        return NO;
    }
    if([block isKindOfClass:[NSNull class]]){
        return NO;
    }
    NSInvocation* invocation = [NSInvocation rx_invocationWithBlock:block];
    NSMethodSignature *sig = invocation.methodSignature;
    //EasyLog(@">>>numberOfArguments:%d",sig.numberOfArguments);
    int argCount = (int)(sig.numberOfArguments - 1);
    for(NSUInteger i=1;i <= argCount ;i++){
        const char* type = [sig getArgumentTypeAtIndex:i];
        RxEncodeType typeCode = [RxEncodeTypeUtil getEncodeType:type];
        //EasyLog(@">>>index:%d type:%s",i,type);
        if(typeCode == EncodeArrayType || typeCode == EncodeStructType || typeCode == EncodeUnionType ||
                typeCode == EncodeUnKnownType){
            return NO;
        }
    }
    if(invocation.methodSignature.methodReturnLength != 0){//返回值的字节长度
        //EasyLog(@"---methodReturnLength:%d",invocation.methodSignature.methodReturnLength);
        RxEncodeType retType = [RxEncodeTypeUtil getEncodeType:invocation.methodSignature.methodReturnType];
        if(retType == EncodeArrayType || retType == EncodeStructType || retType == EncodeUnionType ||
                retType == EncodeUnKnownType){
            return NO;
        }
    }
    return YES;
}
+(id)invokeBlock:(id)block args:(va_list)list  error:(NSError**)err invocation:(NSInvocation **)invo{
    if(block==nil){
        return nil;
    }
    if([block isKindOfClass:[NSNull class]]){
        return nil;
    }
    if(![self checkBlockInvokeable:block]){
        if(err){
            *err = [NSError errorWithDomain:@"com.InvokeError" code:-1 userInfo:nil];
        }
        return nil;
    }
    __autoreleasing NSInvocation* invocation = [NSInvocation rx_invocationWithBlock:block];
    NSMethodSignature *sig = invocation.methodSignature;
    int argCount = (int)(sig.numberOfArguments - 1);
    int index = 1;
    for(NSUInteger i=0;i<sig.numberOfArguments-1;i++){
        const char* type = [sig getArgumentTypeAtIndex:index];
        RxEncodeType typeCode = [RxEncodeTypeUtil getEncodeType:type];
        if(typeCode == EncodeCharType){
            char arg = va_arg(list, int);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.c = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeIntType){
            int arg = va_arg(list, int);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.i = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeShortType){
            short arg = va_arg(list, int);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.s = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeLongType){
            long arg = va_arg(list, long);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.l = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeLongLongType){
            long long arg = va_arg(list,long long);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.q = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeUCharType){
            unsigned char arg = va_arg(list,int);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.S = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeUIntType){
            unsigned int arg = va_arg(list,unsigned int);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.I = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeUShortType){
            unsigned short arg = va_arg(list,int);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.S = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeULongType){
            unsigned long arg = va_arg(list,unsigned long);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.L = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeULongLongType){
            unsigned long long arg = va_arg(list,unsigned long long);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.Q = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeFloatType){
            float arg = va_arg(list,double);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.f = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeDoubleType){
            double arg = va_arg(list,double);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.d = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeBoolType){
            BOOL arg = va_arg(list,int);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.B = arg;
            [invocation setArgument:mem->_addr atIndex:index];//参数传入
        }else if(typeCode == EncodeCCharStrType){
            char* arg = va_arg(list,char*);
            RxLog(@">>>>EncodeCCharStrType %s",arg);
            [invocation setArgument:&arg atIndex:index];//参数传入
        }else if(typeCode == EncodeIdType || typeCode == EncodeBlockType || typeCode == EncodeClassType){
            __autoreleasing id arg = va_arg(list,id);
            [invocation setArgument:&arg atIndex:index];//参数传入
        }else if(typeCode == EncodeSELType || typeCode == EncodePointerType ||
                typeCode==EncodeFuncType || typeCode==EncodeMultiPointerType){
            void* arg = va_arg(list,void*);
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            mem->_value.p = arg;
            [invocation setArgument:&arg atIndex:index];//参数传入
        }else if(typeCode == EncodeArrayType || typeCode == EncodeStructType || typeCode == EncodeUnionType ||
                typeCode == EncodeUnKnownType){
            //以下三个类型貌似不好取出，长度虽然可以使用
            // NSUInteger valueSize = 0;
            //NSGetSizeAndAlignment(argType, &valueSize, NULL);得到，但是取出仍然是很大问题
            if(err){
                *err = [NSError errorWithDomain:@"com.InvokeError" code:-2 userInfo:nil];
            }
            return nil;
        }
        index++;
    }
    [invocation invoke];
    if(invo!=nil){
        *invo = invocation;
    }
    if(invocation.methodSignature.methodReturnLength != 0){//返回值的字节长度
        //EasyLog(@"---methodReturnLength:%d",invocation.methodSignature.methodReturnLength);
        RxEncodeType retType = [RxEncodeTypeUtil getEncodeType:invocation.methodSignature.methodReturnType];
        if(     retType == EncodeIdType ||
                retType == EncodeBlockType ||
                retType == EncodeClassType){
            __autoreleasing id retObj;
            [invocation getReturnValue:&retObj];
            return retObj;
        }
        else if(retType == EncodeCharType || retType == EncodeIntType || retType == EncodeShortType ||
                retType == EncodeLongType || retType == EncodeLongLongType || retType == EncodeUCharType ||
                retType == EncodeUIntType || retType == EncodeUShortType || retType == EncodeULongType ||
                retType == EncodeFloatType || retType == EncodeDoubleType || retType == EncodeBoolType||
                retType == EncodeULongLongType){
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            [invocation getReturnValue:mem->_addr];
            RxLog(@">>>>>RxProxyMem:%d",mem->_value.q);
            return mem;
        }else if(retType == EncodeSELType || retType == EncodePointerType ||
                retType==EncodeFuncType || retType==EncodeMultiPointerType){
            __autoreleasing RxProxyMem* mem=[RxProxyMem new];
            void* point=NULL;
            [invocation getReturnValue:&point];
            mem->_value.p = point;
            mem->_addr = point;
            return mem;
        }
        else if(retType == EncodeCCharStrType){
            char* res= NULL;
            [invocation getReturnValue:&res];
            __autoreleasing RxProxyMem *mem = [RxProxyMem new];
            mem->_addr = res;
            mem->_value.p = res;
            return mem;
        }
        else if(retType == EncodeArrayType || retType == EncodeStructType || retType == EncodeUnionType ||
                retType == EncodeUnKnownType){
            if(err){
                *err = [NSError errorWithDomain:@"com.InvokeError" code:-3 userInfo:nil];
            }
            return invocation;//自行读取
        }
//        else{
//            void* res= malloc(invocation.methodSignature.methodReturnLength);
//            __autoreleasing MyMem *mem = [MyMem new];//
//            mem->memAddr = res;
//            [invocation getReturnValue:res];
//            return res;
//        }
    }
    return nil;
}
+(id)invokeBlock:(id)block argsList:(NSArray *)argArr{
    if(block==nil){
        return nil;
    }
    if([block isKindOfClass:[NSNull class]]){
        return nil;
    }
    NSInvocation* invocation = [NSInvocation rx_invocationWithBlock:block];
    int index = 1;
    //EasyLog(@"method argcount:%d",invocation.methodSignature.numberOfArguments);
    for(NSUInteger i=0;i<invocation.methodSignature.numberOfArguments-1;i++){
        id arg = argArr[i];
        [invocation setArgument:(void*)&arg atIndex:index];//参数传入
        index++;
    }

    [invocation invoke];

    return [self returnValueChange:invocation];
}
+(id)invoke:(id)target selector:(SEL)seletor argsList:(NSArray *)argArr{//参数都是id类型
    NSMethodSignature* signature = [target methodSignatureForSelector:seletor];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector  =seletor;
    int index = 2;//参数序号从2开始，前两个分别是self 和 cmd占用

    for(NSUInteger i=0;i<invocation.methodSignature.numberOfArguments-2;i++){
        id arg = argArr[i];
        [invocation setArgument:(void*)&arg atIndex:index];//参数传入
        index++;
    }

    [invocation invoke];

    return [self returnValueChange:invocation];
}
+(id)invoke:(id)target selector:(SEL)seletor firstArg:(void*)arg arglist:(va_list)list{
    NSMethodSignature* signature = [target methodSignatureForSelector:seletor];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector  =seletor;
    int index = 2;//参数序号从2开始，前两个分别是self 和 cmd占用
    void* ar = arg;
    for(;ar!=nil; ar =  va_arg(list, void*)){
        int* ivp = ar;
        //EasyLog(@">>>>>invoke arglist:%d",*ivp);
        [invocation setArgument:ar atIndex:index];//参数传入
        index++;
    }
    [invocation invoke];
    return [self returnValueChange:invocation];
}
+(id)invoke:(id)target selector:(SEL)seletor arglist:(va_list)list{
    NSMethodSignature* signature = [target methodSignatureForSelector:seletor];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector  =seletor;
    int index = 2;//参数序号从2开始，前两个分别是self 和 cmd占用
    void* ar = va_arg(list, void*);
    for(;ar!=nil; ar =  va_arg(list, void*)){
        int* ivp = ar;
        RxLog(@">>>>>invoke arglist:%d",*ivp);
        [invocation setArgument:ar atIndex:index];//参数传入
        index++;
    }
    [invocation invoke];
    return [self returnValueChange:invocation];
}
+(id)invoke:(id)target selector:(SEL)seletor args:(void*)arg,...NS_REQUIRES_NIL_TERMINATION{
    NSMethodSignature* signature = [target methodSignatureForSelector:seletor];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    invocation.target = target;
    invocation.selector  =seletor;
    int index = 2;//参数序号从2开始，前两个分别是self 和 cmd占用
    
    va_list arglist;
    va_start(arglist, arg);
    for(void* ar = arg;ar!=nil; ar =  va_arg(arglist, void*)){
        [invocation setArgument:ar atIndex:index];//参数传入
        index++;
    }
    va_end(arglist);
    
    [invocation invoke];
    return [self returnValueChange:invocation];
}
@end
