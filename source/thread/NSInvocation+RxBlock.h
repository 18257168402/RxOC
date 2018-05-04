//
//  NSInvocation+Block.h
//  NSInvocation+Block
//
//  Created by deput on 12/11/15.
//  Copyright © 2015 deput. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSInvocation (RxBlock)
+ (instancetype)rx_invocationWithBlock:(id) block;
+ (instancetype)rx_invocationWithBlockAndArguments:(id) block ,...;
@end
