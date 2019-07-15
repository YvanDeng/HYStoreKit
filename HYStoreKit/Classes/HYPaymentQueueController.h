//
//  HYPaymentQueueController.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYStoreKit+Types.h"

NS_ASSUME_NONNULL_BEGIN

@interface SKPaymentTransaction (Log)

- (NSString *)debugDescription;

@end

@class HYPayment;
@class HYRestorePurchases;
@class HYCompleteTransactions;
@class SKPaymentTransaction;
@interface HYPaymentQueueController : NSObject

@property (nonatomic, copy, nullable) HYShouldAddStorePaymentHandler shouldAddStorePaymentHandler;
@property (nonatomic, copy, nullable) HYUpdatedDownloadsHandler updatedDownloadsHandler;

- (void)startPayment:(HYPayment *)payment;
- (void)restorePurchases:(HYRestorePurchases *)restorePurchases;
- (void)completeTransactions:(HYCompleteTransactions *)completeTransactions;
- (void)finishTransaction:(SKPaymentTransaction *)transaction;

- (void)startDownloads:(NSArray<SKDownload *> *)downloads;
- (void)pauseDownloads:(NSArray<SKDownload *> *)downloads;
- (void)resumeDownloads:(NSArray<SKDownload *> *)downloads;
- (void)cancelDownloads:(NSArray<SKDownload *> *)downloads;

@end

NS_ASSUME_NONNULL_END
