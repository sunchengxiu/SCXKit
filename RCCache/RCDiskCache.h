//
//  RCDiskCache.h
//  RCCache
//
//  Created by 孙承秀 on 2018/6/26.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN
@interface RCDiskCache : NSObject
/**
 disk cache name
 */
@property(nullable,nonatomic , copy)NSString *name;
/**
 cache path
 */
@property(nonatomic , copy , readonly)NSString *path;
/**
 阀值
 */
@property(nonatomic , assign)NSUInteger threshold;
/**
 自定义数据的归档，可以使用这个 block 来实现自定义归档而不用实现 NSCoding 协议
 */
@property(nullable,nonatomic , copy)NSData *(^CustomArchiveBlock)(id object);
/**
 自定义数据解档，可以使用这个 block 来自定义实现数据的解档而不用实现 NSCoding 协议
 */
@property(nullable, nonatomic , copy)id (^CustomUnArchiveBlock)(NSData *data);
/**
 如果一个对象需要被保存为一个对象的时候，那么可以使用这个 block 来生成对应的文件名，如果为 nil ，则内部会使用 MD5 来生成默认的文件名
 */
@property(nonatomic , copy)NSString *(^CustomGenerateFileNameBlock)(NSString *key);
/**
 最大数量限制，如果为 NSUIntegerMax，则表示没有限制
 */
@property(nonatomic , assign)NSUInteger limitCount;
/**
 最大成本数，如果为 NSUIntegerMax 则没有限制。
 */
@property(nonatomic , assign)NSUInteger limitCost;
/**
 最大过期时间，如果为 DBL_MAX ，则表示咩有限制
 */
@property(nonatomic , assign)NSTimeInterval limitAge;
/**
 磁盘最小可用空间，如果磁盘空间低于此值，则会删除一些对象
 */
@property(nonatomic , assign)NSUInteger minLimitDiskSpace;
/**
 自动轮询时间，默认为 60s，每隔 60s 就会检查是否到达某个极限，来开始驱逐对象
 */
@property(nonatomic , assign)NSTimeInterval autoPollingTime;
/**
 是否开启错误 log 提示
 */
@property(nonatomic , assign)BOOL logEnable;
- (instancetype)init UNAVAILABLE_ATTRIBUTE;
+ (instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 初始化一个数据库对象，如果指定路径的缓存实例已经存在于内存中，那么这个方法会直接返回，否则会创建一个新实例。

 @param path 存储路径
 @return 数据库对象
 */
- (instancetype)initWithPath:(NSString *)path;

/**
 初始化一个数据库对象,并带有阀值，如果指定路径的缓存实例已经存在于内存中，那么这个方法会直接返回，否则会创建一个新实例。

 @param path 存储路径
 @param threshold 阀值，如果数据大小大于这个阀值，会被存储到文件中，否则会被存储到数据库中，0 表示所有的数据都存储在文件中，NSUintegerMax 表示所有的数据都存储在数据库中，如果不知道阀值是多少 20480 字节是一个不错的选择
 @return 数据库对象
 */
- (instancetype)initWithPath:(NSString *)path threshold:(NSUInteger)threshold NS_DESIGNATED_INITIALIZER;

/**
 缓存中是否存在指定 key 对应的对象，如果 key 为 nil，则返回 nil,此方法可能会阻塞当前线程，知道数据读取完成

 @param key key
 @return 是否包含
 */
- (BOOL)containObjectForKey:(NSString *)key;

/**
  缓存中是否存在指定 key 对应的对象，如果 key 为 nil，则返回 nil,此方法不会阻塞当前线程

 @param key key
 @param block 后台 block 返回
 */
- (void)containObjectForKey:(NSString *)key withBlock:(void (^)(NSString *key , BOOL contains))block;

/**
 返回指定 key 对应的缓存对象，此方法可能会阻塞当前线程，知道数据读取完成

 @param key key
 @return key 对应的对象
 */
- (nullable id<NSCoding>)objectForKey:(NSString *)key;

/**
 返回指定 key 对应的缓存对象,此方法不会阻塞当前线程

 @param key key
 @param block 后台通过 block 返回
 */
- (void)objectForKey:(NSString *)key withBlock:(void (^)(NSString *key , id<NSCoding> __nullable object))block;

/**
 设置缓存，此方法可能会阻塞当前线程，直到数据写入完成

 @param object 缓存的对象，如果为空，则会调用 remove 方法，移除key对应的老数据
 @param key 缓存的 key ，不能为空
 */
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key;

/**
 设置缓存，此方法不会阻塞当前线程
 
 @param object 缓存的对象，如果为空，则会调用 remove 方法，移除key对应的老数据
 @param key 缓存的 key ，不能为空
 @param block 后台 block 返回
 */
- (void)setObject:(nullable id<NSCoding>)object forKey:(NSString *)key withBlock:(void (^)(void))block;

/**
 移除 key 对应的对象，此方法可能会阻塞当前线程

 @param key key
 */
- (void)removeObjectForKey:(NSString *)key;

/**
 移除 key 对应的对象，此方法可能bu会阻塞当前线程

 @param key key
 @param block 后台 block 返回
 */
- (void)removeObjectForKey:(NSString *)key withBlock:(void (^)(NSString *key))block;

/**
 清空缓存，此方法可能会阻塞当前线程
 */
- (void)removeAllObjects;

/**
 清空缓存，此方法不会阻塞当前线程

 @param block 后台 block 返回
 */
-(void)removeAllObjectsWithBlock:(void (^)(void))block;


/**
 清空缓存，并带有进度，此方法不会阻塞当前线程

 @param progressBlock 进度 block
 @param endBlock end block
 */
- (void)removeAllObjectsWithProgressBlock:(nullable void (^)(int removedCount , int totalCount))progressBlock endBlock:(nullable void (^)(BOOL error))endBlock;

/**
 获取缓存的总个数，此方法可能会阻塞当前线程

 @return 总个数
 */
- (NSUInteger)totalCount;

/**
 获取缓存的总个数,此方法可能不会阻塞当前线程

 @param block 后台 block 返回
 */
- (void)totalCountWithBlock:(void (^)(NSUInteger total))block;

/**
 获取缓存的总开销，此方法可能会阻塞当前线程

 @return 总开销
 */
- (NSUInteger)totalCost;

/**
 获取缓存的总开销，此方法不会阻塞当前线程
 
 @param block 后台线程返回
 */
- (void)totalCostWithBlock:(void (^)(NSUInteger total))block;

/**
 驱逐对象以达到指定的个数限制,这个方法可能会阻塞当前线程，直到符合限制的要求

 @param limitCount 个数限制
 */
- (void)trimToCount:(NSUInteger)limitCount;

/**
 驱逐对象以达到指定的个数限制,这个方法不会阻塞当前线程

 @param limitCount 个数限制
 @param block 后台 block 返回
 */
- (void)trimToCount:(NSUInteger)limitCount withBlock:(void (^)(void))block;

/**
 驱逐对象，以达到指定的开销大小，此方法可能会阻塞当前线程

 @param limitCost 开销总大小限制
 */
- (void)trimToCost:(NSUInteger)limitCost;

/**
 驱逐对象，以达到指定的开销大小，此方法可能会阻塞当前线程

 @param limitCost 开销总限制
 @param block 后台 block 返回
 */
- (void)trimToCost:(NSUInteger)limitCost withBlock:(void (^)(void))block;

/**
 驱逐指定过期时间之前所有的数据,此方法可能会阻塞当前线程，知道数据驱逐完成

 @param age 过期时间
 */
- (void)trimToAge:(NSTimeInterval)age;

/**
 驱逐指定过期时间之前所有的数据，此方法可能不会阻塞当前线程

 @param age 过期时间
 @param block 后台 block 返回
 */
- (void)trimToAge:(NSTimeInterval)age withBlock:(void (^)(void))block;
+ (nullable NSData *)getExtendedDataFromObject:(id)object;
+ (void)setExtendedData:(nullable NSData *)data toObject:(id)object;
@end
NS_ASSUME_NONNULL_END
