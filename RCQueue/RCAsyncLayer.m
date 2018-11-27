//
//  RCAsyncLayer.m
//  RCAsyncTaskLib
//
//  Created by 孙承秀 on 2018/6/8.
//  Copyright © 2018年 RongCloud. All rights reserved.
//

#import "RCAsyncLayer.h"
#import "RCDispatchAsyncQueue.h"
#import "RCSecurity.h"
#import "RCAsyncDisplayTask.h"


#define WILLDISPLAY(object) if (task.willDisplay) {\
task.willDisplay(object);\
}

#define DIDDISPLAY(object,value) if (task.didDisplay) {\
task.didDisplay(self, value);\
}

 dispatch_queue_t RCAsyncLayerGetDispatchQueue(){
     return RCDispatchQueuePool(NSQualityOfServiceUserInteractive);
}
static dispatch_queue_t RCAsyncLayerGetReleaseQueue(){
    return RCDispatchQueuePool(NSQualityOfServiceDefault );
}
@implementation RCAsyncLayer{
    RCSecurity *_safer;
}
-(instancetype)init{
    
    self = [super init];
    static CGFloat scale;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        scale = [UIScreen mainScreen].scale;
    });
    self.contentsScale = scale;
    _safer = [RCSecurity new];
    _asyncToDisplay = YES;
    return self;
}
- (void)asyncDisplay:(BOOL)async{
    __strong id <RCAsyncDisplayTaskDelegate> delegate = (id)self.delegate;
    RCAsyncDisplayTask *task = [delegate asyncDisplayTask];
    if (!task.display) {
        WILLDISPLAY(self);
        self.contents = nil;
        DIDDISPLAY(self,YES);
        return;
    }
    if (async) {
        WILLDISPLAY(self);
        RCSecurity *safer = [RCSecurity new];
        int32_t count = safer.value;
        BOOL (^isCancel)(void) = ^ BOOL {
            return  count != safer.value;
        };
        CGSize size = self.bounds.size;
        BOOL opaque = self.opaque;
        CGFloat scale = self.contentsScale;
        CGColorRef backgroundcolor = (opaque && self.backgroundColor) ? CGColorRetain(self.backgroundColor) : NULL;
        if (size.width < 1 ||size.height < 1) {
            CGImageRef ref = (__bridge CGImageRef)self.contents;
            self.contents = nil;
            dispatch_async(RCAsyncLayerGetReleaseQueue(), ^{
                CFRelease(ref);
            });
            DIDDISPLAY(self, YES);
            CGColorRelease(backgroundcolor);
            return;
        }
        dispatch_async(RCAsyncLayerGetDispatchQueue(), ^{
            if (isCancel()) {
                CGColorRelease(backgroundcolor);
                return ;
            }
            UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
            CGContextRef context = UIGraphicsGetCurrentContext();
            if (opaque) {
                CGContextSaveGState(context);{
                    if (!backgroundcolor || CGColorGetAlpha(backgroundcolor) < 1) {
                        CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                        CGContextAddRect(context, CGRectMake(0, 0, size.width *scale, size.height * scale));
                        CGContextFillPath(context);
                    }
                    if (backgroundcolor) {
                        CGContextSetFillColorWithColor(context, backgroundcolor);
                        CGContextAddRect(context, CGRectMake(0, 0, size.width * scale, size.height * scale));
                        CGContextFillPath(context);
                    }
                    
                } CGContextRestoreGState(context);
            }
            
            task.display(context, size, isCancel);
            
            if (isCancel()) {
                UIGraphicsEndImageContext();
                dispatch_async(dispatch_get_main_queue(), ^{
                    DIDDISPLAY(self, NO);
                });
                return;
            }
            UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            if (isCancel()) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    DIDDISPLAY(self, NO);
                });
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if (isCancel()) {
                    DIDDISPLAY(self, NO);
                    return;
                } else {
                    self.contents = (__bridge id)image.CGImage;
                    DIDDISPLAY(self, YES);
                }
            });
        });
    } else {
        [_safer GenerateSecurityValue];
        WILLDISPLAY(self);
        CGSize size = self.bounds.size;
        BOOL opaque = self.opaque;
        CGFloat scale = self.contentsScale;
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, self.contentsScale);
        CGContextRef context = UIGraphicsGetCurrentContext();
        if (opaque) {
            if (!self.backgroundColor || CGColorGetAlpha(self.backgroundColor)) {
                CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
                CGContextAddRect(context, CGRectMake(0, 0, size.width * scale, size.height * scale));
                CGContextFillPath(context);
            } else {
                CGContextSetFillColorWithColor(context, self.backgroundColor);
                CGContextAddRect(context, CGRectMake(0, 0, size.width, size.height));
                CGContextFillPath(context);
            }
        }
        task.display(context, size, ^BOOL{
            return NO;
        });
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.contents = (__bridge id)image.CGImage;
        DIDDISPLAY(self, YES);
        
    }
}
-(void)setNeedsDisplay{
    [self cancelDisplay];
    [super setNeedsDisplay];
}
-(void)display{
    super.contents = super.contents;
    [self asyncDisplay:_asyncToDisplay];
}
-(void)cancelDisplay{
    [_safer GenerateSecurityValue];
}
-(void)dealloc{
    [_safer GenerateSecurityValue];
}
@end
