//
//  RCStorage.h
//  RCCache
//
//  Created by 孙承秀 on 2018/6/26.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger , RCCacheType) {
    RCCacheTypeFile = 0,
    RCCacheTypeSqlite = 1,
    RCCacheTypeMixed = 2,
};

@interface RCCacheItem : NSObject
/**
 key
 */
@property(nonatomic , copy )NSString *key;
/**
 data
 */
@property(nonatomic , strong)NSData *value;
/**
 file name
 */
@property(nonatomic , copy)NSString *fileName;
/**
 file size
 */
@property(nonatomic , assign)int size;
/**
 modify time
 */
@property(nonatomic , assign)int modifyTime;
/**
 access time
 */
@property(nonatomic , assign)int accessTime;
/**
 extended data
 */
@property(nonatomic , strong)NSData *extendedData;


@end

@interface RCStorage : NSObject
/**
 path
 */
@property(nonatomic , copy , readonly)NSString *path;
/**
 是否开启错误 log
 */
@property(nonatomic , assign)BOOL logEnable;
/**
 缓存种类
 */
@property(nonatomic , assign , readonly)RCCacheType cacheType;
// 不应该使用下面这两种方式初始化
-(instancetype)init UNAVAILABLE_ATTRIBUTE;
+(instancetype)new UNAVAILABLE_ATTRIBUTE;

/**
 初始化方法

 @param path 数据库路径
 @param type 存储类型
 @return 实例
 */
- (nullable instancetype)initWithPath:(NSString *)path type:(RCCacheType)type NS_DESIGNATED_INITIALIZER;

/**
 保存或者更新数据，如果已经存在则更新
 @discussion 如果“type”是“RCCacheTypeFile”，则 fileName 不能为空 ， 如果 type 是 RCCacheTypeSqlite，则忽略 fileName ， 如果 type 是 RCCacheTypeMixed ， 如果 fileName 不为空，则先保存到文件，如果 fileName 为空，则会保存到数据库

 @param item 要保存的数据
 @return 是否保存成功
 */
- (BOOL)saveItem:(RCCacheItem *)item;

/**
 将数据存储到数据库，如果 type 是 RCCacheTypeFile ， 则这个方法会失败

 @param key key，不能为空
 @param value value 不能为空
 @return 是否存储成功
 */
- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value;

/**
 保存或者更新 item
 
 @discussion 如果 type 为 RCCacheTypeFile，则 fileName 不能为空 ， 如果 type 为 RCCacheTypeSqlite ， 则会忽略 fileName ， 如果 type 为 RCCacheTypeMixed ， 如果 fileName 不为空，则会保存到文件，如果为空，则会保存到数据库

 @param key key 不能为空
 @param value value 不能为空
 @param fileName fileName 
 @param extendedData 扩展数据，如果传 nil ，则会忽略
 @return 是否保存成功
 */
- (BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value fileName:(nullable NSString *)fileName extendedData:(nullable NSData *)extendedData;

/**
 删除数据

 @param key key
 @return 是否删除成功
 */
- (BOOL)removeItemWithKey:(NSString *)key;

/**
 批量移除数据

 @param keys 批量 key
 @return 是否移除成功
 */
- (BOOL)removeItemsWithKeys:(NSArray<NSString *> *)keys;

/**
 移除所有大小大于指定 size 大小的数据

 @param size 指定的限制大小
 @return 是否删除成功
 */
- (BOOL)removeItemsForSizeLargerThan:(int)size;

/**
 删除过旧的数据，这些数据比指定的 time 时间要早

 @param time 指定的访问时间
 @return 是否删除成功
 */
- (BOOL)removeItemsForTimeEarlierThan:(int)time;

/**
 删除一些数据，去响应指定好的大小
 删除策略：LRU，删除最近使用频率较低的数据

 @param size 指定的缓存大小
 @return 是否删除成功
 */
- (BOOL)removeItemsToFitSize:(int)size;

/**
 删除一些数据，去响应指定好的缓存数量

 @param count 指定好的数量
 @return 是否删除成功
 */
- (BOOL)removeItemsToFitCount:(int)count;

/**
 移除所有的数据，这个方法会先把数据移到垃圾箱中，然后在后台线程把数据清理掉，所以速度要比 快。

 @return 是否删除成功
 */
- (BOOL)removeAllItems;

/**
 删除所有的数据（有进度返回）

 @param progressBlock 以 block 的形式返回进度
 @param endBlock 结束 block
 */
- (void)removeAllItemsWithProgress:(nullable void (^)(int removedCount , int totalCount))progressBlock endBlock:(nullable void (^)(BOOL error))endBlock;

/**
 根据 key 获取指定 item

 @param key key
 @return item,如果为空，原因可能是为空或者发生错误
 */
- (nullable RCCacheItem *)getItemForKey:(NSString *)key;

/**
 根据 key 获取指定的 item（不包含 value）

 @param key key
 @return item,如果为空，原因可能是为空或者发生错误
 */
- (nullable RCCacheItem *)getItemInfoForKey:(NSString *)key;

/**
 根据 key，获取指定的 item 的 value

 @param key key
 @return item 的 value
 */
- (nullable NSData *)getItemValueForKey:(NSString *)key;

/**
 批量获取 item

 @param keys keys
 @return 对应的 item 数组
 */
- (nullable NSArray<RCCacheItem *> *)getItemsForKeys:(NSArray<NSString *> *)keys;

/**
 批量获取 item info

 @param keys keys
 @return item info 数组
 */
- (nullable NSArray<RCCacheItem *> *)getItemInfosForKeys:(NSArray<NSString *> *)keys;

/**
 批量获取所有 key 对应的 value

 @param keys keys
 @return 对应的 value
 */
- (nullable NSDictionary<NSString * , NSData *> *)getItemValuesForKeys:(NSArray<NSString *> *)keys;

/**
 是否存在某个 key 对应的 value

 @param key key
 @return 是否存在
 */
- (BOOL)itemExistsForKey:(NSString *)key;

/**
 获取所有 items 的 count

 @return 总量
 */
- (int)getItemsCount;

/**
 获取所有 items 的 size

 @return 总 size
 */
- (int)getItemsSize;
@end
NS_ASSUME_NONNULL_END
