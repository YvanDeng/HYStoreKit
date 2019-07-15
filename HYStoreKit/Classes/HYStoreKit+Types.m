//
//  HYStoreKit+Types.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYStoreKit+Types.h"

NSErrorUserInfoKey const HYInvalidProductIdentifierKey = @"com.dreame.HYStoreKit.HYInvalidProductIdentifier";

@implementation HYPurchase

- (instancetype)initWithProductId:(NSString *)productId
                          product:(SKProduct *)product
                         quantity:(NSUInteger)quantity
                      transaction:(SKPaymentTransaction *)transaction
           needsFinishTransaction:(BOOL)needsFinishTransaction {
    self = [super init];
    if (self) {
        _productId = productId;
        _product = product;
        _quantity = quantity;
        _transaction = transaction;
        _needsFinishTransaction = needsFinishTransaction;
    }
    return self;
}

@end

@implementation HYVerifySubscriptionResult

- (instancetype)initWithSubscriptionStatus:(HYSubscriptionStatus)status items:(NSArray<HYReceiptItem *> *)items {
    self = [super init];
    if (self) {
        self->_status = status;
        self->_items = items;
    }
    return self;
}

@end

@implementation HYSubscription

- (instancetype)initWithSubscriptionType:(HYSubscriptionType)subscriptionType validDuration:(NSTimeInterval)validDuration {
    self = [super init];
    if (self) {
        _subscriptionType = subscriptionType;
        _validDuration = validDuration;
    }
    return self;
}

@end

@implementation HYReceiptItem

- (instancetype)initWithReceiptInfo:(NSDictionary<NSString *,id> *)receiptInfo {
    if (!receiptInfo) return nil;
    
    NSString *productId = receiptInfo[@"product_id"];
    NSInteger quantity = [receiptInfo[@"quantity"] integerValue];
    NSString *transactionId = receiptInfo[@"transaction_id"];
    NSString *originalTransactionId = receiptInfo[@"original_transaction_id"];
    NSDate *purchaseDate = [HYReceiptItem parseDateFromReceiptInfo:receiptInfo key:@"purchase_date_ms"];
    NSDate *originalPurchaseDate = [HYReceiptItem parseDateFromReceiptInfo:receiptInfo key:@"original_purchase_date_ms"];
    if (!productId || !quantity || !transactionId || !originalTransactionId || !purchaseDate || !originalPurchaseDate) {
        NSLog(@"could not parse receipt item: %@. Skipping...", receiptInfo);
        return nil;
    }
    
    self->_productId = productId;
    self->_quantity = quantity;
    self->_transactionId = transactionId;
    self->_originalTransactionId = originalTransactionId;
    self->_purchaseDate = purchaseDate;
    self->_originalPurchaseDate = originalPurchaseDate;
    self->_webOrderLineItemId = receiptInfo[@"web_order_line_item_id"];
    self->_subscriptionExpirationDate = [HYReceiptItem parseDateFromReceiptInfo:receiptInfo key:@"expires_date_ms"];
    self->_cancellationDate = [HYReceiptItem parseDateFromReceiptInfo:receiptInfo key:@"cancellation_date_ms"];
    self->_isTrialPeriod = [receiptInfo[@"is_trial_period"] boolValue];
    self->_isInIntroOfferPeriod = [receiptInfo[@"is_in_intro_offer_period"] boolValue];
    
    return self;
}

+ (NSDate * _Nullable)parseDateFromReceiptInfo:(NSDictionary<NSString *,id> *)receiptInfo key:(NSString *)key {
    if ([receiptInfo.allKeys containsObject:key] && [receiptInfo[key] doubleValue] > 0) {
        return [NSDate dateWithTimeIntervalSince1970: [receiptInfo[key] doubleValue] / 1000];
    }
    return nil;
}

@end

@implementation HYReceiptError

+ (instancetype)receiptErrorWithErrorType:(HYReceiptErrorType)errorType {
    HYReceiptError *receiptError = [HYReceiptError new];
    receiptError->_receiptErrorType = errorType;
    return receiptError;
}

+ (instancetype)receiptErrorWithErrorType:(HYReceiptErrorType)errorType error:(NSError *)error {
    HYReceiptError *receiptError = [HYReceiptError new];
    receiptError->_receiptErrorType = errorType;
    receiptError->_error = error;
    return receiptError;
}

+ (instancetype)receiptErrorWithErrorType:(HYReceiptErrorType)errorType decodeJson:(NSString *)decodeJson {
    HYReceiptError *receiptError = [HYReceiptError new];
    receiptError->_receiptErrorType = errorType;
    receiptError->_decodeJson = decodeJson;
    return receiptError;
}

+ (instancetype)receiptErrorWithErrorType:(HYReceiptErrorType)errorType receipt:(NSDictionary<NSString *,id> *)receipt status:(HYReceiptStatus)status {
    HYReceiptError *receiptError = [HYReceiptError new];
    receiptError->_receiptErrorType = errorType;
    receiptError->_receipt = receipt;
    receiptError->_status = status;
    return receiptError;
}

@end

@implementation HYReceiptInfoField

@end

@implementation HYInApp

@end
