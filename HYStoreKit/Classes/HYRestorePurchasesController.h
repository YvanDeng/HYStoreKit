//
//  HYRestorePurchasesController.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/24.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// value is an NSNumber that wrapper for `HYTransationResult`
extern NSString * const HYTransationResultKey;
// value is an HYPurchase instance or an NSError instance
extern NSString * const HYTransationResultDataKey;

typedef NSDictionary* HYTransationResultInfo;

@interface HYRestorePurchases : NSObject

@property (nonatomic, readonly) BOOL atomically;
@property (nonatomic, copy, readonly, nullable) NSString *applicationUsername;
@property (nonatomic, copy, readonly) void(^callback)(NSArray<HYTransationResultInfo> *results);

- (instancetype)initWithAtomically:(BOOL)atomically applicationUsername:(NSString * _Nullable)applicationUsername callback:(void(^)(NSArray<HYTransationResultInfo> *results))callback;

@end

@class SKPaymentTransaction;
@class SKPaymentQueue;
@interface HYRestorePurchasesController : NSObject

@property (nonatomic, strong, nullable) HYRestorePurchases *restorePurchases;

- (void)restoreCompletedTransactionsFailedWithError:(NSError *)error;
- (void)restoreCompletedTransactionsFinished;

- (NSArray<SKPaymentTransaction *> *)processTransactions:(NSArray<SKPaymentTransaction *> *)transactions onPaymentQueue:(SKPaymentQueue *)paymentQueue;

@end

NS_ASSUME_NONNULL_END
