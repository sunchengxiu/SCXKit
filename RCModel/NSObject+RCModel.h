//
//  NSObject+RCModel.h
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
#import "RCModelProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (RCModel)
#pragma mark - json -> model

/**
 将 json 转化为 model（可识别 NSData ， NSString ， NSDictionary），会先将传进来的数据格式化成 dic ， 然后调用下面的方法。
 
 @param json json 数据
 @return 转化后的 model
 */
+ (instancetype)modelWithJson:(id)json;

/**
 dic -> model，模型序列化，最终会调用下面的方法进行k核心模型转换

 @param dic 需要转换的 dic
 @return 转换后的模型
 */
+ (instancetype)modelWithDictionary:(NSDictionary *)dic;

/**
 根据传进来的 dic，进行 dic -> model 的操作，返回值代表是否转换成功，可以通过一个模型，直接调用这个方法，穿进去对应的 dic ， 进行模型转化
 example:
    @interface RCUser : NSObject

     @property (nonatomic, strong) RCAddress *address;

     @end
 
    [_address modelSetWithDictionary:dic[@"address"]];
 
    可以使用上面的方式直接转化
 @param dic 需要转换的 dic
 @return 是否转换成功
 */
- (BOOL)modelSetWithDictionary:(NSDictionary *)dic;

#pragma mark - model -> json

/**
 model -> json

 @return 转化好的数据
 */
- (nullable id)modelToJsonObject;

@end

NS_ASSUME_NONNULL_END
