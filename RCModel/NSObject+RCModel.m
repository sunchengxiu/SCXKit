//
//  NSObject+RCModel.m
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
#import "NSObject+RCModel.h"
#import "RCModelMeta.h"
#import "RCModelProtocol.h"
#import "RCModelPropertyMeta.h"
#import "RCModelFormater.h"
typedef struct {
    // 要设置的实体对象
    void *model;
    // 实体类描述
    void *modelMeta;
    // 要设置的值
    void *dic;
    
} RCModelSetContext;
@implementation NSObject (RCModel)

/**
 获取 value 并且赋值

 @param propertyMeta 属性描述类
 @param context 上下文
 */
static void SetModelWithPropertyMeta(const void *propertyMeta , void * context){
    RCModelSetContext *_context = context;
    __unsafe_unretained NSDictionary *dic  = (__bridge NSDictionary *)_context->dic;
    __unsafe_unretained RCModelPropertyMeta *meta = (__bridge RCModelPropertyMeta*)propertyMeta;
    if (!meta.setter) {
        return;
    }
    id value = nil;
    // 存在自定义属性映射的，需要重新获取并赋值
    if (meta.mapToKeyPath) {
        value = RCValueForKeyPaths(dic, meta.mapToKeyPath);
    } else if(meta.mapToArray){
        value = RCValueForMutiKeys(dic, meta.mapToArray);
    } else {
        value = [dic objectForKey:meta.mapToKey];
    }
    if (value) {
        id model = (__bridge id)_context->model;
        RCModelSetValueForProperty(model, value, meta);
    }
}
static void SetModelWithDictionary(const void *key , const void *value , void *context){
    RCModelSetContext *_context = context;
    __unsafe_unretained RCModelMeta *meta = (__bridge RCModelMeta *)_context->modelMeta;
    __unsafe_unretained RCModelPropertyMeta *propertyMeta = [meta.mapper objectForKey:(__bridge id)key];
    __unsafe_unretained id model = (__bridge id )_context->model;
    while (propertyMeta) {
        if (propertyMeta.setter) {
            RCModelSetValueForProperty(model, (__bridge __unsafe_unretained id)value, propertyMeta);
        }
        // 如果存在 json 中的一个 key ，对应 model 中的多个属性的时候，之前的属性元类处理方式是将这些一对多以链表的形式存储，保证不拉下每一个，所以这里要便利它的 next 指针，找出所有的model。
        propertyMeta = propertyMeta.next;
    }
}

#pragma mark - json -> model

/**
 将 json 转化为 model（可识别 NSData ， NSString ， NSDictionary）

 @param json json 数据
 @return 转化后的 model
 */
+ (instancetype)modelWithJson:(id)json{
    NSDictionary *dic = [self dictionaryWithJson:json];
    if (dic) {
        return [self modelWithDictionary:dic];
    } else {
        return nil;
    }
}

/**
 将 json 转化为 dic

 @param json json
 @return dic
 */
+ (NSDictionary *)dictionaryWithJson:(id)json{
    if (!json || json == (id)kCFNull) {
        return nil;
    }
    NSDictionary *dic = nil;
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSDictionary class]]) {
        dic = json;
    } else if ([json isKindOfClass:[NSData class]]){
        jsonData = json;
    } else if ([json isKindOfClass:[NSString class]]){
        jsonData = [(NSString *)json dataUsingEncoding:NSUTF8StringEncoding];
    }
    if (jsonData) {
        dic = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
        if (!dic) {
            dic = nil;
        }
    }
    return dic;
}
/**
 将字典动态转化为数据模型

 @param dic 要转化的字典
 @return 数据模型
 */
+ (instancetype)modelWithDictionary:(NSDictionary *)dic{
    if (dic == nil || [dic isKindOfClass:[NSNull class]] || [dic isEqual:[NSNull null]] || dic == (id)kCFNull) {
        NSLog(@"dic is not enable nil");
        return nil;
    }
    if (![dic isKindOfClass:[NSDictionary class]]) {
        NSLog(@"dic is not NSDictionary class");
        return nil;
    }
    Class cls = [self class];
    // 创建当前的模型描述类
    RCModelMeta *modelMeta = [RCModelMeta metaWithClass:cls];
    if (modelMeta.isCustomClassFromDictionary) {
        cls = [(id<RCModelProtocol>)cls modelCustomClassForDictionary:dic];
    }
    NSObject *newObject = [cls new];
    if ([newObject modelSetWithDictionary:dic]) {
        return newObject;
    }
    return nil;
}
- (BOOL)modelSetWithDictionary:(NSDictionary *)dic{
    if (!dic || dic == (id)kCFNull) {
        return NO;
    }
    if (![dic isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    RCModelMeta *meta = [RCModelMeta metaWithClass:object_getClass(self)];
    if (meta.keyMapCount == 0) {
        return NO;
    }
    RCModelSetContext context = {0};
    context.model = (__bridge void *)self;
    context.modelMeta = (__bridge void *)meta;
    context.dic = (__bridge void *)dic;
    // 判断模型的属性数量与json的键值对数量的对应关系,这样可以减少循环方法调用次数
    if (meta.keyMapCount >= CFDictionaryGetCount((CFDictionaryRef)dic)) {
        // 如果存在模型中多个属性对应json的一个属性的时候
        // 根据字典给模型赋值
        // 这里只是最基本的赋值，没有处理映射的情况
        CFDictionaryApplyFunction((CFDictionaryRef)dic, SetModelWithDictionary, &context);
        // 这里主要是为了减少遍历次数，只遍历特殊的自定义映射
        if (meta.keyPathsArr) {
            CFArrayApplyFunction((CFArrayRef)meta.keyPathsArr, CFRangeMake(0, CFArrayGetCount((CFArrayRef)meta.keyPathsArr)), SetModelWithPropertyMeta, &context);
        } else if (meta.mutiKeyPathArr){
            CFArrayApplyFunction((CFArrayRef)meta.mutiKeyPathArr, CFRangeMake(0, CFArrayGetCount((CFArrayRef)meta.mutiKeyPathArr)), SetModelWithPropertyMeta, &context);
        }
        
    } else {
        CFArrayApplyFunction((CFArrayRef)meta.allPropertyMetaArrs, CFRangeMake(0, meta.keyMapCount), SetModelWithPropertyMeta, &context);
    }
    // 模型转换检测
    if (meta.isHasCustomTransformFromDic) {
        // 处理上述所有自动转换无法完成的情况。
        return [(id<RCModelProtocol>)self modelCustomTransformFromDictionary:dic];
    }
    return YES;
}

#pragma mark - model -> json
-(id)modelToJsonObject{
    id value = ModelToJSONObjectRecursive(self);
    if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
        return value;
    }
    return nil;
}
@end


