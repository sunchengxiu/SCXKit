//
//  RCStorage.m
//  RCCache
//
//  Created by 孙承秀 on 2018/6/26.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCStorage.h"
#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <time.h>
#if __has_include(<sqlite3.h>)
#import <sqlite3.h>
#else
#import "sqlite3.h"
#endif

#define KMAXERRORCOUNT 8
#define KMINRETRYTIME 2.0
static NSString *const KDBFileName = @"RCSqliteCache.sqlite";
static NSString *const KDBShmFileName = @"RCSqliteCache.sqlite-shm";
static NSString *const KDBWalFileName = @"RCSqliteCache.sqlite-wal";
static NSString *const KDataDirectoryName = @"data";
static NSString *const KTrashDirectoryName = @"trash";
static const int KPathLengthMax = PATH_MAX - 64;

@implementation RCStorage{
    dispatch_queue_t _trashQueue;
    
    NSString *_path;
    NSString *_dbPath;
    NSString *_dataPath;
    NSString *_trashPath;
    
    NSTimeInterval _lastErrorTime;
    NSUInteger _errorCount;
    
    sqlite3 *_db;
    CFMutableDictionaryRef _stmtCache;
}
#pragma mark - private

/**
 开启数据库

 @return 是否开启成功
 */
- (BOOL)openDB{
    if (_db) {
        return YES;
    }
    int result = sqlite3_open(_dbPath.UTF8String,&_db);
    if (result == SQLITE_OK) {
        _lastErrorTime = 0;
        _errorCount = 0;
        CFDictionaryKeyCallBacks keyCallbacks = kCFCopyStringDictionaryKeyCallBacks;
        CFDictionaryValueCallBacks valueCallbacks = {0};
        _stmtCache = CFDictionaryCreateMutable(CFAllocatorGetDefault(), 0, &keyCallbacks, &valueCallbacks);
        return YES;
    } else {
        _db = NULL;
        if (_stmtCache) {
            CFRelease(_stmtCache);
        }
        _stmtCache = NULL;
        _lastErrorTime = CACurrentMediaTime();
        _errorCount ++;
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d sqlite open failed:%d",__FUNCTION__,__LINE__,result);
        }
        return NO;
    }
}

/**
 关闭数据库

 @return 是否关闭成功
 */
- (BOOL)closeDB{
    if (!_db) {
        return YES;
    }
    BOOL retry = NO;
    BOOL stmtFinish = NO;
    do {
        retry = NO;
        int result = sqlite3_close(_db);
        if (result == SQLITE_BUSY || result == SQLITE_LOCKED) {
            if (!stmtFinish) {
                stmtFinish = YES;
                sqlite3_stmt *stmt;
                // 释放所有的 prepare 语句
                while ((stmt = sqlite3_next_stmt(_db,nil)) != 0 ) {
                    sqlite3_finalize(stmt);
                    retry = YES;
                }
            }
        } else if(result != SQLITE_OK){
            retry = NO;
            if (self.logEnable) {
                NSLog(@"Function :%s line:%d sqlite close failed:%d",__FUNCTION__,__LINE__,result);
            }
        }
    } while (retry);
    _db = NULL;
    return YES;
}

/**
 检查数据库
 */
- (BOOL)checkDB{
    if (_db) {
        return YES;
    } else {
        if (_errorCount < KMAXERRORCOUNT && (CACurrentMediaTime() - _lastErrorTime > KMINRETRYTIME) ) {
            return [self openDB] && [self initDB];
        } else {
            if (self.logEnable) {
                NSLog(@"Function :%s line:%d check DB failed",__FUNCTION__,__LINE__);
            }
            return NO;
        }
    }
}

/**
 创建数据库
 */
- (BOOL)initDB{
    NSString *sql = @"pragma journal_mode = wal; pragma synchronous = normal;create table if not exists RCSqliteCache(key text,fileName text,size integer,fileData blob,modifyTime integer,lastAccessTime integer , extendData data,primary key(key));create index if not exists lastAccessTime_index on RCSqliteCache(lastAccessTime);";
    return [self execute:sql];
}

- (BOOL)execute:(NSString *)sql{
    if (sql.length <= 0) {
        return NO;
    }
    if (![self checkDB]) {
        return NO;
    }
    char *error = NULL;
    int result = sqlite3_exec(_db,sql.UTF8String,NULL,NULL,&error);
    if (error != nil) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d excute sql failed:%s",__FUNCTION__,__LINE__,error);
            sqlite3_free(error);
        }
    }
    return result == SQLITE_OK;
}

/**
 数据库的 checkpoint
 */
- (void)checkPoint{
    if (![self checkDB]) {
        return;
    }
    sqlite3_wal_checkpoint(_db,NULL);
}

/**
 准备 sql
 */
- (sqlite3_stmt *)prepareStmt:(NSString *)sql{
    if (sql.length <= 0 || ![self checkDB] || !_stmtCache) {
        return NULL;
    }
    sqlite3_stmt *stmt = (sqlite3_stmt *)CFDictionaryGetValue(_stmtCache, (const void *)sql);
    if (stmt) {
        sqlite3_reset(stmt);
    } else {
        int result = sqlite3_prepare_v2(_db,sql.UTF8String,-1,&stmt,NULL);
        if (result != SQLITE_OK) {
            if (self.logEnable) {
                NSLog(@"Function :%s line:%d prepare stmt failed:%d",__FUNCTION__,__LINE__,result);
            }
            return NULL;
        } else {
            CFDictionarySetValue(_stmtCache, (__bridge const void *)sql, stmt);
        }
    }
    return stmt;
}

/**
 保存到数据库，如果有文件名，则数据库不保存改数据，如果没有没有，则数据库保存该数据
 */
- (BOOL)saveToDbWithKey:(NSString *)key value:(NSData *)value fileName:(NSString *)fileName extendData:(NSData *)data{
    NSString *sql = @"insert or replace into RCSqliteCache(key , fileName , size , fileData , modifyTime , lastAccessTime , extendData) values (?1,?2,?3,?4,?5,?6,?7)";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        return NO;
    }
    int currentTime = (int)time(NULL);
    sqlite3_bind_text(stmt,1,key.UTF8String,-1,NULL);
    sqlite3_bind_text(stmt, 2, fileName.UTF8String, -1, NULL);
    sqlite3_bind_int(stmt,3,(int)value.length);
    if (fileName) {
        sqlite3_bind_blob(stmt,4,NULL,0,0);
    } else {
        sqlite3_bind_blob(stmt , 4 ,value.bytes ,(int)value.length,0);;
    }
    sqlite3_bind_int(stmt, 5 ,currentTime);
    sqlite3_bind_int(stmt,6,currentTime);
    sqlite3_bind_blob(stmt,7,data.bytes,(int)data.length,0);
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d save to db failed:%d",__FUNCTION__,__LINE__,result);
        }
        return NO;
    }
    return YES;
}

/**
 键值绑定
 */
- (NSString *)separatKeysToIdentifier:(NSArray *)keys{
    NSMutableString *identifier = [NSMutableString new];
    for (NSInteger i = 0 ,max = keys.count; i < keys.count; i ++) {
        [identifier appendString:@"?"];
        if (i + 1 != max) {
            [identifier appendString:@","];
        }
    }
    return identifier;
}
- (void )bindKeys:(NSArray *)keys stmt:(sqlite3_stmt *)stmt fromIndex:(int)index{
    for (int i = 0 ; i < keys.count; i ++) {
        NSString *key = keys[i];
        sqlite3_bind_text(stmt, index + i, key.UTF8String, -1, NULL);
    }
}

/**
 更新缓存的访问时间
 */
- (BOOL)updateAccessTimeWithKeyOnDB:(NSString *)key{
    NSString *sql = @"update RCSqliteCache set lastAccessTime= ?1 where key =?2;";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        return NO;
    }
    sqlite3_bind_int(stmt,1,(int)time(NULL));
    sqlite3_bind_text(stmt, 2, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d update access time failed:%d",__FUNCTION__,__LINE__,result);
        }
    }
    return YES;
}

/**
 批量更新缓存的访问时间
 */
- (BOOL)updateAccessTimeWithKeysOnDB:(NSArray *)keys{
    NSString *sql = [NSString stringWithFormat:@"update RCSqliteCache set lastAccessTime = %d where key in (%@);",(int)time(NULL),[self separatKeysToIdentifier:keys]];
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(_db,sql.UTF8String,-1,&stmt,NULL);
    if (result != SQLITE_OK) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d update access time with keys prepare failed:%d",__FUNCTION__,__LINE__,result);
        }
        return NO;
    }
    [self bindKeys:keys stmt:stmt fromIndex:1];
    result = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if (result != SQLITE_DONE) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d update access time with keys failed:%d",__FUNCTION__,__LINE__,result);
        }
        return NO;
    }
    return YES;
}

/**
 从数据库删除缓存
 */
- (BOOL)deleteItemWithKeyOnDB:(NSString *)key{
    NSString *sql = [NSString stringWithFormat:@"delete from RCSqliteCache where key = ?1;"];
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d delete Item with key prepare failed",__FUNCTION__,__LINE__);
        }
    }
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d delete Item with key failed:%d",__FUNCTION__,__LINE__,result);
        }
        return NO;
    }
    return YES;
}

/**
 根据 key 批量删除 item
 */
- (BOOL)deleteItemsWithKeysOnDB:(NSArray *)keys{
    if (![self checkDB]) {
        return NO;
    }
    NSString *sql = [NSString stringWithFormat:@"delete from RCSqliteCache where key in(%@)",[self separatKeysToIdentifier:keys]];
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d delete Items with keys prepare failed",__FUNCTION__,__LINE__);
        }
        return NO;
    }
    [self bindKeys:keys stmt:stmt fromIndex:1];
    result = sqlite3_step(stmt);
    sqlite3_finalize(stmt);
    if (result == SQLITE_ERROR) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d delete Items with keys failed",__FUNCTION__,__LINE__);
        }
        return NO;
    }
    return YES;
}

/**
 删除所有大小大于指定大小的 item
 */
- (BOOL)deleteItemsWhenSizeLargerThanOnDB:(int)size{
    if (![self checkDB]) {
        return NO;
    }
    NSString *sql = @"delete from RCSqliteCache where size > ?1;";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d delete Item when size larger than size prepare failed",__FUNCTION__,__LINE__);
        }
        return NO;
    }
    sqlite3_bind_int(stmt, 1, size);
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d delete Item when size larger than size failed",__FUNCTION__,__LINE__);
        }
        return NO;
    }
    return YES;
}

/**
 删除所有不经常访问的过旧的 item
 */
- (BOOL)deleteItemsWhenTimeEarlierThanOnDB:(int)time{
    NSString *sql = @"delete from RCSqliteCache where lastAccessTime < ?1;";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d delete Item when time earlier than time prepare failed",__FUNCTION__,__LINE__);
        }
        return NO;
    }
    sqlite3_bind_int(stmt, 1, time);
    int result = sqlite3_step(stmt);
    if (result != SQLITE_DONE) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d delete Item when time earlier than time failed",__FUNCTION__,__LINE__);
        }
        return NO;
    }
    return YES;
}

/**
 根据 stmt 获取 item（根据参数可选择是否排除文件 data）
 */
- (RCCacheItem *)getItemFromStmt:(sqlite3_stmt *)stmt excludeFileData:(BOOL)exclude{
    int i = 0 ;
    const char *_key = (char *)sqlite3_column_text(stmt, i++);
    const char *_fileName = (char *)sqlite3_column_text(stmt, i++);
    int _fileDataSize = (int)sqlite3_column_int(stmt, i++);
    const void *data = exclude ? NULL : sqlite3_column_blob(stmt, i);
    int dataBytes = exclude ? 0 : sqlite3_column_bytes(stmt, i ++);
    int mtime = (int)sqlite3_column_int(stmt, i++);
    int atime = (int)sqlite3_column_int(stmt, i ++);
    const void *extendedData = sqlite3_column_blob(stmt, i);
    int extendedDataBytes = sqlite3_column_bytes(stmt, i);
    RCCacheItem *item = [RCCacheItem new];
    if (_key) {
        item.key = [NSString stringWithUTF8String:_key];
    }
    if (_fileName && *_fileName != 0) {
        item.fileName = [NSString stringWithUTF8String:_fileName];
    }
    if (dataBytes > 0 && data) {
        item.value = [NSData dataWithBytes:data length:dataBytes];
    }
    item.size = _fileDataSize;
    item.modifyTime = mtime;
    item.accessTime = atime;
    if (extendedData && extendedDataBytes > 0 ) {
        item.extendedData = [NSData dataWithBytes:extendedData length:extendedDataBytes];
    }
    return item;
}

/**
 根据 key 通过 sql 获取指定的 item
 */
- (RCCacheItem *)getItemWithKeyOnDB:(NSString *)key excludeFileData:(BOOL)exclude{
    NSString *sql = exclude ?  @"select key , fileName , size , modifyTime , lastAccessTime ,extendData from RCSqliteCache where key = ?1; " : @"select key , fileName , size , fileData, modifyTime , lastAccessTime ,extendData from RCSqliteCache where key = ?1; ";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d get item with key  failed",__FUNCTION__,__LINE__);
        }
    }
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    RCCacheItem *item = nil;
    int result = sqlite3_step(stmt);
    if (result == SQLITE_ROW) {
        item = [self getItemFromStmt:stmt excludeFileData:exclude];
    } else {
        if (result != SQLITE_DONE) {
            if (self.logEnable) {
                NSLog(@"Function :%s line:%d get item with key  failed",__FUNCTION__,__LINE__);
            }
        }
    }
    return item;
}

/**
 根据 keys 批量获取 item（根据参数是否包含文件数据）
 */
- (NSMutableArray<RCCacheItem *> *)getItemsWithKeysOnDB:(NSArray *)keys excludedFileData:(BOOL)exclude{
    NSString *sql = nil;
    if (exclude) {
        sql = [NSString stringWithFormat:@"select key , fileName , size , modifyTime , lastAccessTime , extendedData from RCSqliteCache where key in (%@);",[self separatKeysToIdentifier:keys]];
    } else {
        sql = [NSString stringWithFormat:@"select key , fileName , size ,fileData, modifyTime , lastAccessTime , extendedData from RCSqliteCache where key in (%@);",[self separatKeysToIdentifier:keys]];
    }
    sqlite3_stmt *stmt = NULL;
    int result = sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL);
    if (result != SQLITE_OK) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d get items with keys prepare failed",__FUNCTION__,__LINE__);
        }
    }
    if (!stmt) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d get items with keys prepare failed",__FUNCTION__,__LINE__);
        }
    }
    [self bindKeys:keys stmt:stmt fromIndex:1];
    NSMutableArray *items = [NSMutableArray new];
    do {
       int result = sqlite3_step(stmt);
        if (result == SQLITE_ROW) {
            RCCacheItem *item = [self getItemFromStmt:stmt excludeFileData:exclude];
            if (item) {
                [items addObject:item];
            }
        } else if(result == SQLITE_DONE){
            break;
        } else {
            if(self.logEnable){
               NSLog(@"Function :%s line:%d get items with keys step failed",__FUNCTION__,__LINE__);
            }
            items = nil;
            break;
        }
    } while (1);
    sqlite3_finalize(stmt);
    return items;
}

/**
 获取缓存 data

 */
- (NSData *)getValueWithKeyOnDB:(NSString *)key{
    NSString *sql = @"select fileData from RCSqliteCache where key = ?1;";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d get value with key failed",__FUNCTION__,__LINE__);
        }
        return nil;
    }
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if (result == SQLITE_ROW) {
        const void *blob = sqlite3_column_blob(stmt, 0);
        int bytes = sqlite3_column_bytes(stmt, 0);
        if (!blob || bytes < 0) {
            return nil;
        }
        return [NSData dataWithBytes:blob length:bytes];
    } else {
        if (result != SQLITE_DONE) {
            if (self.logEnable) {
                NSLog(@"Function :%s line:%d get value with key failed",__FUNCTION__,__LINE__);
            }
        }
        return nil;
    }
}

/**
 获取文件名
 */
- (NSString *)getFileNameWithKeyOnDB:(NSString *)key{
    NSString *sql = @"select fileName from RCSqliteCache where key = ?1;";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d get fileName with key failed",__FUNCTION__,__LINE__);
        }
        return nil;
    }
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if (result == SQLITE_ROW) {
        const char *fileName = (char *)sqlite3_column_text(stmt, 0);
        if (fileName && *fileName != 0) {
            return [NSString stringWithUTF8String:fileName];
        }
        return nil;
    } else {
        if (result != SQLITE_DONE) {
            if (self.logEnable) {
                NSLog(@"Function :%s line:%d get fileName with key failed",__FUNCTION__,__LINE__);
            }
        }
        return nil;
    }
}
- (NSMutableArray<NSString *> *)getFileNameWithKeysOnDB:(NSArray *)keys{
    NSString *sql = [NSString stringWithFormat:@"select fileName from RCSqliteCache where key in(%@);",[self separatKeysToIdentifier:keys] ];
    sqlite3_stmt *stmt = nil;
    sqlite3_prepare_v2(_db, sql.UTF8String, -1, &stmt, NULL);
    if (!stmt) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d get fileNames with keys prepare failed",__FUNCTION__,__LINE__);
        }
        return  nil;
    }
    [self bindKeys:keys stmt:stmt fromIndex:1];
    NSMutableArray *items = [NSMutableArray array];
    do {
        int result = sqlite3_step(stmt);
        if (result == SQLITE_ROW) {
            const char *fileName = (char *)sqlite3_column_text(stmt, 0);
            if (fileName && *fileName != 0) {
                NSString *name = [NSString stringWithUTF8String:fileName];
                if (name) {
                    [items addObject:name];
                }
            }
        } else if (result == SQLITE_DONE){
            break;
        } else {
            if (self.logEnable) {
                NSLog(@"Function :%s line:%d get fileNames with keys failed",__FUNCTION__,__LINE__);
            }
            items = nil;
            break;
        }
    } while (1);
    sqlite3_finalize(stmt);
    return items;
}

/**
 筛选大于指定大小的文件名
 */
- (NSMutableArray<NSString *> *)getFileNamesWhereSizeLargerThanOnDB:(int)size{
    NSString *sql =@"select fileName from RCSqliteCache where size > ?1 and fileName is not null;";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        return nil;
    }
    sqlite3_bind_int(stmt, 1, size);
    NSMutableArray *fileNames = [NSMutableArray array];
    do {
        int result = sqlite3_step(stmt);
        if (result == SQLITE_ROW) {
            const char *fileName = (char *)sqlite3_column_text(stmt, 0);
            if (fileName && *fileName != 0) {
                NSString *name = [NSString stringWithUTF8String:fileName];
                if (name) {
                    [fileNames addObject:name];
                }
            }
        } else if (result == SQLITE_DONE ){
            break;
        } else {
            if (self.logEnable) {
                NSLog(@"Function :%s line:%d get fileNames with size larger than failed",__FUNCTION__,__LINE__);
            }
            fileNames = nil;
            break;
        }
    } while (1);
    return fileNames;
}

/**
 筛选过旧的数据，筛选出所有时间小于指定时间的文件名
 */
- (NSMutableArray<NSString *> *)getFileNamesWhereTimeEarlierThanOnDB:(int)time{
    NSString *sql = @"select fileName from RCSqliteCache where lastAccessTime < ?1 and fileName is not null;";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        return nil;
    }
    sqlite3_bind_int(stmt, 1, time);
    NSMutableArray *arr = [NSMutableArray array];
    do {
         int result = sqlite3_step(stmt);
        if (result == SQLITE_ROW) {
            const char *name = (char *)sqlite3_column_text(stmt, 0);
            if (name && *name != 0) {
                NSString *fileName = [NSString stringWithUTF8String:name];
                if (fileName) {
                    [arr addObject:fileName];
                }
            }
        } else if (result == SQLITE_DONE){
            break;
        } else{
            if (self.logEnable) {
                NSLog(@"Function :%s line:%d get fileNames with time earlier than failed",__FUNCTION__,__LINE__);
            }
            arr = nil;
            break;
        }
    } while (1);
    sqlite3_finalize(stmt);
    return arr;
}

/**
 按照升序排序筛选出指定数量的文件大小信息
 */
- (NSMutableArray<RCCacheItem *> *)getFileSizeInfoOrderByLastAccessTimeASCLimitCountOnDB:(int)count{
    NSString *sql = @"select key , fileName , size from RCSqliteCache order by lastAccessTime asc limit ?1";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        return nil;
    }
    sqlite3_bind_int(stmt, 1, count);
    NSMutableArray *items = [NSMutableArray array];
    do {
        int result = sqlite3_step(stmt);
        if (result == SQLITE_ROW) {
            const char *key = (char *)sqlite3_column_text(stmt, 0);
            const char *fileName = (char *)sqlite3_column_name(stmt, 1);
            int size = sqlite3_column_int(stmt, 2);
            NSString *keyName = [NSString stringWithUTF8String:key];
            if (keyName) {
                RCCacheItem *item = [RCCacheItem new];
                item.key = keyName;
                item.fileName = fileName ? [NSString stringWithUTF8String:fileName] : nil;
                item.size = size;
                [items addObject:item ];
            }
        } else if (result == SQLITE_DONE){
            break;
        } else {
            if (self.logEnable) {
                NSLog(@"Function :%s line:%d get filesize info failed",__FUNCTION__,__LINE__);
            }
            items = nil;
            break;
        }
    } while (1);
    return items;
}

/**
 获取指定 key 对应的item个数
 */
- (int)getItemCountWithKeyOnDB:(NSString *)key{
    NSString *sql = @"select count(key) from RCSqliteCache where key = ?1;";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        return -1;
    }
    sqlite3_bind_text(stmt, 1, key.UTF8String, -1, NULL);
    int result = sqlite3_step(stmt);
    if (result != SQLITE_ROW) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d get item count failed",__FUNCTION__,__LINE__);
        }
        return -1;
    }
    return sqlite3_column_int(stmt, 0);
}

/**
 获取总的 item size

 */
- (int)getTotalItemSizeOnDB{
    NSString *sql = @"select sum(size) from RCSqliteCache ";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d get item total size failed",__FUNCTION__,__LINE__);
        }
        return -1;
    }
    int result = sqlite3_step(stmt);
    if (result != SQLITE_ROW) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d get item total size failed",__FUNCTION__,__LINE__);
        }
        return -1;
    }
    return sqlite3_column_int(stmt, 0);
}
- (int)getTotalItemCountOnDB{
    NSString *sql = @"select count(*) from RCSqliteCache";
    sqlite3_stmt *stmt = [self prepareStmt:sql];
    if (!stmt) {
        return -1;
    }
    int result = sqlite3_step(stmt);
    if (result != SQLITE_ROW) {
        if (self.logEnable) {
            NSLog(@"Function :%s line:%d get item total count failed",__FUNCTION__,__LINE__);
        }
    }
    return sqlite3_column_int(stmt, 0);
}
#pragma mark - file
- (BOOL)writeFileWithName:(NSString *)fileName data:(NSData *)data{
    NSString *filepath = [_dataPath stringByAppendingPathComponent:fileName];
    return [data writeToFile:filepath atomically:YES];
}
- (NSData *)readDataFromFile:(NSString *)fileName{
    NSString *filePath  = [_dataPath stringByAppendingPathComponent:fileName];
    return [NSData dataWithContentsOfFile:filePath];
}
- (BOOL)removeFile:(NSString *)fileName{
    NSString *filePath = [_dataPath stringByAppendingPathComponent:fileName];
    return [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}
- (BOOL)removeToTrashFolder{
    CFUUIDRef ref = CFUUIDCreate(NULL);
    CFStringRef str = CFUUIDCreateString(NULL, ref);
    CFRelease(ref);
    NSString *trashPath = [_trashPath stringByAppendingPathComponent:(__bridge NSString *)str];
    BOOL rem = [[NSFileManager defaultManager] moveItemAtPath:_dataPath toPath:trashPath error:nil];
    if (rem) {
        [[NSFileManager defaultManager] createDirectoryAtPath:_dataPath withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    CFRelease(str);
    return rem;
}
- (void)emptyTrashFolder{
    NSString *trashPath = _trashPath;
    dispatch_queue_t queue = _trashQueue;
    dispatch_async(queue, ^{
        NSArray *arr = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:trashPath error:nil];
        for (NSString *subPath in arr) {
            NSString *filePaht = [trashPath stringByAppendingPathComponent:subPath];
            [[NSFileManager defaultManager] removeItemAtPath:filePaht error:nil];
        }
    });
}
- (void)reset{
    [[NSFileManager defaultManager] removeItemAtPath:[_path stringByAppendingPathComponent:KDBFileName] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[_path stringByAppendingPathComponent:KDBShmFileName] error:nil];
    [[NSFileManager defaultManager] removeItemAtPath:[_path stringByAppendingPathComponent:KDBWalFileName] error:nil];
    [self removeToTrashFolder];
    [self emptyTrashFolder];
}
#pragma mark - public
-(instancetype)init{
    @throw [NSException exceptionWithName:@"RCStorage error" reason:@"please useinitWithPath:(NSString *)path type:(RCCacheType)type" userInfo:nil];
    return [self initWithPath:@"" type:RCCacheTypeMixed];
}
-(instancetype)initWithPath:(NSString *)path type:(RCCacheType)type{
    if (path.length == 0 || path.length > KPathLengthMax - 64) {
        NSLog(@"please input a useable path");
        return nil;
    }
    if (type > RCCacheTypeMixed) {
        NSLog(@"plase use a valueable type");
        return nil;
    }
    if (self = [super init]) {
        _path = path;
        _dbPath = [path stringByAppendingPathComponent:KDBFileName];
        _dataPath = [path stringByAppendingPathComponent:KDataDirectoryName];
        _trashPath = [path stringByAppendingPathComponent:KTrashDirectoryName];
        _cacheType = type;
        _logEnable = YES;
        _trashQueue = dispatch_queue_create("https://github.com/sunchengxiu/RCCache.git.storageQueue", DISPATCH_QUEUE_SERIAL);
        if (self.logEnable) {
            NSLog(@"DB path:%@",_dbPath);
        }
        NSError *error = nil;
        if ((![[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&error]) || (![[NSFileManager defaultManager] createDirectoryAtPath:[path stringByAppendingPathComponent:KDataDirectoryName] withIntermediateDirectories:YES attributes:nil error:&error]) || (![[NSFileManager defaultManager] createDirectoryAtPath:[path stringByAppendingPathComponent:KTrashDirectoryName] withIntermediateDirectories:YES attributes:nil error:&error])) {
            NSLog(@"RCStorage init error");
            return nil;
        }
        if (![self openDB] || ![self initDB]) {
            [self closeDB];
            [self reset];
            if (![self openDB] || ![self initDB]) {
                [self closeDB];
                NSLog(@"init db error");
                return nil;
            }
        }
        [self emptyTrashFolder];
    }
    return self;
}
-(BOOL)saveItem:(RCCacheItem *)item{
    return [self saveItemWithKey:item.key value:item.value fileName:item.fileName extendedData:item.extendedData];
}
-(BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value{
    return [self saveItemWithKey:key value:value fileName:nil extendedData:nil];
}
-(BOOL)saveItemWithKey:(NSString *)key value:(NSData *)value fileName:(NSString *)fileName extendedData:(NSData *)extendedData{
    if (key.length == 0 || value.length == 0 ) {
        if (self.logEnable) {
            NSLog(@"key or value is nil");
        }
        return NO;
    }
    if (fileName && _cacheType == RCCacheTypeFile) {
        if (self.logEnable) {
            NSLog(@"type is file but file name is null");
        }
        return NO;
    }
    if (fileName.length) {
        if (![self writeFileWithName:fileName data:value]) {
            return NO;
        }
        if (![self saveToDbWithKey:key value:value fileName:fileName extendData:extendedData]) {
            [self removeFile:fileName];
            return NO;
        }
        return YES;
    } else {
        if (_cacheType != RCCacheTypeSqlite) {
            NSString *fileName = [self getFileNameWithKeyOnDB:key];
            if (fileName) {
                [self removeFile:fileName];
            }
        }
        return [self saveToDbWithKey:key value:value fileName:nil extendData:extendedData];
    }
}
-(BOOL)removeItemWithKey:(NSString *)key{
    if (key.length <= 0) {
        return NO;
    }
    switch (_cacheType) {
        case RCCacheTypeSqlite:
            {
                return [self deleteItemWithKeyOnDB:key];
            }
            break;
            case RCCacheTypeFile:
        case RCCacheTypeMixed:{
            NSString *fileName = [self getFileNameWithKeyOnDB:key];
            if (fileName) {
                [self removeFile:fileName];
            }
            return [self deleteItemWithKeyOnDB:key];
        }break;
            
        default:
            return NO;
            break;
    }
}
-(BOOL)removeItemsWithKeys:(NSArray<NSString *> *)keys{
    if (keys.count <= 0) {
        return NO;
    }
    switch (_cacheType) {
        case RCCacheTypeSqlite:
            {
               return [self deleteItemsWithKeysOnDB:keys];
            }
            break;
            case RCCacheTypeFile:
        case RCCacheTypeMixed:{
            NSArray *arr = [self getFileNameWithKeysOnDB:keys];
            for (NSString *fileName in arr) {
                [self removeFile:fileName];
            }
            return [self deleteItemsWithKeysOnDB:keys];
        } break;
            
        default:
            return NO;
            break;
    }
}
-(BOOL)removeItemsToFitSize:(int)size{
    if (size == INT_MAX) {
        return YES;
    }
    if (size <= 0) {
        [self removeAllItems];
    }
    int total = [self getTotalItemSizeOnDB];
    if (total < 0 ) {
        return NO;
    }
    if (total <= size) {
        return YES;
    }
    NSArray *arr = nil;
    BOOL success = NO;
    do {
        arr = [self getFileSizeInfoOrderByLastAccessTimeASCLimitCountOnDB:16];;
        for (RCCacheItem *item in arr) {
            if (total > size) {
                if (item.fileName) {
                    [self removeFile:item.fileName];
                }
                if ([self deleteItemWithKeyOnDB:item.key]) {
                    success = YES;
                } else {
                    success = NO;
                }
                total -= item.size;
            } else {
                break;
            }
            if (!success) {
                break;
            }
        }
    } while (total > size && success  &&  arr.count > 0);
    if (success) {
        [self checkPoint];
    }
    return success;
}
-(BOOL)removeItemsToFitCount:(int)count{
    if (count <= 0) {
        return [self removeAllItems];
    }
    if (count == INT_MAX) {
        return YES;
    }
    int total = [self getItemsCount];
    if (total < 0 ) {
        return NO;
    }
    if (total <= count) {
        return YES;
    }
    BOOL success = NO;
    NSArray *arr = nil;
    do {
        arr = [self getFileSizeInfoOrderByLastAccessTimeASCLimitCountOnDB:16];
        for (RCCacheItem *item in arr) {
            if (total > count) {
                if (item.fileName) {
                    [self removeFile:item.fileName];
                }
                if ([self deleteItemWithKeyOnDB:item.key]) {
                    success = YES;
                }
                total --;
            } else {
                break;
            }
            if (!success) {
                break;
            }
        }
    } while (success && arr.count > 0 && total > count);
    if (success) {
        [self checkPoint];
    }
    return success;
}
-(BOOL)removeItemsForSizeLargerThan:(int)size{
    if (size == INT_MAX) {
        return YES;
    }
    if (size <= 0 ) {
        [self removeAllItems];
    }
    switch (_cacheType) {
        case RCCacheTypeSqlite:
            {
                if ([self deleteItemsWhenSizeLargerThanOnDB:size]) {
                    [self checkPoint];
                    return YES;
                }
            }
            break;
            case RCCacheTypeFile:
        case RCCacheTypeMixed:{
            NSArray *arr = [self getFileNamesWhereSizeLargerThanOnDB:size];
            for (NSString *fileName in arr) {
                [self removeFile:fileName];
            }
            if ([self deleteItemsWhenSizeLargerThanOnDB:size]) {
                [self checkPoint];
            }
            return YES;
        }break;
            
        default:
            break;
    }
    return NO;
}
-(BOOL)removeItemsForTimeEarlierThan:(int)time{
    if (time <= 0) {
        return YES;
    }
    if (time == INT_MAX) {
        [self removeAllItems];
    }
    switch (_cacheType) {
        case RCCacheTypeSqlite:
            {
                if ([self deleteItemsWhenTimeEarlierThanOnDB:time]) {
                    [self checkPoint];
                }
            }
            break;
            case RCCacheTypeFile:
        case RCCacheTypeMixed:{
            NSArray *arr = [self getFileNamesWhereTimeEarlierThanOnDB:time];
            for (NSString *fileName in arr) {
                [self removeFile:fileName];
            }
            if ([self deleteItemsWhenTimeEarlierThanOnDB:time]) {
                [self checkPoint];
            }
            return YES;
        }break;
            
        default:
            break;
    }
    return NO;
}
-(void)removeAllItemsWithProgress:(void (^)(int, int))progressBlock endBlock:(void (^)(BOOL))endBlock{
    int total = [self getTotalItemCountOnDB];
    int left  = total;
    NSArray *arr = nil;
    BOOL success = NO;
    if (total <= 0) {
        if (endBlock) {
            endBlock(total < 0);
        }
    } else {
        do {
            arr = [self getFileSizeInfoOrderByLastAccessTimeASCLimitCountOnDB:32];
            for (RCCacheItem *item in arr) {
                if (left > 0) {
                    if (item.fileName) {
                        [self removeFile:item.fileName];
                    }
                    if ([self deleteItemWithKeyOnDB:item.key]) {
                        success = YES;
                    }
                    left --;
                } else {
                    break;
                }
                if (!success) {
                    break;
                }
            }
            if (progressBlock) {
                progressBlock(total - left , total);
            }
        } while (success && arr.count > 0 && left > 0);
        if (success) {
            [self checkPoint];
        }
        if (endBlock) {
            endBlock(!success);
        }
    }
}
-(BOOL)removeAllItems{
    if (![self closeDB]) {
        return NO;
    }
    [self reset];
    if (![self openDB]) {
        return NO;
    }
    if (![self initDB]) {
        return NO;
    }
    return YES;
}
-(RCCacheItem *)getItemForKey:(NSString *)key{
    if (key.length == 0 ) {
        return nil;
    }
    RCCacheItem *item = [self getItemWithKeyOnDB:key excludeFileData:NO];
    if (item) {
        [self updateAccessTimeWithKeyOnDB:key];
        if (item.fileName) {
            item.value = [self readDataFromFile:item.fileName];
            if (item.value == nil) {
                [self deleteItemWithKeyOnDB:key];
                item = nil;
            }
        }
    }
    return item;
}
-(RCCacheItem *)getItemInfoForKey:(NSString *)key{
    if (key.length <= 0) {
        return nil;
    }
    RCCacheItem *item = [self getItemWithKeyOnDB:key excludeFileData:YES];
    return item;
}
-(NSData *)getItemValueForKey:(NSString *)key{
    if (key.length == 0 ) {
        return nil;
    }
    NSData *value = nil;
    switch (_cacheType) {
        case RCCacheTypeSqlite:
            {
                value = [self getValueWithKeyOnDB:key];
            }
            break;
        case RCCacheTypeFile:{
            NSString *fileName = [self getFileNameWithKeyOnDB:key];
            if (fileName) {
                value = [self readDataFromFile:fileName];
                if (!value) {
                    [self deleteItemWithKeyOnDB:key];
                    value = nil;
                }
            }
            
        }break;
        case RCCacheTypeMixed:{
            NSString *fileName = [self getFileNameWithKeyOnDB:key];
            if (fileName) {
                value = [self readDataFromFile:fileName];
                if (!value) {
                    [self deleteItemWithKeyOnDB:key];
                    value = nil;
                }
            } else {
                value = [self getValueWithKeyOnDB:key];
            }
            
        }break;
            
        default:
            break;
    }
    if (value) {
        [self updateAccessTimeWithKeyOnDB:key];
    }
    return value;
}
-(NSArray<RCCacheItem *> *)getItemsForKeys:(NSArray<NSString *> *)keys{
    NSMutableArray *items  = [self getItemsWithKeysOnDB:keys excludedFileData:NO];
    if (_cacheType != RCCacheTypeSqlite) {
        for (NSInteger i = 0 ,max = items.count; i < max; i ++) {
            RCCacheItem *item = items[i];
            if (item.fileName) {
                item.value = [self readDataFromFile:item.fileName];
                if (!item.value) {
                    if (item.key) {
                        [self deleteItemWithKeyOnDB:item.key];
                    }
                    [items removeObjectAtIndex:i];
                    i --;
                    max --;
                }
            }
        }
    }
    if (items.count) {
        [self updateAccessTimeWithKeysOnDB:keys];
    }
    return items.count ? items : nil;
}
-(NSArray<RCCacheItem *> *)getItemInfosForKeys:(NSArray<NSString *> *)keys{
    if (keys.count <= 0) {
        return nil;
    }
    NSArray *items = [self getItemsWithKeysOnDB:keys excludedFileData:YES];
    return items;
}
-(NSDictionary<NSString *,NSData *> *)getItemValuesForKeys:(NSArray<NSString *> *)keys{
    if (keys.count <= 0) {
        return nil;
    }
    NSArray *items = [self getItemsForKeys:keys];
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (RCCacheItem *item in items) {
        if (item.key && item.value) {
            [dic setObject:item.value forKey:item.key];
        }
    }
    return dic.count ? dic : nil;
}
-(BOOL)itemExistsForKey:(NSString *)key{
    if (key.length <= 0) {
        return NO;
    }
    return [self getItemCountWithKeyOnDB:key] > 0;
}
-(int)getItemsSize{
    return [self getTotalItemSizeOnDB];
}
-(int)getItemsCount{
    return [self getTotalItemCountOnDB];
}
-(void)dealloc{
    UIBackgroundTaskIdentifier identifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        
    }];
    [self closeDB];
    if (identifier != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:identifier];
    }
}
@end

@implementation RCCacheItem

@end
