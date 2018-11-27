//
//  RCQueue.h
//  RCAsyncTaskLib
//
//  Created by 孙承秀 on 2018/6/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface RCDispatchAsyncQueue : NSObject
- (instancetype)initWithQueueName:(NSString *)name queueCount:(NSUInteger)count queueQos:(NSQualityOfService)qos;
+(instancetype)queueFromQos:(NSQualityOfService)qos;
- (dispatch_queue_t)rc_queue;
@property(nonatomic , copy , readonly)NSString *name;
//dispatch_queue_t RCDispatchAsyncQueueInBlockWithQOS(NSQualityOfService qos,dispatch_block_t block);
dispatch_queue_t RCDispatchQueuePool(NSQualityOfService );
void RCDispatchQueuePoolWithBlock(NSQualityOfService qos,void (^block)(dispatch_queue_t));
@end
