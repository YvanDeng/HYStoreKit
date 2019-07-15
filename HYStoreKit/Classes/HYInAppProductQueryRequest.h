//
//  HYInAppProductQueryRequest.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SKProduct;
@interface HYInAppProductQueryRequest : NSObject

- (instancetype)initWithProductIds:(NSSet<NSString *> *)productIds callback:(void(^)(NSArray<SKProduct *> *retrievedProducts, NSArray<NSString *> *invalidProductIDs, NSError * _Nullable error))callback;

- (void)start;
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
