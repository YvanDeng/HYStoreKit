//
//  HYInAppReceipt.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/5/5.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYInAppReceipt.h"
#import "HYStoreKit+Types.h"

@implementation NSDate (HYStoreKit)

- (instancetype)initWithMillisecondsSince1970:(NSString *)millisecondsSince1970 {
    if ([millisecondsSince1970 isEqualToString:@"0"]) {
        return [NSDate dateWithTimeIntervalSince1970: 0];
    }
    
    double millisecondsNumber = [millisecondsSince1970 doubleValue];
    if (millisecondsNumber == 0.0) return nil;
    
    self = [self init];
    return [NSDate dateWithTimeIntervalSince1970: millisecondsNumber / 1000];
}

@end

#pragma mark - receipt mangement

@implementation HYInAppReceipt

+ (HYReceiptItem * _Nullable)verifyPurchaseWithProductId:(NSString *)productId inReceipt:(nonnull NSDictionary<NSString *,id> *)receipt {
    // 获取商品的小票信息
    NSArray *receipts = [self getInAppReceiptsWithReceipt:receipt];
    NSArray *filteredReceiptsInfo = [self filterReceiptsInfo:receipts withProductIds:[NSSet setWithObject:productId]];
    NSMutableArray<HYReceiptItem *> *receiptItems = @[].mutableCopy;
    [filteredReceiptsInfo enumerateObjectsUsingBlock:^(NSDictionary *  _Nonnull receipt, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!receipt[@"cancellation_date"]) {
            HYReceiptItem *item = [[HYReceiptItem alloc] initWithReceiptInfo:receipt];
            if (item) [receiptItems addObject:item];
        }
    }];
    
    // 确认至少有一张小票包含正确的productId
    if (receiptItems.count > 0) {
        return receiptItems.firstObject;
    }
    return nil;
}

+ (HYVerifySubscriptionResult *)verifySubscriptions:(HYSubscription *)subscription productIds:(NSSet<NSString *> *)productIds inReceipt:(NSDictionary<NSString *,id> *)receipt validUntil:(NSDate *)date {
    // 检查自动续订订阅当前是否处于活跃状态时，latest_receipt和latest_receipt_info的值很有用。通过提供订阅的任何交易小票并检查这些值，可以获得有关当前活跃订阅期的信息。如果验证的小票是最新续订的，则latest_receipt的值与receipt-data（在请求中）相同，而latest_receipt_info的值与receipt相同。
    NSArray<NSDictionary *> *receipts;
    NSTimeInterval duration = -1;
    switch (subscription.subscriptionType) {
        case HYSubscriptionTypeAutoRenewable:
            receipts = receipt[@"latest_receipt_info"];
            break;
        case HYSubscriptionTypeNonRenewing: {
            receipts = [self getInAppReceiptsWithReceipt:receipt];
            duration = subscription.validDuration;
        }
            break;
    }
    NSArray<NSDictionary *> *receiptsInfo = [self filterReceiptsInfo:receipts withProductIds:productIds];
    NSMutableArray<HYReceiptItem *> *receiptItems = @[].mutableCopy;
    __block NSUInteger nonCancelledReceiptsInfoCount = 0;
    [receiptsInfo enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj[@"cancellation_date"]) {
            HYReceiptItem *item = [[HYReceiptItem alloc] initWithReceiptInfo:obj];
            if (item) [receiptItems addObject:item];
            nonCancelledReceiptsInfoCount += 1;
        }
    }];
    if (nonCancelledReceiptsInfoCount == 0) {
        HYVerifySubscriptionResult *result = [[HYVerifySubscriptionResult alloc] initWithSubscriptionStatus:HYSubscriptionStatusNotPurchased items:nil];
        return result;
    }
    
    NSDate *receiptDate = [self getReceiptRequestDateInReceipt:receipt];
    if (!receiptDate) {
        receiptDate = date;
    }
    
    if (nonCancelledReceiptsInfoCount > receiptItems.count) {
        NSLog(@"receipt has %@ items, but only %@ were parsed", @(nonCancelledReceiptsInfoCount), @(receiptItems.count));
    }
    
    NSMutableArray *expiryDatesAndItems = @[].mutableCopy;
    if (duration > -1) {
        [receiptItems enumerateObjectsUsingBlock:^(HYReceiptItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSDate *expirationDate = [[NSDate alloc] initWithTimeIntervalSince1970:obj.originalPurchaseDate.timeIntervalSince1970 + duration];
            NSDictionary *dic = @{@"expirationDate": expirationDate, @"item": obj};
            [expiryDatesAndItems addObject:dic];
        }];
    } else {
        [receiptItems enumerateObjectsUsingBlock:^(HYReceiptItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.subscriptionExpirationDate) {
                NSDictionary *dic = @{@"expirationDate": obj.subscriptionExpirationDate, @"item": obj};
                [expiryDatesAndItems addObject:dic];
            }
        }];
    }
    
    if (expiryDatesAndItems.count == 0) {
        HYVerifySubscriptionResult *result = [[HYVerifySubscriptionResult alloc] initWithSubscriptionStatus:HYSubscriptionStatusNotPurchased items:nil];
        return result;
    }
    
    NSArray *sortedExpiryDatesAndItems = [expiryDatesAndItems sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *  _Nonnull obj1, NSDictionary *  _Nonnull obj2) {
        return [obj1[@"expirationDate"] compare:obj2[@"expirationDate"]];
    }];
    
    NSMutableArray *sortedReceiptItems = @[].mutableCopy;
    [sortedExpiryDatesAndItems enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [sortedReceiptItems addObject:obj[@"item"]];
    }];
    
    NSDate *firstExpiryDate = sortedExpiryDatesAndItems.firstObject[@"expirationDate"];
    switch ([firstExpiryDate compare:receiptDate]) {
        case NSOrderedDescending: {
            HYVerifySubscriptionResult *result = [[HYVerifySubscriptionResult alloc] initWithSubscriptionStatus:HYSubscriptionStatusPurchased items:sortedReceiptItems.copy];
            return result;
        }
        default:{
            HYVerifySubscriptionResult *result = [[HYVerifySubscriptionResult alloc] initWithSubscriptionStatus:HYSubscriptionStatusExpired items:sortedReceiptItems.copy];
            return result;
        }
    }
}

#pragma mark - private methods

+ (NSArray<NSDictionary<NSString *,id> *> * _Nullable)getInAppReceiptsWithReceipt:(NSDictionary<NSString *,id> *)receipt {
    if (!receipt) return nil;
    NSDictionary *appReceipt = receipt[@"receipt"];
    NSArray *inAppReceipts = appReceipt[@"in_app"];
    return inAppReceipts;
}

/**
 获取所有指定商品的小票信息

 @param receipts 获取到的小票数组信息
 @param productIds 商品Id集合
 */
+ (NSArray<NSDictionary<NSString *,id> *> *)filterReceiptsInfo:(NSArray<NSDictionary<NSString *,id> *> * _Nullable)receipts withProductIds:(NSSet<NSString *> *)productIds {
    if (!receipts) return @[];
    
    // Filter receipts with matching product ids
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        if (evaluatedObject && [evaluatedObject isKindOfClass:[NSDictionary class]]) {
            NSDictionary *receipt = (NSDictionary *)evaluatedObject;
            return [productIds containsObject:receipt[@"product_id"]];
        }
        return NO;
    }];
    NSArray *receiptsMatchingProductIds = [receipts filteredArrayUsingPredicate:predicate];
    
    return receiptsMatchingProductIds;
}

+ (NSDate *)getReceiptRequestDateInReceipt:(NSDictionary *)receipt {
    NSDictionary *receiptInfo = receipt[@"receipt"];
    if (!receiptInfo) {
        return nil;
    }
    NSString *requestDateString = receiptInfo[@"request_date_ms"];
    if (!requestDateString) {
        return nil;
    }
    return [[NSDate alloc] initWithMillisecondsSince1970:requestDateString];
}

@end
