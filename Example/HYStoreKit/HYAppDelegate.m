//
//  HYAppDelegate.m
//  HYStoreKit
//
//  Created by 邓逸远 on 06/18/2019.
//  Copyright (c) 2019 邓逸远. All rights reserved.
//

#import "HYAppDelegate.h"
#import <StoreKit/StoreKit.h>
#import <HYStoreKit/HYStoreKit.h>

@implementation HYAppDelegate

- (void)_setupIAP {
    [HYStoreKit completeTransactionsWithAtomically:YES completion:^(NSArray<HYPurchase *> * _Nonnull purchases) {
        for (HYPurchase *purchase in purchases) {
            switch (purchase.transaction.transactionState) {
                case SKPaymentTransactionStateRestored: {
                    NSArray<SKDownload *> *downloads = purchase.transaction.downloads;
                    if (downloads.count > 0) {
                        [HYStoreKit startDownloads:downloads];
                    } else if (purchase.needsFinishTransaction) {
                        [HYStoreKit finishTransaction:purchase.transaction];
                    }
                    NSLog(@"State %@: %@", @(purchase.transaction.transactionState), purchase.productId);
                }
                    break;
                case SKPaymentTransactionStateFailed:
                case SKPaymentTransactionStatePurchasing:
                case SKPaymentTransactionStateDeferred:
                    break; // do nothing
                default:
                    break; // do nothing
            }
        }
    }];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self _setupIAP];
    return YES;
}

@end
