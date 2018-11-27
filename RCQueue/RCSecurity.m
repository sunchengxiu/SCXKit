//
//  RCSecurity.m
//  RCAsyncTaskLib
//
//  Created by 孙承秀 on 2018/6/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCSecurity.h"
#import <libkern/OSAtomic.h>
@interface RCSecurity()
/**
 Check safety
 */
@property(nonatomic , assign )int32_t value;
@end
@implementation RCSecurity
-(int32_t)value{
    return self.value;
}
-(int32_t)GenerateSecurityValue{
    return OSAtomicIncrement32(&_value);
}
@end
