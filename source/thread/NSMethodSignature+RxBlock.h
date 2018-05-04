//
//  NSMethodSignature+Block.h
//  easylib
//
//  Created by 黎书胜 on 2018/2/5.
//  Copyright © 2018年 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSMethodSignature(RxBlock)
+(NSMethodSignature *)rx_methodSignatureWithBlock:(id)block;
@end
