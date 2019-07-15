//
//  HYRestorePurchasesController.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/24.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYRestorePurchasesController.h"
#import "HYStoreKit+Types.h"

#import "HYPaymentsController.h"

NSString * const HYTransationResultKey = @"com.dreame.HYStoreKit.HYTransationResult";
NSString * const HYTransationResultDataKey = @"com.dreame.HYStoreKit.HYTransationResultData";

@implementation HYRestorePurchases

- (instancetype)initWithAtomically:(BOOL)atomically applicationUsername:(NSString * _Nullable)applicationUsername callback:(nonnull void (^)(NSArray<HYTransationResultInfo> * _Nonnull))callback {
    self = [super init];
    if (self) {
        _atomically = atomically;
        _applicationUsername = applicationUsername;
        _callback = callback;
    }
    return self;
}

@end

@interface HYRestorePurchasesController ()

@property (nonatomic, strong) NSMutableArray<HYTransationResultInfo> *restoredPurchases;

@end

@implementation HYRestorePurchasesController

- (void)restoreCompletedTransactionsFailedWithError:(NSError *)error {
    if (!_restorePurchases) {
        NSLog(@"Callback already called. Returning");
        return;
    }
    
    HYTransationResultInfo result = @{HYTransationResultKey: @(HYTransactionResultFailed),
                                  HYTransationResultDataKey: error};
    [self.restoredPurchases addObject:result];
    if (self.restorePurchases.callback) {
        self.restorePurchases.callback(self.restoredPurchases.copy);
    }

    // Reset state after error received
    [self.restoredPurchases removeAllObjects];
    self.restorePurchases = nil;
}

- (void)restoreCompletedTransactionsFinished {
    if (!_restorePurchases) {
        NSLog(@"Callback already called. Returning");
        return;
    }
    if (self.restorePurchases.callback) {
        self.restorePurchases.callback(self.restoredPurchases.copy);
    }

    // Reset state after error received
    [self.restoredPurchases removeAllObjects];
    self.restorePurchases = nil;
}

#pragma mark - TransactionController

- (NSArray<SKPaymentTransaction *> *)processTransactions:(NSArray<SKPaymentTransaction *> *)transactions onPaymentQueue:(SKPaymentQueue *)paymentQueue {
    if (!_restorePurchases) return transactions;
    
    NSMutableArray<SKPaymentTransaction *> *unhandledTransactions = @[].mutableCopy;
    for (SKPaymentTransaction *transaction in transactions) {
        HYPurchase *restoredPurchase = [self processTransaction:transaction atomically:self.restorePurchases.atomically onPaymentQueue:paymentQueue];
        if (restoredPurchase) {
            HYTransationResultInfo result = @{HYTransationResultKey: @(HYTransactionResultRestored),    HYTransationResultDataKey: restoredPurchase};
            [self.restoredPurchases addObject:result];
        } else {
            [unhandledTransactions addObject:transaction];
        }
    }
    
    return unhandledTransactions.copy;
}

- (HYPurchase * _Nullable)processTransaction:(SKPaymentTransaction *)transaction atomically:(BOOL)atomically onPaymentQueue:(SKPaymentQueue *)paymentQueue {
    SKPaymentTransactionState transactionState = transaction.transactionState;
    if (transactionState == SKPaymentTransactionStateRestored) {
        NSString *transactionProductIdentifier = transaction.payment.productIdentifier;
        HYPurchase *purchase = [[HYPurchase alloc] initWithProductId:transactionProductIdentifier product:nil quantity:transaction.payment.quantity transaction:transaction needsFinishTransaction:!atomically];
        if (atomically) {
            [paymentQueue finishTransaction:transaction];
        }
        return purchase;
    }
    return nil;
}

#pragma mark - getter

- (NSMutableArray<HYTransationResultInfo> *)restoredPurchases {
    if (!_restoredPurchases) {
        _restoredPurchases = [NSMutableArray array];
    }
    return _restoredPurchases;
}

@end
