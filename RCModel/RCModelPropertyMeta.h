//
//  RCModelPropertyMeta.h
//  RCModel
//
//  Copyed and modified by 孙承秀 on 2018/10/15.
//  Thank you for YY
//  YYKit <https://github.com/ibireme/YYKit>
//
//  Created by ibireme on 15/5/9.
//  Copyright (c) 2015 ibireme.
//
//  This source code is licensed under the MIT-style license found in the
//  LICENSE file in the root directory of this source tree.
//

#import <Foundation/Foundation.h>
#import "RCClassInfo.h"
#import "RCModelDefine.h"
NS_ASSUME_NONNULL_BEGIN
@interface RCModelPropertyMeta : NSObject

/**
 编码类型
 */
@property(nonatomic , assign , readonly)RCEncodingType encodingType;

/**
 系统的 NS 类型
 */
@property(nonatomic , assign, readonly)RCEncodingNSType nsType;

/**
 属性名字
 */
@property(nonatomic , copy, readonly)NSString *name;

/**
 所属类
 */
@property(nonatomic , assign, readonly)Class cls;

/**
 映射到的类
 */
@property(nonatomic , assign)Class mapperCls;

/**
 setter
 */
@property(nonatomic , assign, readonly)SEL setter;

/**
 getter
 */
@property(nonatomic , assign, readonly)SEL getter;

/**
 是否是基本数据类型
 */
@property(nonatomic , assign, readonly)BOOL isCNumber;

/**
 是否支持 kvc
 */
@property(nonatomic , assign, readonly)BOOL isAllowKVC;

/**
 如果为结构体,结构体是否支持归档
 */
@property(nonatomic , assign, readonly)BOOL isAllowStructArchive;

/**
 是否含有自定义映射
 */
@property(nonatomic , assign, readonly) BOOL isHasCustomMapperDictionary;

/**
 property info
 */
@property(nonatomic , strong, readonly)RCObjc_property *propertyInfo;

/**
 简单 KV 映射对应
 {
 @"name":@"userName"
 }
 */
@property(nonatomic , copy)NSString *mapToKey;

/**
 稍微复杂的 KV
 {
 @"name":@"user.name"
 }
 */
@property(nonatomic , copy)NSArray *mapToKeyPath;

/**
 一对多
 {
 @"id":@[@"id",@"uid",@"userID"]
 }
 */
@property(nonatomic , copy)NSArray *mapToArray;

/**
 next 指针
 */
@property(nonatomic , strong)RCModelPropertyMeta *next;

/**
 初始化 propertyMeta 类

 @param classInfo 类信息
 @param propertyInfo 属性信息
 @param mapper 映射
 @return 初始化后的 propertyMeta
 */
+ (instancetype)propertyMetaWithClassInfo:(RCClassInfo *)classInfo propertyInfo:(RCObjc_property *)propertyInfo mapper:(Class)mapper;
@end

NS_ASSUME_NONNULL_END
