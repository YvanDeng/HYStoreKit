//
//  HYPaymentsController.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/24.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HYTransactionResult) {
    HYTransactionResultPurchased,
    HYTransactionResultRestored,
    HYTransactionResultFailed
};

@class SKProduct;
@class HYPurchase;
@interface HYPayment : NSObject

@property (nonatomic, strong, readonly) SKProduct *product;
@property (nonatomic, readonly) NSUInteger quantity;
@property (nonatomic, readonly) BOOL atomically;
@property (nonatomic, copy, readonly, nullable) NSString *applicationUsername;
@property (nonatomic, readonly) BOOL simulatesAskToBuyInSandbox;
@property (nonatomic, copy, readonly) void(^callback)(HYTransactionResult result, HYPurchase * _Nullable purchase, NSError * _Nullable error);

- (instancetype)initWithProduct:(SKProduct *)product
                       quantity:(NSUInteger)quantity
                     atomically:(BOOL)atomically
            applicationUsername:(NSString * _Nullable)applicationUsername
     simulatesAskToBuyInSandbox:(BOOL)simulatesAskToBuyInSandbox
                       callback:(void(^)(HYTransactionResult result, HYPurchase * _Nullable purchase, NSError * _Nullable error))callback;

- (NSUInteger)hashValue;
- (BOOL)isEqualToPayment:(HYPayment *)payment;

@end

@class SKPaymentTransaction;
@class SKPaymentQueue;
@interface HYPaymentsController : NSObject

- (BOOL)hasPayment:(HYPayment *)payment;
- (void)addPayment:(HYPayment *)payment;

// 处理payment类型交易
- (NSArray<SKPaymentTransaction *> *)processTransactions:(NSArray<SKPaymentTransaction *> *)transactions onPaymentQueue:(SKPaymentQueue *)paymentQueue;

@end

NS_ASSUME_NONNULL_END
