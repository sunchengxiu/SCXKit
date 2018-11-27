//
//  RCMemoryCache.m
//  RCCache
//
//  Created by 孙承秀 on 2018/6/26.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCMemoryCache.h"
#import <RCDispatchQueueLib/RCDispatchQueueLib.h>
#import <pthread.h>
#define RCINLINE static inline
#define WEAK __weak typeof(self)weakSelf = self;
#define STRONG __strong typeof(weakSelf)strongSelf = weakSelf;

/**
 选择合适优先级的队列

 */
RCINLINE dispatch_queue_t RCReleaseQueue(){
    return RCDispatchQueuePool(NSQualityOfServiceUtility);
}
#pragma mark -
#pragma mark -------------- node(链表节点) ---------------
/**
 双向链表节点
 */
@interface RCCacheLinkNode : NSObject{
    @package
    __unsafe_unretained RCCacheLinkNode *_prev;
    __unsafe_unretained RCCacheLinkNode *_next;
    id _key;
    id _data;
    NSUInteger _cost;
    NSTimeInterval _time;
}
@end
#define NODEPRE RCCacheLinkNode *(^)
@implementation RCCacheLinkNode
#pragma mark -
#pragma mark -node get 方法
-(id)key{
    return self->_key;
}
- (id)value{
    return self->_data;
}
- (RCCacheLinkNode *)prev{
    return self->_prev;
}
- (RCCacheLinkNode *)next{
    return self->_next;
}
- (NSUInteger )cost{
    return self->_cost;
}
- (NSTimeInterval)time{
    return self->_time;
}

#pragma mark -
#pragma mark -node set 方法

-(NODEPRE (id))keyEqualTo{
    WEAK;
    return ^ RCCacheLinkNode *(id key){
        STRONG;
        if (strongSelf) {
            strongSelf->_key = key;
            return strongSelf;
        } else {
            return nil;
        }
    };
    
}
- (NODEPRE (id))valueEqualTo{
    WEAK;
    return ^ RCCacheLinkNode *(id data){
        STRONG;
        if (strongSelf) {
            strongSelf->_data = data;
            return strongSelf;
        } else {
            return nil;
        }
    };
}
- (NODEPRE (RCCacheLinkNode *))prevEqualTo{
    WEAK;
    return ^ RCCacheLinkNode *(RCCacheLinkNode *prev){
        STRONG;
        if (strongSelf) {
            strongSelf->_prev = prev;
            return strongSelf;
        } else {
            return nil;
        }
    };
}
- (NODEPRE (RCCacheLinkNode *))nextEqualTo{
    WEAK;
    return ^ RCCacheLinkNode *(RCCacheLinkNode *next){
        STRONG;
        if (strongSelf) {
            strongSelf->_next = next;
            return strongSelf;
        } else {
            return nil;
        }
    };
}
- (NODEPRE  (NSUInteger) )costEqualTo{
    WEAK;
    return ^ RCCacheLinkNode *(NSUInteger cost){
        STRONG;
        if (strongSelf) {
            strongSelf->_cost = cost;
            return strongSelf;
        } else {
            return nil;
        }
    };
}
- (NODEPRE (NSTimeInterval))timeEqualTo{
    WEAK;
    return ^ RCCacheLinkNode *(NSTimeInterval time){
        STRONG;
        if (strongSelf) {
            strongSelf->_time = time;
            return strongSelf;
        } else {
            return nil;
        }
    };
}
@end
#pragma mark -
#pragma mark -------------- 链表 ---------------
@interface RCCacheLinkMap : NSObject{
    @package
    CFMutableDictionaryRef _linkDic;
    RCCacheLinkNode *_head;
    RCCacheLinkNode *_tail;
    BOOL _releaseOnMainThread;
    BOOL _releaseAsynchronously;
    NSUInteger _totalCost;
    NSUInteger _totalCount;
    
}

/**
 头插法插入一个节点（该节点不在链表中）

 @param node 插入的节点
 */
- (void)insertNodeToHead:(RCCacheLinkNode *)node;

/**
 将一个节点推到头部（该节点已经在链表中）

 @param node 需要变换的节点
 */
- (void)bringNodeToHead:(RCCacheLinkNode *)node;

/**
 删除尾节点(需要存在尾节点)

 @return 删除的尾节点
 */
- (RCCacheLinkNode *)deleteTailNode;

/**
 删除一个节点（需要存在该节点）

 @param node 要删除的节点
 */
- (void)deleteNode:(RCCacheLinkNode *)node;

/**
 删除所有的节点
 */
- (void)deleteAllNodes;
@end

@implementation RCCacheLinkMap
- (RCCacheLinkNode *)tail{
    return self->_tail;
}
- (RCCacheLinkNode *)head{
    return self->_head;
}
- (NSUInteger)totalCount{
    return self->_totalCount;
}
- (NSUInteger)totalCost{
    return self->_totalCost;
}
- (CFMutableDictionaryRef)linkMapDic{
    return self->_linkDic;
}
- (BOOL)releaseOnMainThread{
    return self->_releaseOnMainThread;
}
- (BOOL)releaseOnAsyncThread{
    return self->_releaseAsynchronously;
}
- (RCCacheLinkMap *(^)(BOOL))releaseOnMainThreadEqualTo{
    WEAK
    return ^RCCacheLinkMap *(BOOL on){
        STRONG
        if (strongSelf) {
            strongSelf->_releaseOnMainThread = on;
            return self;
        } else {
            return nil;
        }
    };
}
- (RCCacheLinkMap *(^)(BOOL))releaseOnAsyncThreadEqualTo{
    WEAK
    return ^RCCacheLinkMap *(BOOL on){
        STRONG
        if (strongSelf) {
            strongSelf->_releaseAsynchronously = on;
            return self;
        } else {
            return nil;
        }
    };
}
-(instancetype)init{
    if (self = [super init]) {
        _linkDic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        _releaseOnMainThread = NO;
        _releaseAsynchronously = YES;
    }
    return self;
}

/**
 头插法

 @param node 插入的节点
 */
-(void)insertNodeToHead:(RCCacheLinkNode *)node{
    CFDictionarySetValue(_linkDic, (__bridge const void *)(node.key), (const void *)node);
    [self changeTheCountAndTheCost:node match:@"+"];
    if (_head) {
        node.nextEqualTo(_head);
        _head.prevEqualTo(node);
        _head = node;
        
    } else {
        _head = _tail = node;
    }
}

/**
 将节点切换到头部

 @param node 需要变换的节点
 */
-(void)bringNodeToHead:(RCCacheLinkNode *)node{
    if (_head == node) {
        return;
    }
    if (_tail == node) {
        _tail = node.prev;
        _tail.nextEqualTo(nil);
    } else {
        node.next.prevEqualTo(node.prev);
        node.prev.nextEqualTo(node.next);
    }
    node.nextEqualTo(_head);
    node.prevEqualTo(nil);
    _head.prevEqualTo(node);
    _head = node;
}

/**
 删除某个节点

 @param node 要删除的节点
 */
-(void)deleteNode:(RCCacheLinkNode *)node{
    CFDictionaryRemoveValue(_linkDic, (const void *)node.key);
    [self changeTheCountAndTheCost:node match:@"-"];
    if (node.next) {
        node.next.prevEqualTo(node.prev);
    }
    if (node.prev) {
        node.prev.nextEqualTo(node.next);
    }
    if (_head == node) {
        _head = node.next;
    }
    if (_tail == node) {
        _tail = node.prev;
    }
}

/**
 删除尾节点

 @return 删除的尾节点
 */
-(RCCacheLinkNode *)deleteTailNode{
    if (!_tail) {
        return nil;
    }
    RCCacheLinkNode *tailNode = _tail;
    CFDictionaryRemoveValue(_linkDic, (const void *)(_tail.key));
    [self changeTheCountAndTheCost:_tail match:@"-"];
    if (_head == _tail) {
        _head = _tail = nil;
    } else {
        _tail = _tail.prev;
        _tail.nextEqualTo(nil);
    }
    return tailNode;
}

/**
 删除所有的节点
 */
-(void)deleteAllNodes{
    _totalCost = 0;
    _totalCount = 0;
    _head = nil;
    _tail = nil;
    if (CFDictionaryGetCount(_linkDic)) {
        CFMutableDictionaryRef holder = _linkDic;
        _linkDic = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
        if (_releaseAsynchronously) {
            dispatch_queue_t queue = _releaseOnMainThread ? dispatch_get_main_queue() : RCReleaseQueue();
            dispatch_async(queue, ^{
                CFRelease(holder);
            });
        } else if(_releaseOnMainThread ){
            dispatch_async(dispatch_get_main_queue(), ^{
                CFRelease(holder);
            });
        } else {
            CFRelease(holder);
        }
    }
}
/**
 增长引用计数

 @param node 节点
 */
- (void)changeTheCountAndTheCost:(RCCacheLinkNode *)node match:(NSString *)match{
    self.increaseTotalCost(node,match).increaseTotalCount(match);
}
#pragma mark -
#pragma mark -私有方法封装
/**
 增长总内存计数
 */
- (RCCacheLinkMap * (^)(RCCacheLinkNode *,NSString *))increaseTotalCost{
    WEAK
    return ^ RCCacheLinkMap * (RCCacheLinkNode *node , NSString *match){
        STRONG
        if (strongSelf) {
            if ([match isEqualToString:@"+"]) {
                strongSelf->_totalCost += [node cost];
            } else if ([match isEqualToString:@"-"]){
                strongSelf->_totalCost -= [node cost];
            }
            return strongSelf;
        } else {
            return nil;
        }
        
    };
    
}


/**
 增长总容量计数
 */
- (RCCacheLinkMap *(^)(NSString *))increaseTotalCount{
    WEAK
    return  ^ RCCacheLinkMap *(NSString *match){
        STRONG
        if (strongSelf) {
            if ([match isEqualToString:@"+"]) {
                strongSelf->_totalCount ++;
            } else if ([match isEqualToString:@"-"]){
                strongSelf->_totalCount --;
            }
            return strongSelf;
        } else {
            return nil;
        }
    };
}
/**
 释放
 */
-(void)dealloc{
    CFRelease(_linkDic);
}
@end

#pragma mark -
#pragma mark -------------- 内存缓存 ---------------
@implementation RCMemoryCache{
    pthread_mutex_t _lock;
    RCCacheLinkMap *_linkMap;
    dispatch_queue_t _queue;
}
#define LOCK pthread_mutex_lock(&_lock);
#define UNLOCK pthread_mutex_unlock(&_lock);;
#define TRYLOCK (pthread_mutex_trylock(&_lock) == 0)
#pragma mark - private
- (void)trimToLimitCost:(NSUInteger)cost{
    LOCK
    BOOL finish = NO;
    if (cost <= 0 ) {
        [_linkMap deleteAllNodes];
        finish = YES;
    } else if (_linkMap.totalCost <= cost){
        finish = YES;
    }
    UNLOCK
    if (finish) {
        return;
    }
    NSMutableArray *holder = [NSMutableArray array];
    // 释放超出指定内存的资源
    while (!finish) {
        if (TRYLOCK) {
            if (_linkMap.totalCost > cost) {
                RCCacheLinkNode *node = [_linkMap deleteTailNode];
                if (node) {
                    [holder addObject:node];
                }
            } else {
                finish = YES;
            }
            UNLOCK
        } else {
            usleep(10 * 1000); // 10ms
        }
    }
    // 选择合适的线程释放资源
    if (holder.count) {
        dispatch_queue_t queue = _linkMap.releaseOnMainThread ? dispatch_get_main_queue() : RCReleaseQueue();
        dispatch_async(queue, ^{
            [holder count];
        });
    }
}
- (void)trimToLimitCount:(NSUInteger)count{
    LOCK
    BOOL finish = NO;
    if (count <= 0) {
        [_linkMap deleteAllNodes];
        return;
    } else if(_linkMap.totalCount <= count){
        finish = YES;
    }
    UNLOCK
    if (finish) {
        return;
    }
    NSMutableArray *holder = [NSMutableArray array];
    // 删除超出容量限制的缓存
    while (!finish) {
        if (pthread_mutex_trylock(&_lock) == 0) {
            if (TRYLOCK) {
                RCCacheLinkNode *node = [_linkMap deleteTailNode];
                if (node) {
                    [holder addObject:node];
                }
            } else {
                finish = YES;
            }
            UNLOCK
        } else {
            usleep(10 * 1000);
        }
    }
    // 选择合适的线程释放资源
    if (holder.count) {
        dispatch_queue_t queue = _linkMap.releaseOnMainThread ? dispatch_get_main_queue() : RCReleaseQueue();
        dispatch_async(queue, ^{
            [holder count];
        });
    }
}
- (void)trimToLimitAge:(NSTimeInterval)age{
    BOOL finish = NO;
    LOCK
    NSTimeInterval current = CACurrentMediaTime();
    if (age <= 0) {
        [_linkMap deleteAllNodes];
        finish = YES;
    } else if(_linkMap.tail && current - _linkMap.tail.time <= age){
        finish = YES;
    }
    UNLOCK
    if (finish) {
        return;
    }
    NSMutableArray *holder = [NSMutableArray array];
    // 删除过期的缓存
    while (!finish) {
        if (TRYLOCK) {
            if (_linkMap.tail && (current - _linkMap.tail.time > age)) {
                RCCacheLinkNode *node = [_linkMap deleteTailNode];
                if (node) {
                    [holder addObject:node];
                }
            } else {
                finish = YES;
            }
            UNLOCK
        } else {
            usleep(10 * 1000);
        }
    }
    // 选择合适的线程释放资源
    if (holder.count) {
        dispatch_queue_t queue = _linkMap.releaseOnMainThread ? dispatch_get_main_queue() : RCReleaseQueue();
        dispatch_async(queue, ^{
            [holder count];
        });
    }
}
- (void)trimPolling{
    WEAK
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoPollingTime * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
        STRONG
        if (strongSelf) {
            [strongSelf trimOnBackground];
            [strongSelf trimPolling];
        }
    });
}
- (void)trimOnBackground{
    dispatch_async(_queue, ^{
        [self trimToCost:self.limitCost];
        [self trimToCount:self.limitCount];
        [self trimToAge:self.limitAge];
    });
}
- (void)didReceiveMemoryWarning:(NSNotification *)noti{
    if (self.DidReceiveMemoryWarningBlock) {
        self.DidReceiveMemoryWarningBlock(self);
    }
    if (self.shouldRemoveAllObjectsOnMemoryWarning) {
        [self removeAllObjects];
    }
}
- (void)didEnterBackground:(NSNotification *)noti{
    if (self.DidEnterBackgroundBlock) {
        self.DidEnterBackgroundBlock(self);
    }
    if (self.shouldRemoveAllObjectsWhenEnterBackground) {
        [self removeAllObjects];
    }
}
#pragma mark - public
-(instancetype)init{
    if (self = [super init]) {
        pthread_mutex_init(&_lock, NULL);
        _queue = dispatch_queue_create("https://github.com/sunchengxiu/RCCache.git.memoryQueue", DISPATCH_QUEUE_SERIAL);
        _linkMap = [RCCacheLinkMap new];
        _autoPollingTime = 5.0;
        _totalLimitCost = NSUIntegerMax;
        _totalLimitCount = NSUIntegerMax;
        _limitAge = DBL_MAX;
        _shouldRemoveAllObjectsOnMemoryWarning = YES;
        _shouldRemoveAllObjectsWhenEnterBackground = YES;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [self trimPolling];
    }
    return self;
}
-(id)objectForKey:(id)key{
    if (!key) {
        return nil ;
    }
    LOCK
    RCCacheLinkNode *node = CFDictionaryGetValue(_linkMap.linkMapDic, (const void *)key);
    if (node) {
        NSTimeInterval current = CACurrentMediaTime();
        node.timeEqualTo(current);
        [_linkMap bringNodeToHead:node];
    }
    UNLOCK
    return node?node.value : nil;
}
-(BOOL)containObjectForKey:(id)key{
    if (!key) {
        return NO;
    }
    LOCK
    BOOL has = CFDictionaryContainsKey(_linkMap.linkMapDic, (__bridge const void *)key);
    UNLOCK
    return has;
}
-(void)setObject:(id)object forKey:(id)key{
    [self setObject:object forKey:key withCost:0];
}
-(void)setObject:(id)object forKey:(id)key withCost:(NSUInteger)cost{
    if (!key) {
        return;
    }
    if (!object) {
        [self removeObjectForKey:key];
        return;
    }
    LOCK
    RCCacheLinkNode *node = CFDictionaryGetValue(_linkMap.linkMapDic, (const void *)key);
    NSTimeInterval current = CACurrentMediaTime();
    if (node) {
        [_linkMap changeTheCountAndTheCost:node match:@"-"];
        node.costEqualTo(cost);
        [_linkMap changeTheCountAndTheCost:node match:@"+"];
        node.timeEqualTo(current);
        node.valueEqualTo(object);
        [_linkMap bringNodeToHead:node];
    } else {
        RCCacheLinkNode *node = [RCCacheLinkNode new];
        node.valueEqualTo(object);
        node.timeEqualTo(current);
        node.costEqualTo(cost);
        node.keyEqualTo(key);
        [_linkMap insertNodeToHead:node];
    }
    if (_linkMap.totalCount > _totalLimitCount) {
        RCCacheLinkNode *node = [_linkMap deleteTailNode];
        if (node) {
            if (_linkMap.releaseOnAsyncThread) {
                dispatch_queue_t queue = _linkMap.releaseOnMainThread ? dispatch_get_main_queue() : RCReleaseQueue();
                dispatch_async(queue, ^{
                    [node class];
                });
            } else if(_linkMap.releaseOnMainThread && !pthread_main_np()){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [node class];
                });
            }
        }
    }
    if (_linkMap.totalCost > _limitCost) {
        NSUInteger limit = _limitCost;
        WEAK
        dispatch_async(_queue, ^{
            STRONG
            if (strongSelf) {
                [strongSelf trimToCost:limit];
            }
        });
    }
    UNLOCK;
}
-(void)removeObjectForKey:(id)key{
    if (!key) {
        return;
    }
    LOCK
    RCCacheLinkNode *node = CFDictionaryGetValue(_linkMap.linkMapDic, (const void *)key);
    if (node) {
        [_linkMap deleteNode:node];
        if (_linkMap.releaseOnAsyncThread) {
            dispatch_queue_t queue = _linkMap.releaseOnMainThread ? dispatch_get_main_queue() : RCReleaseQueue();
            dispatch_async(queue, ^{
                [node class];
            });
        } else if (_linkMap.releaseOnMainThread && !pthread_main_np()){
            dispatch_async(dispatch_get_main_queue(), ^{
                [node class];
            });
        }
    }
    UNLOCK;
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [_linkMap deleteAllNodes];
    pthread_mutex_destroy(&_lock);
}
-(NSUInteger)totalCost{
    LOCK
    NSUInteger cost = _linkMap.totalCost;
    UNLOCK
    return cost;
}
-(NSUInteger)totalCount{
    LOCK
    NSUInteger count = _linkMap.totalCount;
    UNLOCK
    return count;
}
-(BOOL)releaseOnMainThread{
    LOCK
    BOOL releaseOnMainThread = _linkMap.releaseOnMainThread;
    UNLOCK
    return releaseOnMainThread;
}
-(BOOL)releaseOnAsyncThread{
    LOCK
    BOOL releaseOnAsyncThread = _linkMap.releaseOnAsyncThread;
    UNLOCK
    return releaseOnAsyncThread;
}
-(void)setReleaseOnMainThread:(BOOL)releaseOnMainThread{
    LOCK
    _linkMap.releaseOnMainThreadEqualTo(releaseOnMainThread);
    UNLOCK;
}
-(void)setReleaseOnAsyncThread:(BOOL)releaseOnAsyncThread{
    LOCK
    _linkMap.releaseOnAsyncThreadEqualTo(releaseOnAsyncThread);
    UNLOCK
}
-(void)removeAllObjects{
    LOCK
    [_linkMap deleteAllNodes];
    UNLOCK
}
-(void)trimToCost:(NSUInteger)cost{
    if (cost <= 0 ) {
        [self removeAllObjects];
        return;
    }
    [self trimToLimitCost:cost];
}
-(void)trimToCount:(NSUInteger)count{
    if (count <= 0 ) {
        [self removeAllObjects];
        return;
    }
    [self trimToLimitCount:count];
}
-(void)trimToAge:(NSTimeInterval)age{
    if (age <= 0 ) {
        [self removeAllObjects];
        return;
    }
    [self trimToLimitAge:age];
}
@end
