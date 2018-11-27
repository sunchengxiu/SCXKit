//
//  RCRunloopTransaction.m
//  RCAsyncTaskLib
//
//  Created by 孙承秀 on 2018/6/7.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCRunloopTransaction.h"
@interface RCRunloopTransaction()
/**
 target
 */
@property(nonatomic , strong)id target;
/**
 sel
 */
@property(nonatomic , assign)SEL selector;
@end
static NSMutableSet *transactions;


static void RCRunLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info){
    if (transactions.count == 0) {
        return;
    }
    NSMutableSet *set = transactions;
    transactions = [NSMutableSet new];
    [set enumerateObjectsUsingBlock:^(RCRunloopTransaction *transaction, BOOL * _Nonnull stop) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [transaction.target performSelector:transaction.selector];
#pragma clang diagnostic pop
    }];
}
static void RCSetUpRunloop(){
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transactions = [NSMutableSet set];
        CFRunLoopRef ref = CFRunLoopGetMain();
        CFRunLoopObserverRef observer = CFRunLoopObserverCreate(CFAllocatorGetDefault(), kCFRunLoopBeforeWaiting | kCFRunLoopExit, YES, 0xFFFFFF, RCRunLoopObserverCallBack, NULL);
        CFRunLoopAddObserver(ref, observer, kCFRunLoopCommonModes);
        CFRelease(observer);
    });
}

@implementation RCRunloopTransaction

+ (RCRunloopTransaction *)transactionWithTarget:(id)target selector:(SEL)selector{
    if (!target || !selector) {
        return nil;
    }
    RCRunloopTransaction *transaction = [[RCRunloopTransaction alloc] init];
    transaction.target = target;
    transaction.selector = selector;
    return transaction;
}

- (void)commit{
    if (!_target || !_selector) {
        return;
    }
    RCSetUpRunloop();
    [transactions addObject:self];
}

- (NSUInteger)hash{
    long h1 = (long)((void *)_selector);
    long h2 = (long)(_target);
    return h1^h2;
                     
}
-(BOOL)isEqual:(id)object{
    if (self == object) {
        return YES;
    }
    if (![object isMemberOfClass:self.class]) {
        return NO;
    }
    RCRunloopTransaction *transaction = object;
    return transaction.selector == self.selector && self.target == transaction.target;
}

@end
