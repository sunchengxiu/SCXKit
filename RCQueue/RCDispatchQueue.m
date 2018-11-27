//
//  RCDispatchQueue.m
//  RCDispatchQueuePool
//
//  Created by 孙承秀 on 2018/6/9.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCDispatchQueue.h"
#import "RCDispatchAsyncQueue.h"

@interface RCDispatchQueue()
@property(nonatomic , assign)void (*queuePointer) (NSQualityOfService,void (^block)(dispatch_queue_t));
@property(nonatomic , assign)NSQualityOfService currentQOS;
@property(nonatomic , copy)dispatch_block_t block;
@property(nonatomic , assign)NSTimeInterval delay;
@property(nonatomic , strong)__block dispatch_semaphore_t sem;;
@end
@implementation RCDispatchQueue

/**
 获取一个默认的队列，优先级默认为（RCQualityOfServiceDefault），如果开启 start 会在此队列中根据优先级延迟指定 time 时间后，执行 block。

 @param block block
 @param time 延迟时间
 @return 队列对象
 */
+ (instancetype)dispatch_Queue_Block_After:(dispatch_block_t)block delay:(NSTimeInterval)time{
    return [self dispatch_Queue_Block_After:block QOS:RCQualityOfServiceDefault delay:time];
}

/**
 获取一个指定优先级的队列，如果开启 start 会在此队列中根据优先级延迟指定 time 时间后，执行 block。
 
 @param block block
 @param qos 指定优先级
 @param time 延迟时间
 @return 队列对象
 */
+ (instancetype)dispatch_Queue_Block_After:(dispatch_block_t)block QOS:(RCQualityOfService)qos delay:(NSTimeInterval)time{
    return [self dispatch_Queue_GlobalBlock:block QOS:qos time:time];
}
/**
 获取一个默认的队列，优先级默认为（RCQualityOfServiceDefault），如果开启 start 会在此队列中根据优先级立刻执行 block。
 
 @param block block
 @return 队列对象
 */
+ (instancetype)dispatch_Queue_Block:(dispatch_block_t)block{
    return [self dispatch_Queue_Block:block QOS:RCQualityOfServiceDefault];
}

/**
 获取一个指定优先级的队列，如果开启 start 会在此队列中根据优先级立刻执行 block。

 @param block block
 @param qos 优先级
 @return 队列对象
 */
+ (instancetype)dispatch_Queue_Block:(dispatch_block_t)block QOS:(RCQualityOfService)qos{
    return [self dispatch_Queue_GlobalBlock:block QOS:qos time:0];
}

+ (instancetype)dispatch_Queue_GlobalBlock:(dispatch_block_t)block QOS:(RCQualityOfService)qos time:(NSTimeInterval)time{
    return [[[self class] alloc] initQueueWithQOS:qos block:block time:time];
}
- (instancetype)initQueueWithQOS:(RCQualityOfService)qos block:(dispatch_block_t)block time:(NSTimeInterval)time{
    if (self = [super init]) {
        self.delay = time;
        self.block = block;
        NSQualityOfService nsqos = [self switchQos:qos];
        self.currentQOS = nsqos;
        self.queuePointer = RCDispatchQueuePoolWithBlock;
        self.sem = dispatch_semaphore_create(0);
        [self start];
    }
    return self;
}
- (void)start{
    self.queuePointer(self.currentQOS, ^(dispatch_queue_t queue) {
        dispatch_async(queue, ^{
            NSLog(@"%@",queue);
           [self dispatch_Queue_after1:queue block:self.block delay:self.delay];
        });
    });
}
- (void)cancel{
    
}
- (NSQualityOfService)switchQos:(RCQualityOfService)qos{
    switch (qos) {
        case RCQualityOfServiceUserInteractive:
        return NSQualityOfServiceUserInteractive;
        break;
        case RCQualityOfServiceUserInitiated:
        return NSQualityOfServiceUserInitiated;
        break;
        case RCQualityOfServiceUtility:
        return NSQualityOfServiceUtility;
        break;
        case RCQualityOfServiceBackground:
        return NSQualityOfServiceBackground;
        break;
        case RCQualityOfServiceDefault:
        return NSQualityOfServiceDefault;
        break;
        default:
        return NSQualityOfServiceDefault;
        break;
    }
}
- (void)dispatch_Queue_after1:(dispatch_queue_t)queue block:(dispatch_block_t)block  delay:(NSTimeInterval) time{
    dispatch_semaphore_wait(self.sem, dispatch_time(DISPATCH_TIME_NOW, time * 1000 * 1000 * 1000 ));
    block();
    dispatch_semaphore_signal(self.sem);
}
@end
