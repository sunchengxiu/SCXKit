//
//  RCDataCache.m
//  RCCache
//
//  Created by 孙承秀 on 2018/7/2.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCDataCache.h"
#import "RCDiskCache.h"
#import "RCMemoryCache.h"
#define WEAK __weak typeof(self)weakSelf = self;
#define STRONG __strong typeof(weakSelf)strongSelf = weakSelf;
@implementation RCDataCache
-(instancetype)init{
    @throw [NSException exceptionWithName:@"RCDataCache init error" reason:@"please" userInfo:nil];
    return [self initWithPath:@""];
}
-(instancetype)initWithName:(NSString *)name{
    if (name.length == 0) {
        return nil;
    }
    NSString *cachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [cachePath stringByAppendingPathComponent:name];
    return [self initWithPath:path];
}
-(instancetype)initWithPath:(NSString *)path{
    if (path.length == 0 ) {
        return nil;
    }
    RCDiskCache *diskCache = [[RCDiskCache alloc] initWithPath:path];
    if (!diskCache) {
        return nil;
    }
    NSString *name = [path lastPathComponent];
    RCMemoryCache *memoryCache = [[RCMemoryCache alloc] init];
    memoryCache.name = name;
    if (self = [super init]) {
        _name = name;
        _diskCache = diskCache;
        _memoryCache = memoryCache;
    }
    return self;
}
+(instancetype)cacheWithName:(NSString *)name{
    return [[self alloc] initWithName:name];
}
+(instancetype)cacheWithPath:(NSString *)path{
    return [[self alloc] initWithPath:path];
}
-(BOOL)containObjectForKey:(NSString *)key{
    return ([_memoryCache containObjectForKey:key] || [_diskCache containObjectForKey:key]);
}
-(void)containObjectForKey:(NSString *)key block:(void (^)(NSString * _Nonnull, BOOL))block{
    if (!block) {
        return;
    }
    if ([_memoryCache containObjectForKey:key]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (block) {
                block(key , YES);
            }
        });
    } else {
        return [_diskCache containObjectForKey:key withBlock:block];
    }
}
-(id<NSCoding>)objectForKey:(NSString *)key{
    if (!key) {
        return nil;
    }
    id object = [_memoryCache objectForKey:key];
    if (!object) {
        object = [_diskCache objectForKey:key];
        if (object) {
            [_memoryCache setObject:object forKey:key];
        }
    }
    return object;
}
-(void)objectForKey:(NSString *)key block:(void (^)(NSString * _Nonnull, id<NSCoding> _Nonnull))block{
    if (!key || !block) {
        return;
    }
    id object = [_memoryCache objectForKey:key];
    if (object) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (block) {
                block(key , object);
            }
        });
    } else {
        WEAK
        [_diskCache objectForKey:key withBlock:^(NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
            STRONG
            if (strongSelf) {
                if (object && ![strongSelf.memoryCache objectForKey:key]) {
                    [strongSelf.memoryCache setObject:object forKey:key];
                }
                if (block) {
                    block(key,object);
                }
            }
           
        }];
    }
}
-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key{
    [_memoryCache setObject:object forKey:key];
    [_diskCache setObject:object forKey:key];
}
-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key block:(void (^)(void))block{
    [_memoryCache setObject:object forKey:key];
    [_diskCache setObject:object forKey:key withBlock:block];
}
-(void)removeObjectForKey:(NSString *)key{
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key];
}
-(void)removeObjectForKey:(NSString *)key block:(void (^)(NSString * _Nonnull))block{
    [_memoryCache removeObjectForKey:key];
    [_diskCache removeObjectForKey:key withBlock:block];
}
-(void)removeAllObjects{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjects];
}
-(void)removeAllObjectsWithBlock:(void (^)(void))block{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjectsWithBlock:block];
}
-(void)removeAllObjectsWithProgressBlock:(void (^)(int, int))progressBlock endBlock:(void (^)(BOOL))endBlock{
    [_memoryCache removeAllObjects];
    [_diskCache removeAllObjectsWithProgressBlock:progressBlock endBlock:endBlock];
}
@end
