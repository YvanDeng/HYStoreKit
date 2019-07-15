//
//  HYProductsInfoController.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class SKProduct;
@interface HYProductsInfoController : NSObject

- (void)retrieveProductsInfoWithProductIds:(NSSet<NSString *> *)productIds completion:(void(^)(NSArray<SKProduct *> *retrievedProducts, NSArray<NSString *> *invalidProductIDs, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
