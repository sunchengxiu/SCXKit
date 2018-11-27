//
//  RCModelMeta.h
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

@interface RCModelMeta : NSObject

/**
 所有的 propertyMeta 信息
 */
@property(nonatomic , copy , readonly)NSArray *allPropertyMetaArrs;

/**
 自定义属性映射
 */
@property(nonatomic , assign , readonly)BOOL isCustomClassFromDictionary;

/**
 json - > model 过程中，是否有实现自定义检测类，来实现 json -> model 无法实现的需求
 */
@property(nonatomic , assign, readonly) BOOL isHasCustomTransformFromDic;

/**
 model -> json 过程中，是否有实现自定义检测类，来实现 model -> json 无法实现的需求
 */
@property(nonatomic , assign, readonly) BOOL isHasCustomTransformToDic;

/**
 映射数量
 */
@property(nonatomic , assign , readonly)NSUInteger keyMapCount;

/**
 所有的映射
 */
@property(nonatomic , copy , readonly)NSMutableDictionary *mapper;

/**
 keypath arr
 */
@property(nonatomic , strong , readonly)NSMutableArray *keyPathsArr;

/**
 muti keypath arr
 */
@property(nonatomic , strong ,readonly)NSMutableArray *mutiKeyPathArr;

/**
 初始化 modelMeta 类

 @param cls 当前类
 @return 初始化后的m meta 模型
 */
+ (instancetype)metaWithClass:(Class)cls;
@end

NS_ASSUME_NONNULL_END
