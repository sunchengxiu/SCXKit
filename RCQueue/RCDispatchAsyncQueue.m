//
//  RCQueue.m
//  RCAsyncTaskLib
//
//  Created by 孙承秀 on 2018/6/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCDispatchAsyncQueue.h"
#import <libkern/OSAtomic.h>
#define MAX_QUEUE_COUNT 32
typedef struct {
    const char *name;
    void **queues;
    uint32_t queueCount;
    int32_t safer;
    
}RCContext;

static inline qos_class_t RCPriorityFromQOS(NSQualityOfService qos){
    switch (qos) {
        case NSQualityOfServiceUserInteractive:
            return QOS_CLASS_USER_INTERACTIVE;
            break;
            case NSQualityOfServiceUserInitiated:
            return QOS_CLASS_USER_INITIATED;
            break;
            case NSQualityOfServiceUtility:
            return QOS_CLASS_UTILITY;
            break;
            case NSQualityOfServiceDefault:
            return NSQualityOfServiceDefault;
            break;
            case NSQualityOfServiceBackground:
            return QOS_CLASS_BACKGROUND;
            break;
        default:
            return QOS_CLASS_UNSPECIFIED;
            break;
    }
}


static inline dispatch_queue_priority_t RCPriorityFromDispatch(NSQualityOfService qos){
    switch (qos) {
        case NSQualityOfServiceUserInteractive:
            return DISPATCH_QUEUE_PRIORITY_HIGH;
            break;
        case NSQualityOfServiceUserInitiated:
            return DISPATCH_QUEUE_PRIORITY_HIGH;
            break;
        case NSQualityOfServiceUtility:
            return DISPATCH_QUEUE_PRIORITY_LOW;
            break;
        case NSQualityOfServiceDefault:
            return DISPATCH_QUEUE_PRIORITY_DEFAULT;
            break;
        case NSQualityOfServiceBackground:
            return DISPATCH_QUEUE_PRIORITY_BACKGROUND;
            break;
        default:
            return DISPATCH_QUEUE_PRIORITY_DEFAULT;
            break;
    }
}
static void RCReleaseContext(RCContext *context){
    if (!context) {
        return;
    }
    if (context->queues) {
        for (NSInteger i = 0 ; i < context->queueCount; i ++) {
            void *pointer = context->queues[i];
            dispatch_queue_t queue = (__bridge dispatch_queue_t)pointer;
            queue = nil;
        }
        free(context->queues);
        context->queues=NULL;
    }
    if (context->name) {
        free((void *)context->name);
    }
    free(context);
}
static RCContext *RCCreateContext(const char *name , uint32_t count,NSQualityOfService qos){
    RCContext *context = calloc(1, sizeof(RCContext));
    if (!context) {
        NSLog(@"context 内存分配错误");
        return NULL;
    }
    context->queues = calloc(count, sizeof(void *));
    if (!context->queues) {
        NSLog(@"queues 内存分配错误");
        free(context);
        return NULL;
    }
    if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
        dispatch_qos_class_t qosP = RCPriorityFromQOS(qos);
        for (NSInteger i = 0 ; i < count; i ++) {
            dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qosP, 0);
            dispatch_queue_t queue = dispatch_queue_create(name, attr);
            context->queues[i] = (__bridge_retained void *)(queue);
        }
        
    } else {
        long identifer = RCPriorityFromDispatch(qos);
        for (NSInteger i = 0 ; i < count; i ++) {
            dispatch_queue_t queue = dispatch_queue_create(name, DISPATCH_QUEUE_SERIAL);
            dispatch_set_target_queue(queue, dispatch_get_global_queue(identifer, 0));
            context->queues[i] = (__bridge_retained void *)queue;
        }
    }
    
    context->queueCount = count;
    if (name) {
        context->name = name;
    }
    return context;
    
}
static RCContext *RCGetContext(NSQualityOfService qos){
    static RCContext *context[5]={0};
    switch (qos) {
        case NSQualityOfServiceUserInteractive:
        {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                int count = (int)[NSProcessInfo processInfo].activeProcessorCount;
                count = count < 1 ? 1 : (count > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : count);
                context[0] = RCCreateContext("http://www.rongcloud.cn.william_UserInteractive", count, qos);
            });
            return context[0];
        }
            break;
        case NSQualityOfServiceUserInitiated:{
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                int count = (int)[NSProcessInfo processInfo].activeProcessorCount;
                count = count < 1 ? 1 : (count > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : count);
                context[1] = RCCreateContext("http://www.rongcloud.cn.william_UserInitiated", count, qos);
            });
            return context[1];
        }
            break;
        case NSQualityOfServiceUtility:{
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                int count = (int)[NSProcessInfo processInfo].activeProcessorCount;
                count = count < 1 ? 1 : (count > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : count);
                context[2] = RCCreateContext("http://www.rongcloud.cn.william_Utility", count, qos);
            });
            return context[2];
        }
            break;
            case NSQualityOfServiceBackground:
        {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                int count = (int)[NSProcessInfo processInfo].activeProcessorCount;
                count = count < 1 ? 1 : (count > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : count);
                context[3] = RCCreateContext("http://www.rongcloud.cn.william_Background", count, qos);
            });
            return context[3];
        }
            break;
        case NSQualityOfServiceDefault:
        default:
        {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                int count = (int)[NSProcessInfo processInfo].activeProcessorCount;
                count = count < 1 ? 1 : (count > MAX_QUEUE_COUNT ? MAX_QUEUE_COUNT : count);
                context[4] = RCCreateContext("http://www.rongcloud.cn.william_Default", count, qos);
            });
            return context[4];
        }
            break;
    }
}
static dispatch_queue_t RCGetQueue(RCContext *context){
    uint32_t safer = OSAtomicIncrement32(&context->safer);
    void *queue = context->queues[safer % context->queueCount];
    return (__bridge dispatch_queue_t)(queue);
}
dispatch_queue_t RCDispatchQueuePool(NSQualityOfService qos){
    RCContext *context = RCGetContext(qos);
    dispatch_queue_t queue = RCGetQueue(context);
    return queue;
}
void RCDispatchQueuePoolWithBlock(NSQualityOfService qos,void (^block)(dispatch_queue_t)){
    RCContext *context = RCGetContext(qos);
    dispatch_queue_t queue = RCGetQueue(context);
    if (block) {
        block(queue);
    }
}

//@interface RCDispatchAsyncQueue()
//
//@end
@implementation RCDispatchAsyncQueue{
    RCContext *_context;
}
- (instancetype)initWithQueueName:(NSString *)name queueCount:(NSUInteger)count queueQos:(NSQualityOfService)qos{
    if (count ==0 || count > MAX_QUEUE_COUNT ) {
        NSLog(@"您申请的队列太多或者太多了，考虑一下");
        return nil;
    }
    self = [super init];
    _context = RCCreateContext(name.UTF8String, (uint32_t)count, qos);
    if (!_context) {
        NSLog(@"context 申请失败");
        return nil;
    }
    _name = name;
    return self;
}
- (instancetype)initWithContext:(RCContext *)context{
    self = [super init];
    if (context) {
        _context = context;
        _name = (context->name)?[NSString stringWithUTF8String:context->name] : nil;
        return self;
    }
    return nil;
}
+(instancetype)queueFromQos:(NSQualityOfService)qos{
    static dispatch_once_t onceToken;
    static RCDispatchAsyncQueue *queue ;
    dispatch_once(&onceToken, ^{
        queue = [[RCDispatchAsyncQueue alloc] initWithContext:RCGetContext(qos)];
    });
    return queue;
}
- (dispatch_queue_t)rc_queue{
    return RCGetQueue(_context);
}
-(void)dealloc{
    if (_context) {
        RCReleaseContext(_context);
    }
}
@end
