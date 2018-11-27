//
//  RCAsyncDisplayTask.h
//  RCAsyncTaskLib
//
//  Created by 孙承秀 on 2018/6/8.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef void (^WillDisplayLayer)(CALayer *layer);
typedef void(^DisplayLayer) (CGContextRef contextRef,CGSize size , BOOL (^isCancel)(void));
typedef void(^DidDisplayLayer) (CALayer *layer , BOOL finish);
@interface RCAsyncDisplayTask : NSObject
/**
 will displat
 */
@property(nonatomic , copy)WillDisplayLayer willDisplay;
/**
 display
 */
@property(nonatomic , copy)DisplayLayer display;
/**
 did display
 */
@property(nonatomic , copy)DidDisplayLayer didDisplay;

@end

