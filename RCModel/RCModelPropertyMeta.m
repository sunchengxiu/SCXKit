//
//  RCModelPropertyMeta.m
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
#import "RCModelPropertyMeta.h"
#import "RCModelDefine.h"
#import "RCModelProtocol.h"
#import "RCModelFormater.h"
@interface RCModelPropertyMeta()

/**
 编码类型
 */
@property(nonatomic , assign )RCEncodingType encodingType;

/**
 系统的 NS 类型
 */
@property(nonatomic , assign)RCEncodingNSType nsType;

/**
 属性名字
 */
@property(nonatomic , copy)NSString *name;

/**
 所属类
 */
@property(nonatomic , assign)Class cls;


/**
 setter
 */
@property(nonatomic , assign)SEL setter;

/**
 getter
 */
@property(nonatomic , assign)SEL getter;

/**
 是否是基本数据类型
 */
@property(nonatomic , assign)BOOL isCNumber;

/**
 是否支持 kvc
 */
@property(nonatomic , assign)BOOL isAllowKVC;

/**
 如果为结构体,结构体是否支持归档
 */
@property(nonatomic , assign)BOOL isAllowStructArchive;

/**
 是否含有自定义映射
 */
@property(nonatomic , assign) BOOL isHasCustomMapperDictionary;

/**
 property info
 */
@property(nonatomic , strong)RCObjc_property *propertyInfo;
@end

@implementation RCModelPropertyMeta

+(instancetype)propertyMetaWithClassInfo:(RCClassInfo *)classInfo propertyInfo:(RCObjc_property *)propertyInfo mapper:(Class)mapper{
    RCModelPropertyMeta *meta = [self new];
    meta.name = propertyInfo.name;
    meta.encodingType = propertyInfo.type;
    meta.propertyInfo = propertyInfo;
    meta.mapperCls = mapper;
    meta.cls = propertyInfo.cls;
    if ((meta.encodingType & RCEncodingTypeMask) == RCEncodingTypeObject) {
        meta.nsType = RCClassGetNSType(propertyInfo.cls);
    } else {
        meta.isCNumber = RCEncodingTypeIsCNumber(meta.encodingType);
    }
    // 是否存在 getter setter 方法
    if (propertyInfo.setter) {
        if ([classInfo.cls instanceMethodForSelector:propertyInfo.setter]) {
            meta.setter = propertyInfo.setter;
        }
    }
    if (propertyInfo.getter) {
        if ([classInfo.cls instanceMethodForSelector:propertyInfo.getter]) {
            meta.getter = propertyInfo.getter;
        }
    }
    // 是否存在自定义映射字典
    if (mapper) {
        meta.isHasCustomMapperDictionary = [mapper respondsToSelector:@selector(modelCustomClassForDictionary:)];
    } else if(meta.cls && meta.nsType == RCEncodingTypeUnknow) {
        meta.isHasCustomMapperDictionary = [meta.cls respondsToSelector:@selector(modelCustomClassForDictionary:)];
    }
    // 判断结构体是否支持归档,下面这几种才支持
    if ((meta.encodingType & RCEncodingTypeMask) == RCEncodingTypeStruct) {
        static NSSet *types = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableSet *set = [NSMutableSet new];
            // 32 bit
            [set addObject:@"{CGSize=ff}"];
            [set addObject:@"{CGPoint=ff}"];
            [set addObject:@"{CGRect={CGPoint=ff}{CGSize=ff}}"];
            [set addObject:@"{CGAffineTransform=ffffff}"];
            [set addObject:@"{UIEdgeInsets=ffff}"];
            [set addObject:@"{UIOffset=ff}"];
            // 64 bit
            [set addObject:@"{CGSize=dd}"];
            [set addObject:@"{CGPoint=dd}"];
            [set addObject:@"{CGRect={CGPoint=dd}{CGSize=dd}}"];
            [set addObject:@"{CGAffineTransform=dddddd}"];
            [set addObject:@"{UIEdgeInsets=dddd}"];
            [set addObject:@"{UIOffset=dd}"];
            types = set;
        });
        if ([types containsObject:propertyInfo.typeEncoding]) {
            meta.isAllowStructArchive = YES;
        }
    }
    // 是否支持KVC
    if (meta.getter && meta.setter) {
        // long double 和 pointer 不支持 kvc
        switch (meta.encodingType & RCEncodingTypeMask) {
            case RCEncodingTypeBool:
            case RCEncodingTypeInt8:
            case RCEncodingTypeUInt8:
            case RCEncodingTypeInt16:
            case RCEncodingTypeUInt16:
            case RCEncodingTypeInt32:
            case RCEncodingTypeUInt32:
            case RCEncodingTypeInt64:
            case RCEncodingTypeUInt64:
            case RCEncodingTypeFloat:
            case RCEncodingTypeDouble:
            case RCEncodingTypeObject:
            case RCEncodingTypeClass:
            case RCEncodingTypeBlock:
            case RCEncodingTypeStruct:
            case RCEncodingTypeUnion: {
                meta.isAllowKVC = YES;
            } break;
            default: break;
        }
    }
    return meta;
}
@end
