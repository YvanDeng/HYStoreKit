//
//  HYCompleteTransactionsController.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/24.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class HYPurchase;
@interface HYCompleteTransactions : NSObject

@property (nonatomic, readonly) BOOL atomically;
@property (nonatomic, copy) void(^callback)(NSArray<HYPurchase *> *purchases);

- (instancetype)initWithAtomically:(BOOL)atomically callback:(void(^)(NSArray<HYPurchase *> *))callback;

@end

@class SKPaymentTransaction;
@class SKPaymentQueue;
@interface HYCompleteTransactionsController : NSObject

@property (nonatomic, strong, nullable) HYCompleteTransactions *completeTransactions;

- (NSArray<SKPaymentTransaction *> *)processTransactions:(NSArray<SKPaymentTransaction *> *)transactions onPaymentQueue:(SKPaymentQueue *)paymentQueue;

@end


NS_ASSUME_NONNULL_END
