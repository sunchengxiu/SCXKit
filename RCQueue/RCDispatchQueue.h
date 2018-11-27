//
//  RCDispatchQueue.h
//  RCDispatchQueuePool
//
//  Created by 孙承秀 on 2018/6/9.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
typedef NS_ENUM(NSInteger, RCQualityOfService) {
    /*
     一些需要瞬间完成的任务
     */
    RCQualityOfServiceUserInteractive ,
    
    /*
     一些需要立即得到结果的任务，比如在几秒甚至时间更短的时间内完成，优先级低于 UserInteractive
     */
    RCQualityOfServiceUserInitiated ,
    
    /*
    一些需要稍微花点时间完成的任务，比如下载任务等
     */
    RCQualityOfServiceUtility ,
    
    /*
     一些耗时操作，比如数据的备份等需要花费几分钟甚至几小时的任务
     */
    RCQualityOfServiceBackground  ,
    
    /*
     默认状态，介于 UserInitiated 和 Utility 
     */
    RCQualityOfServiceDefault 
};

@interface RCDispatchQueue : NSObject

/**
 获取一个默认的队列，优先级默认为（RCQualityOfServiceDefault），如果开启 start 会在此队列中根据优先级延迟指定 time 时间后，执行 block。
 
 @param block block
 @param time 延迟时间
 @return 队列对象
 */
+ (instancetype)dispatch_Queue_Block_After:(dispatch_block_t)block delay:(NSTimeInterval)time;
/**
 获取一个指定优先级的队列，如果开启 start 会在此队列中根据优先级延迟指定 time 时间后，执行 block。
 
 @param block block
 @param qos 指定优先级
 @param time 延迟时间
 @return 队列对象
 */
+ (instancetype)dispatch_Queue_Block_After:(dispatch_block_t)block QOS:(RCQualityOfService)qos delay:(NSTimeInterval)time;

/**
 获取一个默认的队列，优先级默认为（RCQualityOfServiceDefault），如果开启 start 会在此队列中根据优先级立刻执行 block。
 
 @param block block
 @return 队列对象
 */
+ (instancetype)dispatch_Queue_Block:(dispatch_block_t)block;

/**
 获取一个指定优先级的队列，如果开启 start 会在此队列中根据优先级立刻执行 block。
 
 @param block block
 @param qos 优先级
 @return 队列对象
 */
+ (instancetype)dispatch_Queue_Block:(dispatch_block_t)block QOS:(RCQualityOfService)qos;
@end
