//
//  NSNotificationCenter+HLCategory.h
//  easylib
//
//  Created by 黎书胜 on 2018/1/8.
//  Copyright © 2018年 黎书胜. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RxOC;

@interface NSNotificationCenter(Rx)
@property (strong, nonatomic)NSMutableArray *gcObserverArr;
//如果RxOC启动，那么就需要在合适的时候调用unsubscribe来清除这个监听
-(RxOC*)rx_observeNotificationForName:(NSString *)notificationName object:(id)object;
//autoClean参数为，我们会在这个对象的dealloc之后释放对NSNotificationCenter的监听
-(RxOC*)rx_observeNotificationForName:(NSString *)notificationName object:(id)object autoClean:(NSObject*)obj;
@end
