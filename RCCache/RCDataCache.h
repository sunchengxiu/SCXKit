//
//  RCDataCache.h
//  RCCache
//
//  Created by 孙承秀 on 2018/7/2.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RCMemoryCache,RCDiskCache;
NS_ASSUME_NONNULL_BEGIN
@interface RCDataCache : NSObject
/**
 缓存的名字
 */
@property(nonatomic , copy , readonly)NSString *name;
/**
 内存缓存
 */
@property(nonatomic , strong , readonly)RCMemoryCache *memoryCache;
/**
 磁盘缓存
 */
@property(nonatomic , strong , readonly)RCDiskCache *diskCache;

/**
 使用一个名字，初始化一个缓存对象

 @param name 缓存的名字
 @return 缓存对象
 */
- (nullable instancetype)initWithName:(NSString *)name;

/**
 初始化一个缓存对象

 @param path 缓存的路径
 @return 缓存对象
 */
- (nullable instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

/**
 类方法初始化一个缓存对象

 @param name 缓存的名字
 @return 缓存对象
 */
+ (nullable instancetype)cacheWithName:(NSString *)name;

/**
 类方法初始化一个缓存对象

 @param path 缓存路径
 @return 缓存对象
 */
+ (nullable instancetype)cacheWithPath:(NSString *)path;

/**
 根据 key 查询缓存中是否含有该 key 对应的数据,该方法可能会阻塞当前线程

 @param key key
 @return 是否含有
 */
- (BOOL)containObjectForKey:(NSString *)key;

/**
 根据 key 查询缓存中是否含有该 key 对应的数据,该方法不会阻塞当前线程，通过 block 返回

 @param key key
 @param block 异步 block 返回
 */
- (void)containObjectForKey:(NSString *)key block:(nullable void (^)(NSString *key,BOOL contains))block;

/**
 根据指定 key ，获取缓存中已经存储的数据，该方法可能会阻塞当前线程

 @param key key
 @return 缓存中已经存在的数据
 */
- (nullable id<NSCoding>)objectForKey:(NSString *)key;

/**
  根据指定 key ，获取缓存中已经存储的数据，该方法不会阻塞当前线程，异步 block 返回

 @param key key
 @param block 异步 block 返回数据
 */
- (void)objectForKey:(NSString *)key block:(nullable void (^)(NSString *key , id<NSCoding> object))block;

/**
 存储数据到缓存中，该方法可能会阻塞当前线程，如果 object 为 nil，则会通过 remove 方法移除该 key 对应的对象

 @param object 存储的对象
 @param key 存储对象对应的 key
 */
- (void)setObject:(id <NSCoding>)object forKey:(NSString *)key;

/**
 存储数据到缓存中，该方法不会阻塞当前线程,如果 object 为 nil，则会通过 remove 方法移除该 key 对应的对象.

 @param object 要存储的对象
 @param key key
 @param block 异步 block 返回
 */
- (void)setObject:(id <NSCoding>)object forKey:(NSString *)key block:(nullable void (^)(void))block;

/**
 移除 key 对应的缓存数据，该方法可能会阻塞当前线程

 @param key key
 */
- (void)removeObjectForKey:(NSString *)key;

/**
  移除 key 对应的缓存数据，该方法可能会阻塞当前线程,该方法不会阻塞当前线程

 @param key key
 @param block 异步 block 返回
 */
- (void)removeObjectForKey:(NSString *)key block:(nullable void (^)(NSString *key))block;

/**
 清空缓存，该方法可能会阻塞当前线程
 */
- (void)removeAllObjects;

/**
  清空缓存，该方法不会阻塞当前线程

 @param block 异步 block 返回
 */
- (void)removeAllObjectsWithBlock:(void (^)(void))block;

/**
 清空缓存，带有进度返回

 @param progressBlock 异步进度回调
 @param endBlock 结束 block
 */
- (void)removeAllObjectsWithProgressBlock:(nullable void (^)(int removedCount , int totalCount))progressBlock endBlock:(nullable void (^)(BOOL error))endBlock;

/**
 总的内存缓存的数量

 @return 缓存的总数量
 */
- (int)totalMemoryCacheCount;

/**
 总的磁盘缓存的数量
 
 @return 缓存的总数量
 */
- (int)totalDiskCahceCount;

/**
 总的没存开销大小

 @return 总开销
 */
- (int)totalMemoryCacheCost;

- (int)totalDiskCacheCost;


// 不能使用一下两个方法初始化
-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;
// 不能使用以上两个方法初始化

@end
NS_ASSUME_NONNULL_END
