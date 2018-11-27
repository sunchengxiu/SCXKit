//
//  RCMemoryCache.h
//  RCCache
//
//  Created by 孙承秀 on 2018/6/26.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface RCMemoryCache : NSObject
/**
 缓存的名字（默认为nil）
 */
@property(nonatomic , copy)NSString *name;
/**
 缓存的最大数量
 */
@property(nonatomic , assign , readonly)NSUInteger totalLimitCount;
/**
 缓存对象的总内存大小
 */
@property(nonatomic , assign , readonly)NSUInteger totalLimitCost;
/**
 设置缓存的总大小限制，默认为 NSUIntegerMax ，没有限制，如果设置了限制的大小，则超过设定值会在后台删除
 */
@property(nonatomic , assign)NSUInteger limitCount;
/**
 设置缓存的总内存大小，默认为 NSUIntegerMax ，没有限制，如果设置了大小，则超过设定值会在后台删除。
 */
@property(nonatomic , assign)NSUInteger limitCost;
/**
 设置缓存的过期时间，默认值为 DBL_MAX，没有限制，如果设置了超时时间，则超过设定的时间会在后台删除。
 */
@property(nonatomic , assign)NSTimeInterval limitAge;
/**
 自动轮询检查时间，默认为5s，内部包含一个轮询器，发现有达到限制的，开始驱逐对象
 */
@property(nonatomic , assign)NSTimeInterval autoPollingTime;
/**
 是否需要在内存警告的时候驱逐所有的对象，清空缓存，默认为 YES.
 */
@property(nonatomic , assign)BOOL shouldRemoveAllObjectsOnMemoryWarning;
/**
 进入后台是否需要删除所有的对象，默认为 YES
 */
@property(nonatomic , assign)BOOL shouldRemoveAllObjectsWhenEnterBackground;
/**
 收到内存警告执行的 block
 */
@property(nonatomic , copy)void (^DidReceiveMemoryWarningBlock)(RCMemoryCache *cache);
/**
 进入后台执行的 block
 */
@property(nonatomic , copy)void (^DidEnterBackgroundBlock)(RCMemoryCache *cache);
/**
 是否在主线程中释放对象,默认为 NO
 */
@property(nonatomic , assign)BOOL releaseOnMainThread;
/**
 是否在子线程中释放对象，默认为 YES
 */
@property(nonatomic , assign)BOOL releaseOnAsyncThread;

/**
 缓存中是否有 key 对应的 value

 @param key 要查找的对象的 key 值
 @return 是否含有对象
 */
- (BOOL)containObjectForKey:(id)key;

/**
 查找 key 对应的 value

 @param key 要查找对象的 key
 @return 查找到的 value ，如果没有查找到，返回 nil
 */
- (nullable id )objectForKey:(id)key;

/**
 设置缓存

 @param object 要缓存的对象，如果为 nil ， 则会调用 removeObjectForKey 删除这个 key 对应的 value
 @param key 缓存对象对应的 key
 */
- (void)setObject:(nullable id)object forKey:(id)key;

/**
 设置缓存，携带消耗大小

 @param object 缓存对象
 @param key key
 @param cost 消耗
 */
-(void)setObject:(id)object forKey:(id)key withCost:(NSUInteger)cost;

/**
 删除 key 对应的 value

 @param key 要删除的对象对应的 key
 */
- (void)removeObjectForKey:(id)key;

/**
 清空缓存
 */
- (void)removeAllObjects;

/**
 从缓存中删除对象，一直到 totalCount <= 指定的值

 @param count 允许在缓存中存储的最大数量
 */
- (void)trimToCount:(NSUInteger)count;

/**
 从缓存中删除对象，一直到 totalCost <= 指定的总内存大小

 @param cost 缓存的总开销大小
 */
- (void)trimToCost:(NSUInteger)cost;

/**
 从缓存中删除对象，把超过过期时间的对象都删除

 @param age 过期时间
 */
- (void)trimToAge:(NSTimeInterval)age;

@end
NS_ASSUME_NONNULL_END
