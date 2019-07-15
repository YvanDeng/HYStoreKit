//
//  HYPaymentsController.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/24.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYPaymentsController.h"
#import "HYStoreKit+Types.h"

@implementation HYPayment

- (instancetype)initWithProduct:(SKProduct *)product
                       quantity:(NSUInteger)quantity
                     atomically:(BOOL)atomically
            applicationUsername:(NSString *)applicationUsername
     simulatesAskToBuyInSandbox:(BOOL)simulatesAskToBuyInSandbox
                       callback:(void (^)(HYTransactionResult, HYPurchase * _Nullable, NSError * _Nullable))callback {
    self = [super init];
    if (self) {
        _product = product;
        _quantity = quantity;
        _atomically = atomically;
        _applicationUsername = applicationUsername;
        _simulatesAskToBuyInSandbox = simulatesAskToBuyInSandbox;
        _callback = callback;
    }
    return self;
}

- (NSUInteger)hashValue {
    return self.product.productIdentifier.hash;
}

- (BOOL)isEqualToPayment:(HYPayment *)payment {
    return [self.product.productIdentifier isEqualToString:payment.product.productIdentifier];
}

@end

@interface HYPaymentsController ()

@property (nonatomic, strong) NSMutableArray<HYPayment *> *payments;

@end

@implementation HYPaymentsController

- (NSInteger)findPaymentIndexWithProductIdentifier:(NSString *)identifier {
    for (HYPayment *payment in self.payments) {
        if ([payment.product.productIdentifier isEqualToString:identifier]) {
            return [self.payments indexOfObject:payment];
        }
    }
    return NSNotFound;
}

- (BOOL)hasPayment:(HYPayment *)payment {
    return [self findPaymentIndexWithProductIdentifier:payment.product.productIdentifier] != NSNotFound;
}

- (void)addPayment:(HYPayment *)payment {
    [self.payments addObject:payment];
}

- (NSArray<SKPaymentTransaction *> *)processTransactions:(NSArray<SKPaymentTransaction *> *)transactions onPaymentQueue:(SKPaymentQueue *)paymentQueue {
    return [transactions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return ![self processTransaction:evaluatedObject onPaymentQueue:paymentQueue];
    }]];
}

- (BOOL)processTransaction:(SKPaymentTransaction *)transaction onPaymentQueue:(SKPaymentQueue *)paymentQueue {
    NSString *transactionProductIdentifier = transaction.payment.productIdentifier;
    if ([self findPaymentIndexWithProductIdentifier:transactionProductIdentifier] == NSNotFound) return NO;
    
    NSUInteger paymentIndex = [self findPaymentIndexWithProductIdentifier:transactionProductIdentifier];
    HYPayment *payment = self.payments[paymentIndex];
    SKPaymentTransactionState transactionState = transaction.transactionState;
    if (transactionState == SKPaymentTransactionStatePurchased) {
        if (payment.callback) {
            HYPurchase *purchase = [[HYPurchase alloc] initWithProductId:transactionProductIdentifier product:payment.product quantity:transaction.payment.quantity transaction:transaction needsFinishTransaction:!payment.atomically];
            payment.callback(HYTransactionResultPurchased, purchase, nil);
        }
        
        if (payment.atomically) {
            [paymentQueue finishTransaction:transaction];
        }
        [self.payments removeObjectAtIndex:paymentIndex];
        
        return YES;
    }
    if (transactionState == SKPaymentTransactionStateFailed) {
        if (payment.callback) {
            NSError *error = transaction.error;
            if (!error) {
                error = [NSError errorWithDomain:SKErrorDomain code:SKErrorUnknown userInfo:@{NSLocalizedDescriptionKey : @"Unknown error"}];
            }
            payment.callback(HYTransactionResultFailed, nil, error);
        }
        
        [paymentQueue finishTransaction:transaction];
        [self.payments removeObjectAtIndex:paymentIndex];
        
        return YES;
    }
    if (transactionState == SKPaymentTransactionStateRestored) {
        NSLog(@"Unexpected restored transaction for payment %@", transactionProductIdentifier);
    }
    return NO;
}

#pragma mark - getter

- (NSMutableArray<HYPayment *> *)payments {
    if (!_payments) {
        _payments = [NSMutableArray array];
    }
    return _payments;
}

@end
