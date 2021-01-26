//
//  HYNetworkActivityIndicatorManager.m
//  HYStoreKit_Example
//
//  Created by 邓逸远 on 2020/10/21.
//  Copyright © 2020 邓逸远. All rights reserved.
//

#import "HYNetworkActivityIndicatorManager.h"

static NSInteger loadingCount = 0;

@implementation HYNetworkActivityIndicatorManager

+ (void)networkOperationStarted {
    if (loadingCount == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    }
    loadingCount += 1;
}

+ (void)networkOperationFinished {
    if (loadingCount > 0) {
        loadingCount -= 1;
    }
    if (loadingCount == 0) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    }
}

@end
