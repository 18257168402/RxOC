//
//  RxThreadUtil.h
//  guard
//
//  Created by 黎书胜 on 2017/10/26.
//  Copyright © 2017年 黎书胜. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RxOC.h"


typedef void (^HLTimerBlock)(NSTimer *timer,int repeatcount);
typedef void (^HLDisplayLinkBlock)(CADisplayLink *timer,int totalCount,int repeatCount);

@interface HLMessage:NSObject//后续有需要可以添加其他成员
    @property NSUInteger what;
    @property id obj;
    @property __weak id weakref;//有时候为了避免对象延迟释放(排队需要时间)，可以使用弱引用
@end

@protocol MessageHandler
-(void)handleMessage:(HLMessage*)msg;
@end

@interface HLThreadForLoop:NSThread
@property(atomic) BOOL isNeedQuitLoop;
@end

@interface HLThreadHandler:NSObject//handler主要为了解决异步的问题，消息处理都在同一个线程
{
    id<MessageHandler> _handler;
    NSMutableArray* _removeMsgs;
    BOOL _threadMode;
    HLThreadForLoop* _thread;
    NSPort* _port;
    NSRunLoop * _loop;
    NSCondition *_loopCondition;
}
@property (readonly, nonatomic) NSRunLoop * loop;
-(void)setThreadMode:(HLThreadForLoop*)th;
-(void)sendMessage:(HLMessage*)message;//发送消息
-(void)sendMessage:(HLMessage*)message after:(int)ms;//延迟发送消息
-(void)removeMessage:(HLMessage*)message;//移除消息
-(void)destory;//退出，非UI线程handler使用完毕必须销毁

-(id)initWithHandle:(id<MessageHandler>)hd;
-(void)handleMessage:(HLMessage *)message;
-(void)thread_entry_point:(id)obj;
@end

@interface TaskHandle:NSObject
{
    @private
    dispatch_block_t _task;
    id Lck;
    BOOL _cancel;
}
-(id)initWithBlk:(dispatch_block_t)blk lock:(id)lck;
-(void)invalidate;//取消调度
-(void)run;
@end


@interface RxThreadUtil : NSObject
+(BOOL)isOnMainThread;
+(TaskHandle*)runOnMainThread:(dispatch_block_t) task;//主线程执行
+(TaskHandle*)runOnMainThread:(dispatch_block_t) task after:(int)ms;

+(TaskHandle*)runOnBackground:(dispatch_block_t) task;//放入全局并发队列执行
+(TaskHandle*)runOnBackground:(dispatch_block_t) task after:(int)ms;

//+(TaskHandle*)runOnBackgroundSerial:(dispatch_block_t) task;//放入全局串行队列执行,弃用，实验可知，无法实现任务的串行执行
//+(TaskHandle*)runOnBackgroundSerial:(dispatch_block_t) task after:(int)ms;

+(HLThreadHandler*)buildUIHandler:(id<MessageHandler>)handler;//创建一个主线程的handler
+(HLThreadHandler*)buildNewThreadHandler:(id<MessageHandler>)handler;//新建一个线程，并且在这个线程中建立消息循环，此方式执行的任务，会用同一个线程执行，因此可以避免一些异步问题

/**
 *  loop -> nstimer -> block -> object -> proxy -弱->nstimer
 * 如果没有及时调用  NSTimer的invalidate，可能会造成泄露
 * 在object的dealloc函数中调用时不行的，因为他的dealloc函数需要没有引用计数的时候才能进入
 * 但是当nstimer运行期间，这个引用是一直有的，所以要选好时机调用invalidate
 *
 * @param ms 毫秒数
 * @param repeat 重复次数，如果是0代表一直重复，直到NSTimer invalidate
 * @return 返回NSTimer的代理，代理弱引用真正工作的NSTimer，所以就算返回的NSTimer*被强引用也不会产生循环引用
 */
+(NSTimer*) buildTimer:(int)ms repeat:(int)repeat blk:(HLTimerBlock)blk;//主线程创建定时器
/**
 * 不会产生循环应用的定时器
 *
 * 在一个单独线程运行timer, timer运行完毕，如果10秒钟内没有其他timer请求，那么线程循环退出
 */
+(NSTimer *)buildThreadTimer:(int)ms repeat:(int)repeat blk:(HLTimerBlock)blk;//线程创建定时器

+(CADisplayLink *)buildDisplayLink:(int)totalCount blk:(HLDisplayLinkBlock)blk;
+(CADisplayLink *)buildDisplayLink:(int)totalCount blk:(HLDisplayLinkBlock)blk per:(int)perframe;
@end
