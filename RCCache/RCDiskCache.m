//
//  RCDiskCache.m
//  RCCache
//
//  Created by 孙承秀 on 2018/6/26.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCDiskCache.h"
#import "RCStorage.h"
#import <UIKit/UIKit.h>
#import <objc/message.h>
#include <CommonCrypto/CommonCrypto.h>

#pragma mark - 全局设置
#define Lock() dispatch_semaphore_wait(self->_lock, DISPATCH_TIME_FOREVER)
#define Unlock() dispatch_semaphore_signal(self->_lock)
#define WEAK __weak typeof(self)weakSelf = self;
#define STRONG __strong typeof(weakSelf)strongSelf = weakSelf;
static dispatch_semaphore_t _globalLock;
static NSMapTable *_globalMap;
static const int excludedData;

static int16_t diskCacheFreeSpace(){
    NSError *error = nil;
    NSDictionary *dic = [[NSFileManager defaultManager] attributesOfItemAtPath:NSHomeDirectory() error:&error];
    if (error) {
        return -1;
    }
    int64_t space = [[dic objectForKey:NSFileSystemFreeSize] longLongValue];
    if (space < 0) {
        space = -1;
    }
    return space;
}
static void globalInit(){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _globalMap = [NSMapTable mapTableWithKeyOptions:(NSPointerFunctionsStrongMemory) valueOptions:NSPointerFunctionsWeakMemory ];
        _globalLock = dispatch_semaphore_create(1);
    });
}
static RCDiskCache *getCacheFromGlobal(NSString *path){
    if (path.length <= 0 ) {
        return nil;
    }
    globalInit();
    dispatch_semaphore_wait(_globalLock, DISPATCH_TIME_FOREVER);
    RCDiskCache *cache = [_globalMap objectForKey:path];
    dispatch_semaphore_signal(_globalLock);
    return cache;
}
static void setCacheToGlobal(RCDiskCache *cache){
    if (cache.path.length == 0) {
        return;
    }
    globalInit();
    dispatch_semaphore_wait(_globalLock, DISPATCH_TIME_FOREVER);
    [_globalMap setObject:cache forKey:cache.path];
    dispatch_semaphore_signal(_globalLock);
}
@implementation RCDiskCache{
    RCStorage *_storage;
    dispatch_semaphore_t _lock;
    dispatch_queue_t _queue;
}
- (void)autoPolling{
    WEAK
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_autoPollingTime * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        STRONG
        if (!strongSelf) {
            return ;
        }
        [strongSelf trimOnBackground];
        [self autoPolling];
    });
}
- (void)trimOnBackground{
    WEAK
    dispatch_async(_queue, ^{
        STRONG
        if (!strongSelf) {
            return ;
        }
        Lock();
        [self _trimToAge:strongSelf.limitAge];
        [self _trimToCost:strongSelf.limitCost];
        [self _trimToCount:strongSelf.limitCount];
        [self _trimToTargetDiskSpace:strongSelf.minLimitDiskSpace];
        Unlock();
    });
}
-(void)_trimToAge:(NSTimeInterval)age{
    if (age <= 0) {
        [_storage removeAllItems];
        return;
    }
    int current = (int)time(NULL);
    if (age > current) {
        return;
    }
    long time = current - age;
    if (time >= INT_MAX) {
        return;
    }
    [_storage removeItemsForTimeEarlierThan:age];
}
-(void)_trimToCost:(NSUInteger)limitCost{
    if (limitCost >= INT_MAX) {
        return;
    }
    [_storage removeItemsToFitSize:(int)limitCost];
}
-(void)_trimToCount:(NSUInteger)limitCount{
    if (limitCount >= INT_MAX) {
        return;
    }
    [_storage removeItemsToFitCount:(int)limitCount];
}
- (void)_trimToTargetDiskSpace:(NSUInteger)space{
    if (space == 0 ) {
        return;
    }
    int64_t diskSpace = diskCacheFreeSpace();
    if (diskSpace <= 0) {
        return;
    }
    int64_t itemSize = [_storage getItemsSize];
    if (itemSize <= 0) {
        return;
    }
    int64_t left = space - diskSpace;
    if (left <= 0 ) {
        return;
    }
    int64_t itemLeft = itemSize - left;
    if (itemLeft <= 0) {
        itemLeft = 0;
    }
    [self _trimToCost:(int)itemLeft];
}
- (void)_appWillBeTerminated{
    Lock();
    _storage = nil;
    Unlock();
}
- (NSString *)_fileName:(NSString *)key{
    NSString *fileName = nil;
    if (self.CustomGenerateFileNameBlock) {
        self.CustomGenerateFileNameBlock(key);
    }
    if (!fileName) {
        fileName = [self md5String:key];
    }
    return fileName;
}
- (NSString *)md5String:(NSString *)md5 {
    NSData *data = [md5 dataUsingEncoding:NSUTF8StringEncoding];
    return [self getMd5String:data];
}
- (NSString *)getMd5String:(NSData *)data {
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(data.bytes, (CC_LONG)data.length, result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}
#pragma mark - public
-(instancetype)init{
    @throw [NSException exceptionWithName:@"RCDiskCache init error" reason:@"please use initwithpath" userInfo:nil];
    return [self initWithPath:@""];
}
-(instancetype)initWithPath:(NSString *)path{
    return [self initWithPath:path threshold:20 * 1024];
}
-(instancetype)initWithPath:(NSString *)path threshold:(NSUInteger)threshold{
    if (self = [super init]) {
        RCDiskCache *cache = getCacheFromGlobal(path);
        if (cache) {
            return cache;
        }
        RCCacheType type = 0;
        if (threshold == 0) {
            type = RCCacheTypeFile;
        } else if (threshold == NSUIntegerMax  ){
            type = RCCacheTypeSqlite;
        } else {
            type = RCCacheTypeMixed;
        }
        RCStorage *storage = [[RCStorage alloc] initWithPath:path type:type];
        if (!storage) {
            return nil;
        }
        _storage = storage;
        _path = path;
        _threshold = threshold;
        _lock = dispatch_semaphore_create(1);
        _queue = dispatch_queue_create("https://github.com/sunchengxiu/RCCache.git.diskQueue", DISPATCH_QUEUE_CONCURRENT);
        _limitAge = DBL_MAX;
        _limitCost = NSUIntegerMax;
        _limitCount = NSUIntegerMax;
        _minLimitDiskSpace = 0;
        _autoPollingTime = 60;
        
        [self autoPolling];
        setCacheToGlobal(self);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appWillBeTerminated) name:UIApplicationWillTerminateNotification object:nil];
    }
    return self;
}
-(BOOL)containObjectForKey:(NSString *)key{
    if (key.length <= 0) {
        return NO;
    }
    Lock();
    BOOL exist = [_storage itemExistsForKey:key];
    Unlock();
    return exist;
}
-(void)containObjectForKey:(NSString *)key withBlock:(void (^)(NSString * _Nonnull, BOOL))block{
    if (!block) {
        return;
    }
    WEAK
    dispatch_async(_queue, ^{
        STRONG;
        if (!strongSelf) {
            return ;
        }
        BOOL exist = [strongSelf containObjectForKey:key];
        if (block) {
            block(key,exist);
        }
    });
}
-(id<NSCoding>)objectForKey:(NSString *)key{
    if (!key) {
        return nil;
    }
    Lock();
    RCCacheItem *item = [_storage getItemForKey:key];
    Unlock();
    if (!item.value) {
        return nil;
    }
    id object = nil;
    if (self.CustomUnArchiveBlock) {
        object= self.CustomUnArchiveBlock(item.value);
    } else {
        @try {
            object = [NSKeyedUnarchiver unarchiveObjectWithData:item.value];
        } @catch (NSException *exception) {
            NSLog(@"----");
        } @finally {
            
        }
    }
    if (object && item.extendedData) {
        [RCDiskCache setExtendedData:item.extendedData toObject:object];
    }
    return object;
}
-(void)objectForKey:(NSString *)key withBlock:(void (^)(NSString * _Nonnull, id<NSCoding> _Nullable))block{
    WEAK
    dispatch_async(_queue, ^{
        STRONG
        if (!strongSelf) {
            return ;
        } else {
            id<NSCoding>obj =  [self objectForKey:key];
            if (block) {
                block(key,obj);
            } else {
                
            }
        }
    });
}
-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key{
    if (!key) {
        return;
    } else {
        if (object == nil) {
            [self removeObjectForKey:key];
            return;
        }
        NSData *data = [RCDiskCache getExtendedDataFromObject:object];
        NSData * value = nil;
        if (self.CustomArchiveBlock) {
            value = self.CustomArchiveBlock(object);
        } else {
            @try {
                value = [NSKeyedArchiver archivedDataWithRootObject:object];
            } @catch (NSException *exception) {
                
            } @finally {
                
            }
        }
        if (!value) {
            return;
        } else {
            NSString *fileName = nil;
            if (_storage.cacheType != RCCacheTypeSqlite) {
                if (value.length > _threshold) {
                    fileName = [self _fileName:key];
                }
            }
            Lock();
            [_storage saveItemWithKey:key value:value fileName:fileName extendedData:data];
            Unlock();
        }
    }
}
-(void)setObject:(id<NSCoding>)object forKey:(NSString *)key withBlock:(void (^)(void))block{
    WEAK
    dispatch_async(_queue, ^{
        STRONG;
        if (!strongSelf) {
            return ;
        } else {
            [strongSelf setObject:object forKey:key];
            if (block) {
                block();
            }
        }
    });
}
-(void)removeObjectForKey:(NSString *)key{
    if (!key) {
        return;
    }
    Lock();
    [_storage removeItemWithKey:key];
    Unlock();
}
-(void)removeObjectForKey:(NSString *)key withBlock:(void (^)(NSString * _Nonnull))block{
    WEAK
    dispatch_async(_queue, ^{
        STRONG
        if (!strongSelf) {
            return ;
        }
        [strongSelf removeObjectForKey:key];
        if (block) {
            block(key);
        }
    });
}
-(void)removeAllObjects{
    Lock();
    [_storage removeAllItems];
    Unlock();
}
-(void)removeAllObjectsWithBlock:(void (^)(void))block{
    WEAK
    dispatch_async(_queue, ^{
        STRONG
        if (!strongSelf) {
            return ;
        }
        [strongSelf removeAllObjects];
        if (block) {
            block();
        }
    });
}
-(void)removeAllObjectsWithProgressBlock:(void (^)(int, int))progressBlock endBlock:(void (^)(BOOL))endBlock{
    WEAK
    dispatch_async(_queue, ^{
       STRONG
        if (!strongSelf) {
            return ;
        }
        Lock();
        [strongSelf->_storage removeAllItemsWithProgress:progressBlock endBlock:endBlock];
        Unlock();
    });
}
-(NSUInteger)totalCost{
    Lock();
    int cost = [_storage getItemsSize];
    Unlock();
    return cost;
}
-(void)totalCostWithBlock:(void (^)(NSUInteger))block{
    if (!block) {
        return;
    } else {
        WEAK
        dispatch_async(_queue, ^{
            STRONG
            if (!strongSelf) {
                return ;
            } else {
                int cost = (int)[strongSelf totalCost];
                if (block) {
                    block(cost);
                } else {
                    
                }
            }
        });
    }
}
-(NSUInteger)totalCount{
    Lock();
    int count = (int)[_storage getItemsCount];
    Unlock();
    return count;
}
-(void)totalCountWithBlock:(void (^)(NSUInteger))block{
    if (!block) {
        return;
    } else {
        WEAK
        dispatch_async(_queue, ^{
            STRONG
            if (!strongSelf) {
                return ;
            } else {
                int count = (int)[strongSelf totalCount];
                if (block) {
                    block(count);
                } else {
                    
                }
            }
        });
    }
}
-(void)trimToCount:(NSUInteger)limitCount{
    Lock();
    [self _trimToCount:limitCount];
    Unlock();
}
-(void)trimToCount:(NSUInteger)limitCount withBlock:(void (^)(void))block{
    WEAK
    dispatch_async(_queue, ^{
       STRONG
        if (!strongSelf) {
            return ;
        }
        [strongSelf trimToCount:limitCount];
        if (block) {
            block();
        } else {
            
        }
    });
}
-(void)trimToCost:(NSUInteger)limitCost{
    Lock();
    [self _trimToCost:limitCost];
    Unlock();
}
-(void)trimToCost:(NSUInteger)limitCost withBlock:(void (^)(void))block{
    WEAK
    dispatch_async(_queue, ^{
        STRONG
        if (!strongSelf) {
            return ;
        }
        [strongSelf trimToCost:limitCost];
        if (block) {
            block();
        }
    });
}
-(void)trimToAge:(NSTimeInterval)age{
    Lock();
    [self _trimToAge:age];
    Unlock();
}
-(void)trimToAge:(NSTimeInterval)limitCost withBlock:(void (^)(void))block{
    WEAK
    dispatch_async(_queue, ^{
        STRONG
        if (!strongSelf) {
            return ;
        }
        [strongSelf trimToCost:limitCost];
        if (block) {
            block();
        }
    });
}
-(void)setLogEnable:(BOOL)logEnable{
    Lock();
    _storage.logEnable = logEnable;
    Unlock();
}
-(BOOL)logEnable{
    Lock();
    BOOL enable = _storage.logEnable;
    Unlock();
    return enable;
}
+(void)setExtendedData:(NSData *)data toObject:(id)object{
    objc_setAssociatedObject(object, &excludedData, data, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
+(NSData *)getExtendedDataFromObject:(id)object{
    NSData *data = objc_getAssociatedObject(object, &excludedData);
    return data;
}
-(void)dealloc{
     [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
}
@end
