//
//  RCAsyncLayer.h
//  RCAsyncTaskLib
//
//  Created by 孙承秀 on 2018/6/8.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "RCAsyncDisplayTaskDelegate.h"
@interface RCAsyncLayer : CALayer

/**
 是否需要异步绘制
 */
@property(nonatomic , assign)BOOL asyncToDisplay;
@end
