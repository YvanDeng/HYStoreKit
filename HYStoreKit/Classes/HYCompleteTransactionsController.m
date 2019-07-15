//
//  HYCompleteTransactionsController.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/24.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYCompleteTransactionsController.h"
#import "HYStoreKit+Types.h"

@implementation HYCompleteTransactions

- (instancetype)initWithAtomically:(BOOL)atomically callback:(void (^)(NSArray<HYPurchase *> * _Nonnull))callback {
    self = [super init];
    if (self) {
        _atomically = atomically;
        _callback = callback;
    }
    return self;
}

@end

@implementation HYCompleteTransactionsController

- (NSArray<SKPaymentTransaction *> *)processTransactions:(NSArray<SKPaymentTransaction *> *)transactions onPaymentQueue:(SKPaymentQueue *)paymentQueue {
    if (!self.completeTransactions) {
        NSLog(@"HYStoreKit.completeTransactions() should be called once when the app launches.");
        return transactions;
    }
    
    NSMutableArray<SKPaymentTransaction *> *unhandledTransactions = @[].mutableCopy;
    NSMutableArray<HYPurchase *> *purchases = @[].mutableCopy;
    
    for (SKPaymentTransaction *transaction in transactions) {
        SKPaymentTransactionState transactionState = transaction.transactionState;
        if (transactionState != SKPaymentTransactionStatePurchasing) {
            BOOL willFinishTransaction = self.completeTransactions.atomically || transactionState == SKPaymentTransactionStateFailed;
            HYPurchase *purchase = [[HYPurchase alloc] initWithProductId:transaction.payment.productIdentifier product:nil quantity:transaction.payment.quantity transaction:transaction needsFinishTransaction:!willFinishTransaction];
            [purchases addObject:purchase];
            
            if (willFinishTransaction) {
                NSLog(@"Finishing transaction for payment \"%@\" with state: %@", transaction.payment.productIdentifier, @(transactionState));
                [paymentQueue finishTransaction:transaction];
            }
        } else {
            [unhandledTransactions addObject:transaction];
        }
    }

    if (purchases.count > 0 && self.completeTransactions.callback) {
        self.completeTransactions.callback(purchases.copy);
    }
    
    return unhandledTransactions.copy;
}

@end
