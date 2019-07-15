//
//  HYInAppReceipt.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/5/5.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//
//  小票

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (HYStoreKit)

- (nullable instancetype)initWithMillisecondsSince1970:(NSString *)millisecondsSince1970;

@end

@class HYReceiptItem;
@class HYSubscription;
@class HYVerifySubscriptionResult;
@interface HYInAppReceipt : NSObject

/**
 验证小票中的消费品或非消费品是否购买
 
 @param productId 商品id
 @param receipt 用于查询购买的小票
 @return 购买 或者 未购买
 */
+ (HYReceiptItem * _Nullable)verifyPurchaseWithProductId:(NSString *)productId inReceipt:(NSDictionary<NSString *,id> *)receipt;

/**
 验证小票中的一组订阅的有效性。
 
 这个方法提取与给定productId匹配的所有交易，并按日期降序对其进行排序。然后，它将第一个交易过期日期与小票日期进行比较，以确定其有效性。
 @Note 您可以使用此方法检查订阅组中（互斥）订阅的有效性。
 @Remark type参数确定如何为所有订阅计算到期日期。确保所有productId都符合指定的订阅类型，以避免不正确的结果
 @param subscription autoRenewable 或者 nonRenewing
 @param productIds 需要验证的订阅商品ID
 @param receipt 用于查找订阅的小票
 @param date 根据订阅的到期日期进行检查的日期。仅当小票中没有日期时使用此选项
 @return 三种订阅状态
 */
+ (HYVerifySubscriptionResult *)verifySubscriptions:(HYSubscription *)subscription
                                         productIds:(NSSet<NSString *> *)productIds
                                          inReceipt:(NSDictionary<NSString *,id> *)receipt
                                         validUntil:(NSDate *)date;

@end

NS_ASSUME_NONNULL_END
