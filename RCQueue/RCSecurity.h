//
//  RCSecurity.h
//  RCAsyncTaskLib
//
//  Created by 孙承秀 on 2018/6/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCSecurity : NSObject
/**
 Check safety
 */
@property(nonatomic , assign , readonly)int32_t value;
- (int32_t)GenerateSecurityValue;
@end
