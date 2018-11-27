//
//  RCClassInfo.h
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
#import <objc/runtime.h>
#import "RCModelDefine.h"
NS_ASSUME_NONNULL_BEGIN
/**
 获取编码类型
 
 @discussion Apple doc:
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html
 https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
 
 @param encodingType 系统类型编码
 @return 定义好的类型编码枚举
 */
RCEncodingType RCGetEncodingType(const char *encodingType);

#pragma mark - ivar info

/**
 struct objc_ivar {
     char * _Nullable ivar_name                               OBJC2_UNAVAILABLE;
     char * _Nullable ivar_type                               OBJC2_UNAVAILABLE;
     int ivar_offset                                          OBJC2_UNAVAILABLE;
     #ifdef __LP64__
     int space                                                OBJC2_UNAVAILABLE;
     #endif
 }
 @property = Ivar + setter + getter
 property : 属性
 ivar : 成员变量，主要是用来保存数据的
 */
@interface RCObjc_ivar : NSObject
/**
 ivar
 */
@property(nonatomic , assign , readonly)Ivar ivar;
/**
 name
 */
@property(nonatomic , copy , readonly)NSString *name;
/**
 offset
 */
@property(nonatomic , assign , readonly)ptrdiff_t offset;
/**
 typeencoding
 */
@property(nonatomic , copy , readonly)NSString *typeEncoding;
/**
 encoding
 */
@property(nonatomic , assign , readonly)RCEncodingType type;

/**
 初始化一个 ivar 的对象
 
 @param ivar ivar 结构体
 @return ivar 对象或者 nil
 */
-(instancetype)initWithIvar:(Ivar)ivar;

@end

#pragma mark - method info

/**
 struct objc_method {
 SEL _Nonnull method_name                                 OBJC2_UNAVAILABLE;
 char * _Nullable method_types                            OBJC2_UNAVAILABLE;
 IMP _Nonnull method_imp                                  OBJC2_UNAVAILABLE;
 }
 */
@interface RCObjc_method : NSObject
/**
 method
 */
@property(nonatomic , assign , readonly)Method method;
/**
 method name
 */
@property(nonatomic , copy , readonly)NSString *name;
/**
 type encoding
 */
@property(nonatomic , copy , readonly)NSString *typeEncoding;
/**
 return type encoding
 */
@property(nonatomic , copy , readonly)NSString *returnTypeEncoding;
/**
 SEL
 */
@property(nonatomic , assign , readonly)SEL sel;
/**
 imp
 */
@property(nonatomic , assign , readonly)IMP imp;
/**
 argument type encodings
 */
@property(nonatomic , copy , readonly)NSArray<NSString *> *argumentTypeEncodings;

/**
 创建一个 method 对象

 @param method method
 @return method 对象
 */
- (instancetype)initWithMethod:(Method)method;
@end

#pragma mark - property info

@interface RCObjc_property : NSObject
/**
 property
 */
@property(nonatomic , assign , readonly)objc_property_t property;
/**
 name
 */
@property(nonatomic , copy , readonly)NSString *name;
/**
 type encoding
 */
@property(nonatomic , copy , readonly)NSString *typeEncoding;
/**
 type
 */
@property(nonatomic , assign , readonly)RCEncodingType type;
/**
 ivar name
 */
@property(nonatomic , copy , readonly)NSString *ivarName;
/**
 class
 */
@property(nullable,nonatomic , assign , readonly)Class cls;
/**
 property
 */
@property(nullable,nonatomic , copy , readonly)NSArray<NSString *> *protocols;
/**
 setter
 */
@property(nonatomic , assign , readonly)SEL setter;
/**
 getter
 */
@property(nonatomic , assign , readonly)SEL getter;

/**
 初始化property object
 
 @param property property
 @return property object
 */
- (instancetype)initWithProperty:(objc_property_t)property;
@end

#pragma mark - class info
/**
 struct objc_class {
 Class _Nonnull isa  OBJC_ISA_AVAILABILITY;
 
 #if !__OBJC2__
 Class _Nullable super_class                              OBJC2_UNAVAILABLE;
 const char * _Nonnull name                               OBJC2_UNAVAILABLE;
 long version                                             OBJC2_UNAVAILABLE;
 long info                                                OBJC2_UNAVAILABLE;
 long instance_size                                       OBJC2_UNAVAILABLE;
 struct objc_ivar_list * _Nullable ivars                  OBJC2_UNAVAILABLE;
 struct objc_method_list * _Nullable * _Nullable methodLists                    OBJC2_UNAVAILABLE;
 struct objc_cache * _Nonnull cache                       OBJC2_UNAVAILABLE;
 struct objc_protocol_list * _Nullable protocols          OBJC2_UNAVAILABLE;
 #endif
 
 } OBJC2_UNAVAILABLE;
 */
@interface RCClassInfo : NSObject
/**
 ivar lists
 */
@property(nullable , nonatomic , strong , readonly)NSDictionary<NSString * , RCObjc_ivar *> *ivarList;
/**
 property list
 */
@property(nullable , nonatomic , strong , readonly)NSDictionary<NSString * , RCObjc_property * > *propertyList;
/**
 method list
 */
@property(nullable , nonatomic , strong , readonly)NSDictionary<NSString * , RCObjc_method *> *methodList;
/**
 name
 */
@property(nonatomic , copy , readonly)NSString *name;
/**
 class
 */
@property(nonatomic , assign , readonly)Class cls;
/**
 super class
 */
@property(nullable , nonatomic , assign , readonly)Class superCls;
/**
 meta class
 */
@property(nullable , nonatomic , assign , readonly)Class metaCls;
/**
 id meta
 */
@property(nonatomic , assign , readonly)BOOL isMeta;
/**
 superclass info
 */
@property(nullable , nonatomic , strong , readonly)RCClassInfo *superClsInfo;

/**
 如果一个类发生了更改，需要调用这个类来刷新类信息
 */
- (void)setNeedUpdate;

/**
 如果返回yes，调用‘classInfoWithClass’和‘classInfoWithClassName’获取最新的类信息
 */
- (BOOL)needUpdate;
/**
 获取指定类的类信息
 */
+ (nullable instancetype)classInfoWithClass:(Class)cls;

/**
 获取指定类的类信息
 */
+ (nullable instancetype)classInfoWithClassName:(NSString *)className;
@end

NS_ASSUME_NONNULL_END
