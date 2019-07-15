//
//  HYStoreKit.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYStoreKit.h"

#import "HYProductsInfoController.h"
#import "HYPaymentQueueController.h"
#import "HYInAppReceiptVerificator.h"

#import "HYPaymentsController.h"
#import "HYRestorePurchasesController.h"
#import "HYCompleteTransactionsController.h"

#import "HYInAppReceipt.h"

@interface HYStoreKit ()

@property (nonatomic, strong) HYProductsInfoController *productsInfoController;
@property (nonatomic, strong) HYPaymentQueueController *paymentQueueController;
@property (nonatomic, strong) HYInAppReceiptVerificator *receiptVerificator;

/** 商品信息缓存 */
@property (nonatomic, strong) NSMutableDictionary<NSString *,SKProduct *> *productDict;

@end

@implementation HYStoreKit

+ (instancetype)sharedInstance {
    static HYStoreKit *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[HYStoreKit alloc] init];
    });
    return singleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _productsInfoController = [[HYProductsInfoController alloc] init];
        _paymentQueueController = [[HYPaymentQueueController alloc] init];
        _receiptVerificator = [[HYInAppReceiptVerificator alloc] init];
        _productDict = @{}.mutableCopy;
    }
    return self;
}

#pragma mark - private methods

- (void)retrieveProductsInfoWithProductIds:(NSSet<NSString *> *)productIds completion:(void(^)(NSArray<SKProduct *> * _Nullable, NSArray<NSString *> * _Nullable, NSError * _Nullable))completion {
    if (!productIds) return;
    
    NSMutableArray *products = @[].mutableCopy;
    NSMutableSet *mutableProductIds = [NSMutableSet setWithSet:productIds];
    [productIds enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, BOOL * _Nonnull stop) {
        SKProduct *product = self.productDict[obj];
        if (product) {
            [products addObject:product];
            [mutableProductIds removeObject:obj];
        }
    }];
    
    if (mutableProductIds.count > 0) {
        // 部分在缓存或者缓存中一个都没有
        [self.productsInfoController retrieveProductsInfoWithProductIds:mutableProductIds.copy completion:^(NSArray<SKProduct *> * _Nonnull retrievedProducts, NSArray<NSString *> * _Nonnull invalidProductIDs, NSError * _Nullable error) {
            [retrievedProducts enumerateObjectsUsingBlock:^(SKProduct * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                // 缓存
                self.productDict[obj.productIdentifier] = obj;
            }];
            [products addObjectsFromArray:retrievedProducts];
            if (completion) completion(products.copy, invalidProductIDs, error);
        }];
    } else {
        // 查询的商品都在缓存中
        if (completion) completion(products.copy, nil, nil);
    }
}

- (void)purchaseProductWithProductId:(NSString *)productId
                            quantity:(NSUInteger)quantity
                          atomically:(BOOL)atomically
                 applicationUsername:(NSString *)applicationUsername
          simulatesAskToBuyInSandbox:(BOOL)simulatesAskToBuyInSandbox
                          completion:(void(^_Nullable)(HYPurchase * _Nullable, NSError * _Nullable))completion {
    if (!productId || quantity == 0) return;
    
    [self retrieveProductsInfoWithProductIds:[NSSet setWithObject:productId] completion:^(NSArray<SKProduct *> * _Nullable retrievedProducts, NSArray<NSString *> * _Nullable invalidProductIDs, NSError * _Nullable error) {
        if (retrievedProducts.count > 0) {
            SKProduct *product = retrievedProducts.firstObject;
            [self purchaseProduct:product
                         quantity:quantity
                       atomically:atomically
              applicationUsername:applicationUsername
       simulatesAskToBuyInSandbox:simulatesAskToBuyInSandbox
                       completion:completion];
        } else if (error) {
            // 网络错误
            if (completion) completion(nil, error);
        } else if (invalidProductIDs.count > 0) {
            // productId无效
            if (completion) {
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Invalid product id: %@", invalidProductIDs.firstObject]};
                NSError *error = [[NSError alloc] initWithDomain:SKErrorDomain code:SKErrorPaymentInvalid userInfo:userInfo];
                completion(nil, error);
            }
        } else {
            // 未知错误
            if (completion) {
                NSError *error = [[NSError alloc] initWithDomain:SKErrorDomain code:SKErrorUnknown userInfo:nil];
                completion(nil, error);
            }
        }
    }];
}

- (void)purchaseProduct:(SKProduct *)product
               quantity:(NSUInteger)quantity
             atomically:(BOOL)atomically
    applicationUsername:(NSString *)applicationUsername
simulatesAskToBuyInSandbox:(BOOL)simulatesAskToBuyInSandbox
             completion:(void(^_Nullable)(HYPurchase * _Nullable, NSError * _Nullable))completion {
    if (![HYStoreKit canMakePayments]) {
        if (completion) {
            NSError *error = [NSError errorWithDomain:SKErrorDomain code:SKErrorPaymentNotAllowed userInfo:nil];
            completion(nil, error);
        }
        return;
    }
    
    HYPayment *payment = [[HYPayment alloc] initWithProduct:product quantity:quantity atomically:atomically applicationUsername:applicationUsername simulatesAskToBuyInSandbox:simulatesAskToBuyInSandbox callback:^(HYTransactionResult result, HYPurchase * _Nullable purchase, NSError * _Nullable error) {
        if (completion) {
            switch (result) {
                case HYTransactionResultPurchased:
                    completion(purchase, nil);
                    break;
                case HYTransactionResultFailed:
                    completion(nil, error);
                    break;
                case HYTransactionResultRestored: {
                    NSError *error = [self storeInternalErrorWithErrorCode:SKErrorUnknown description:[NSString stringWithFormat:@"Cannot restore product %@ from purchase path", purchase.productId] extraData:nil];
                    completion(nil, error);
                }
                    break;
            }
        }
    }];
    [self.paymentQueueController startPayment:payment];
}

- (void)restorePurchases:(BOOL)atomically applicationUsername:(NSString *)applicationUsername completion:(void(^)(NSArray<HYPurchase *> * _Nullable, NSArray<NSError *> * _Nullable))completion {
    HYRestorePurchases *restorePurchases = [[HYRestorePurchases alloc] initWithAtomically:atomically applicationUsername:applicationUsername callback:^(NSArray<HYTransationResultInfo> * _Nonnull results) {
        if (completion) {
            NSMutableArray<HYPurchase *> *restoredPurchases = @[].mutableCopy;
            NSMutableArray<NSError *> *restoreFailedPurchases = @[].mutableCopy;
            for (HYTransationResultInfo info in results) {
                HYTransactionResult result = [info[HYTransationResultKey] integerValue];
                id data = info[HYTransationResultDataKey];
                switch (result) {
                    case HYTransactionResultPurchased: {
                        if ([data isKindOfClass:[HYPurchase class]]) {
                            NSError *error = [self storeInternalErrorWithErrorCode:SKErrorUnknown description:[NSString stringWithFormat:@"Cannot purchase product %@ from restore purchases path", ((HYPurchase *)data).productId] extraData:((HYPurchase *)data).productId];
                            [restoreFailedPurchases addObject:error];
                        }
                    }
                        break;
                    case HYTransactionResultFailed:
                        if ([data isKindOfClass:[NSError class]]) {
                            [restoreFailedPurchases addObject:data];
                        }
                        break;
                    case HYTransactionResultRestored:
                        if ([data isKindOfClass:[HYPurchase class]]) {
                            [restoredPurchases addObject:data];
                        }
                        break;
                }
            }
            completion(restoredPurchases.copy, restoreFailedPurchases.copy);
        }
    }];
    [self.paymentQueueController restorePurchases:restorePurchases];
}

- (void)completeTransactions:(BOOL)atomically completion:(void(^)(NSArray<HYPurchase *> *purchases))completion {
     HYCompleteTransactions *completeTransactions = [[HYCompleteTransactions alloc] initWithAtomically:atomically callback:completion];
    [self.paymentQueueController completeTransactions:completeTransactions];
}

- (void)finishTransaction:(SKPaymentTransaction *)transaction {
    [self.paymentQueueController finishTransaction:transaction];
}

- (NSError *)storeInternalErrorWithErrorCode:(NSInteger)errorCode description:(NSString *)description extraData:(id)extraData {
    NSError *error;
    if (extraData) {
        error = [NSError errorWithDomain:SKErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey : description, HYInvalidProductIdentifierKey : extraData}];
    } else {
        error = [NSError errorWithDomain:SKErrorDomain code:errorCode userInfo:@{NSLocalizedDescriptionKey : description}];
    }
    return error;
}

#pragma mark - Public methods - Purchases

+ (BOOL)canMakePayments {
    return [SKPaymentQueue canMakePayments];
}

+ (void)retrieveProductsInfoWithProductIds:(NSSet<NSString *> *)productIds completion:(void (^)(NSArray<SKProduct *> * _Nullable, NSArray<NSString *> * _Nullable, NSError * _Nullable))completion {
    [[HYStoreKit sharedInstance] retrieveProductsInfoWithProductIds:productIds completion:completion];
}

+ (void)purchaseProductWithProductId:(NSString *)productId quantity:(NSUInteger)quantity atomically:(BOOL)atomically applicationUsername:(NSString *)applicationUsername simulatesAskToBuyInSandbox:(BOOL)simulatesAskToBuyInSandbox completion:(void (^)(HYPurchase * _Nullable, NSError * _Nullable))completion {
    [[HYStoreKit sharedInstance] purchaseProductWithProductId:productId quantity:quantity atomically:atomically applicationUsername:applicationUsername simulatesAskToBuyInSandbox:simulatesAskToBuyInSandbox completion:completion];
}

+ (void)purchaseProduct:(SKProduct *)product quantity:(NSUInteger)quantity atomically:(BOOL)atomically applicationUsername:(NSString *)applicationUsername simulatesAskToBuyInSandbox:(BOOL)simulatesAskToBuyInSandbox completion:(void (^)(HYPurchase * _Nullable, NSError * _Nullable))completion {
    [[HYStoreKit sharedInstance] purchaseProduct:product quantity:quantity atomically:atomically applicationUsername:applicationUsername simulatesAskToBuyInSandbox:simulatesAskToBuyInSandbox completion:completion];
}

+ (void)restorePurchasesWithAtomically:(BOOL)atomically applicationUsername:(NSString *)applicationUsername completion:(void (^)(NSArray<HYPurchase *> * _Nullable, NSArray<NSError *> * _Nullable))completion {
    [[HYStoreKit sharedInstance] restorePurchases:atomically applicationUsername:applicationUsername completion:completion];
}

+ (void)completeTransactionsWithAtomically:(BOOL)atomically completion:(void (^)(NSArray<HYPurchase *> * _Nonnull))completion {
    [[HYStoreKit sharedInstance] completeTransactions:atomically completion:completion];
}

+ (void)finishTransaction:(SKPaymentTransaction *)transaction {
    [[HYStoreKit sharedInstance] finishTransaction:transaction];
}

+ (void)setShouldAddStorePaymentHandler:(HYShouldAddStorePaymentHandler)shouldAddStorePaymentHandler {
    [HYStoreKit sharedInstance].paymentQueueController.shouldAddStorePaymentHandler = shouldAddStorePaymentHandler;
}

+ (void)setUpdatedDownloadsHandler:(HYUpdatedDownloadsHandler)updatedDownloadsHandler {
    [HYStoreKit sharedInstance].paymentQueueController.updatedDownloadsHandler = updatedDownloadsHandler;
}

+ (void)startDownloads:(NSArray<SKDownload *> *)downloads {
    [[HYStoreKit sharedInstance].paymentQueueController startDownloads:downloads];
}

+ (void)pauseDownloads:(NSArray<SKDownload *> *)downloads {
    [[HYStoreKit sharedInstance].paymentQueueController pauseDownloads:downloads];
}

+ (void)resumeDownloads:(NSArray<SKDownload *> *)downloads {
    [[HYStoreKit sharedInstance].paymentQueueController resumeDownloads:downloads];
}

+ (void)cancelDownloads:(NSArray<SKDownload *> *)downloads {
    [[HYStoreKit sharedInstance].paymentQueueController cancelDownloads:downloads];
}

#pragma mark - Public methods - Receipt verification

+ (NSData *)localReceiptData {
    return [HYStoreKit sharedInstance].receiptVerificator.appStoreReceiptData;
}

+ (void)verifyReceiptUsingValidator:(id<HYReceiptValidator>)validator forceRefresh:(BOOL)forceRefresh completion:(void (^)(NSDictionary<NSString *,id> * _Nullable, HYReceiptError * _Nullable))completion {
    [[HYStoreKit sharedInstance].receiptVerificator verifyReceiptUsingValidator:validator forceRefresh:forceRefresh completion:completion];
}

+ (void)fetchReceipt:(BOOL)forceRefresh completion:(void (^)(NSData * _Nullable, HYReceiptError * _Nullable))completion {
    [[HYStoreKit sharedInstance].receiptVerificator fetchReceipt:forceRefresh completion:completion];
}

+ (HYReceiptItem *)verifyPurchaseWithProductId:(NSString *)productId inReceipt:(NSDictionary<NSString *,id> *)receipt {
    return [HYInAppReceipt verifyPurchaseWithProductId:productId inReceipt:receipt];
}

+ (HYVerifySubscriptionResult *)verifySubscription:(HYSubscription *)subscription productId:(NSString *)productId inReceipt:(NSDictionary<NSString *,id> *)receipt validUntil:(NSDate *)date {
    return [HYInAppReceipt verifySubscriptions:subscription productIds:[NSSet setWithObject:productId] inReceipt:receipt validUntil:date ? date : [NSDate date]];
}

+ (HYVerifySubscriptionResult *)verifySubscriptions:(HYSubscription *)subscription productIds:(NSSet<NSString *> *)productIds inReceipt:(NSDictionary<NSString *,id> *)receipt validUntil:(NSDate *)date {
    if (!subscription) {
        subscription = [[HYSubscription alloc] initWithSubscriptionType:HYSubscriptionTypeAutoRenewable validDuration:0];
    }
    return [HYInAppReceipt verifySubscriptions:subscription productIds:productIds inReceipt:receipt validUntil:date ? date : [NSDate date]];
}

@end
