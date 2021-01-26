//
//  HYNetworkActivityIndicatorManager.h
//  HYStoreKit_Example
//
//  Created by 邓逸远 on 2020/10/21.
//  Copyright © 2020 邓逸远. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYNetworkActivityIndicatorManager : NSObject

+ (void)networkOperationStarted;
+ (void)networkOperationFinished;

@end

NS_ASSUME_NONNULL_END
