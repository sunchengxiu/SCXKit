//
//  RCAsyncDisplayTaskDelegate.h
//  RCAsyncTaskLib
//
//  Created by 孙承秀 on 2018/6/8.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RCAsyncDisplayTask;
@protocol RCAsyncDisplayTaskDelegate <NSObject>
@required
- (RCAsyncDisplayTask *)asyncDisplayTask;
@end
