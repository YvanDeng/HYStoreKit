//
//  HYPaymentQueueController.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYPaymentQueueController.h"
#import "HYPaymentsController.h"
#import "HYRestorePurchasesController.h"
#import "HYCompleteTransactionsController.h"
#import "HYStoreKit+Types.h"

@implementation SKPaymentTransaction (Log)

- (NSString *)debugDescription {
    NSString *transactionId = self.transactionIdentifier ? self.transactionIdentifier : @"null";
    NSString *stateString;
    switch (self.transactionState) {
        case SKPaymentTransactionStatePurchasing:
            stateString = @"purchasing";
        case SKPaymentTransactionStatePurchased:
            stateString = @"purchased";
        case SKPaymentTransactionStateFailed:
            stateString = @"failed";
        case SKPaymentTransactionStateRestored:
            stateString = @"restored";
        case SKPaymentTransactionStateDeferred:
            stateString = @"deferred";
    }
    return [NSString stringWithFormat:@"productId: %@, transactionId: %@, state: %@, date: %@", self.payment.productIdentifier, transactionId, stateString, self.transactionDate.description];
}

@end

@interface HYPaymentQueueController ()<SKPaymentTransactionObserver>

@property (nonatomic, strong) HYPaymentsController *paymentsController;
@property (nonatomic, strong) HYRestorePurchasesController *restorePurchasesController;
@property (nonatomic, strong) HYCompleteTransactionsController *completeTransactionsController;

@end

@implementation HYPaymentQueueController

- (instancetype)init {
    self = [super init];
    if (self) {
        _paymentsController = [[HYPaymentsController alloc] init];
        _restorePurchasesController = [[HYRestorePurchasesController alloc] init];
        _completeTransactionsController = [[HYCompleteTransactionsController alloc] init];
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}

- (void)dealloc {
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

#pragma mark -

- (void)startPayment:(HYPayment *)payment {
    [self assertCompleteTransactionsWasCalled];
    
    SKMutablePayment *skPayment = [SKMutablePayment paymentWithProduct:payment.product];
    skPayment.applicationUsername = payment.applicationUsername;
    skPayment.quantity = payment.quantity;
    if (@available(iOS 8.3, *)) {
        skPayment.simulatesAskToBuyInSandbox = payment.simulatesAskToBuyInSandbox;
    }
    [[SKPaymentQueue defaultQueue] addPayment:skPayment];
    
    [self.paymentsController addPayment:payment];
}

- (void)restorePurchases:(HYRestorePurchases *)restorePurchases {
    [self assertCompleteTransactionsWasCalled];
    
    if (self.restorePurchasesController.restorePurchases) return;
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactionsWithApplicationUsername:restorePurchases.applicationUsername];
    
    self.restorePurchasesController.restorePurchases = restorePurchases;
}

- (void)completeTransactions:(HYCompleteTransactions *)completeTransactions {
    if (self.completeTransactionsController.completeTransactions) {
        NSLog(@"HYStoreKit.completeTransactions() should only be called once when the app launches. Ignoring this call");
        return;
    }

    self.completeTransactionsController.completeTransactions = completeTransactions;
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)startDownloads:(NSArray<SKDownload *> *)downloads {
    [[SKPaymentQueue defaultQueue] startDownloads:downloads];
}

- (void)pauseDownloads:(NSArray<SKDownload *> *)downloads {
    [[SKPaymentQueue defaultQueue] pauseDownloads:downloads];
}

- (void)resumeDownloads:(NSArray<SKDownload *> *)downloads {
    [[SKPaymentQueue defaultQueue] resumeDownloads:downloads];
}

- (void)cancelDownloads:(NSArray<SKDownload *> *)downloads {
    [[SKPaymentQueue defaultQueue] cancelDownloads:downloads];
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    /*
     * 有关SKPaymentQueue如何处理请求的一些注意事项:
     *
     * SKPaymentQueue 用于排队付款 Payments 或恢复购买请求 Restore purchases requests.
     * Payments 是连续有序的处理，需要与用户交互.
     * Restore purchases requests 不需要用户交互，可以跳到队列头部.
     * SKPaymentQueue 拒绝多次恢复购买调用.
     * 为每个请求设置一个支付队列观察器会导致额外的处理.
     * Failed transactions 只属于排队的付款请求payment request.
     * restoreCompletedTransactionsFailedWithError 在恢复购买请求失败时始终会调用.
     * paymentQueueRestoreCompletedTransactionsFinished 当恢复购买请求成功时，始终在0个或更多update transaction后调用.
     * 需要一个complete transactions handler来捕获应用程序未运行时更新的任何transactions.
     * 在应用程序启动时，注册一个complete transactions handler可确保可以清除任意挂起的transactions.
     * 如果缺少complete transactions handler，则待处理的transactions可能会错误地归因于任何new incoming payments or restore purchases.
     *
     * 处理transaction更新的顺序:
     * 1. payments (transactionState: .purchased and .failed for matching product identifiers)
     * 2. restore purchases (transactionState: .restored, or restoreCompletedTransactionsFailedWithError, or paymentQueueRestoreCompletedTransactionsFinished)
     * 3. complete transactions (transactionState: .purchased, .failed, .restored, .deferred)
     * Any transactions where state == .purchasing are ignored.
     */
    
    NSArray<SKPaymentTransaction *> *unhandledTransactions = [transactions filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(SKPaymentTransaction *  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return evaluatedObject.transactionState != SKPaymentTransactionStatePurchasing;
    }]];
    
    if (unhandledTransactions.count > 0) {
        unhandledTransactions = [self.paymentsController processTransactions:transactions onPaymentQueue:queue];
        
        unhandledTransactions = [self.restorePurchasesController processTransactions:unhandledTransactions onPaymentQueue:queue];
        
        unhandledTransactions = [self.completeTransactionsController processTransactions:unhandledTransactions onPaymentQueue:queue];
        
        if (unhandledTransactions.count > 0) {
            NSMutableString *strings = [[NSMutableString alloc] init];
            for (SKPaymentTransaction *transaction in unhandledTransactions) {
                [strings appendFormat:@"%@\n", transaction.debugDescription];
            }
            NSLog(@"unhandledTransactions:\n%@", strings);
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    [self.restorePurchasesController restoreCompletedTransactionsFailedWithError:error];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    [self.restorePurchasesController restoreCompletedTransactionsFinished];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads {
    if (self.updatedDownloadsHandler) {
        self.updatedDownloadsHandler(downloads);
    }
}

- (BOOL)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment forProduct:(SKProduct *)product {
    if (self.shouldAddStorePaymentHandler) {
        return self.shouldAddStorePaymentHandler(payment, product);
    }
    return NO;
}

#pragma mark - private methods

- (void)assertCompleteTransactionsWasCalled {
    NSString *message = @"HYStoreKit.completeTransactions() must be called when the app launches.";
    NSAssert(self.completeTransactionsController.completeTransactions != nil, message);
}

@end
