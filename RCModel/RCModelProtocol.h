//
//  RCModelProtocol.h
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

NS_ASSUME_NONNULL_BEGIN

@protocol RCModelProtocol <NSObject>
@optional

/**
 黑名单中的属性不会被解析

 @return 黑名单
 */
+ (nullable NSArray<NSString *> *)modelPropertyBlacklist;

/**
 只解析白名单中的属性
 
 @return 白名单
 */
+ (nullable NSArray<NSString *> *)modelPropertyWhitelist;

/**
 自定义映射,某个属性映射到某个类（注：是映射到具体的类）
 {
    @"user":RCUser.class,
    @"address",@"RCAddress"
 }

 @return 自定义模型映射
 */
+ (nullable NSDictionary <NSString * , id>*)modelCustomPropertyMapClass;

/**
 json->model 过程中，用该方法自定义字典中属性对应的自定义类
    + (Class)modelCustomClassForDictionary:(NSDictionary*)dictionary {
        if (dictionary[@"radius"] != nil) {
            return [RCCircle class];
        } else if (dictionary[@"width"] != nil) {
        r   eturn [RCRectangle class];
        } else if (dictionary[@"y2"] != nil) {
            return [RCLine class];
        } else {
            return [self class];
    }
 }

 @return 自定义映射
 */
+ (nullable Class)modelCustomClassForDictionary:(NSDictionary *)dictionary;
/**
 自定义键值对
 如果，我们的模型属性字段和 json 不对应，那么可以通过这个方法来自定义模型和json的键值对应关系
 
 Example:
 
 json:
 {
 "n":"sunchengxiu",
 "a": 25,
 "add" : {
    "home : "dalian"
 },
 "UID" : 88888
 }
 
 model:
 @code
 @interface RCUser : NSObject
    @property NSString *name;
    @property NSInteger age;
    @property NSString *home;
    @property NSString *ID;
 @end
 
 @implementation RCUser
 + (NSDictionary *)modelCustomPropertyMapper {
    return @{   @"name"  : @"n",
                @"age"  : @"a",
                @"home"  : @"add.home",
                @"ID": @[@"id", @"ID", @"UID"]};
    }
 @end
 @endcode
 
 其中 name 属于简单键值对映射，home 属于稍微复杂的 keypath 映射 ， ID 属于较为复杂的一对多映射。
 
 @return A custom mapper for properties.
 */
+ (nullable NSDictionary<NSString *, id> *)modelCustomPropertyMapper;

/**
 可以使用此方法验证属性的转换是否正确，也可以使用i此方法完成一些自动转换没有办法完成的工作
 
 @discussion 此方法将在 `modelWithDictionary` 等之后调用，如果返回 NO ， 将忽略此模型
 
 @param dic  json->model 中使用的 json
 
 @return 如果模型可用请返回 YES， 否则返回 NO。
 */
- (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dic;

/**
 如果默认的 model -> json ， 满足不了需要，可使用此方法做一些额外的处理，可以使用此方法验证模型是否有效，返回 YES 或 NO 来证明。
 
 @discussion 此方法将在 `-modelToJSONString` 之后来调用
 
 @param dic  model
 
 @return 返回 YES 或者 NO 来表示是否可用
 */
- (BOOL)modelCustomTransformToDictionary:(NSMutableDictionary *)dic;
@end

NS_ASSUME_NONNULL_END
