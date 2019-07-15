//
//  HYStoreKit.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYStoreKit+Types.h"

NS_ASSUME_NONNULL_BEGIN

@interface HYStoreKit : NSObject

#pragma mark - Purchases

/**
 * 如果此设备不支持或不允许付款，则返回NO
 */
+ (BOOL)canMakePayments;

/**
 检索商品信息
 
 @param productIds 商品Id集合
 @param completion 结果回调
 */
+ (void)retrieveProductsInfoWithProductIds:(NSSet<NSString *> *)productIds completion:(void(^_Nullable)(NSArray<SKProduct *> * _Nullable retrievedProducts, NSArray<NSString *> * _Nullable invalidProductIDs, NSError * _Nullable error))completion;

/**
 购买商品
 
 @param productId 商品Id
 @param quantity 数量
 @param atomically 商品是否以原子方式购买 (原子方式：立即调用finishTransaction)
 @param applicationUsername 可存储userId
 @param completion 结果回调
 */
+ (void)purchaseProductWithProductId:(NSString *)productId
                            quantity:(NSUInteger)quantity
                          atomically:(BOOL)atomically
                 applicationUsername:(NSString * _Nullable)applicationUsername
          simulatesAskToBuyInSandbox:(BOOL)simulatesAskToBuyInSandbox
                          completion:(void(^_Nullable)(HYPurchase * _Nullable purchase, NSError * _Nullable error))completion;

/**
 购买商品

 @param product 商品
 @param quantity 数量
 @param atomically 商品是否以原子方式购买 (原子方式：立即调用finishTransaction)
 @param applicationUsername 可存储userId
 @param completion 结果回调
 */
+ (void)purchaseProduct:(SKProduct *)product
               quantity:(NSUInteger)quantity
             atomically:(BOOL)atomically
    applicationUsername:(NSString * _Nullable)applicationUsername
simulatesAskToBuyInSandbox:(BOOL)simulatesAskToBuyInSandbox
             completion:(void(^_Nullable)(HYPurchase * _Nullable purchase, NSError * _Nullable error))completion;

/**
 恢复购买
 
 @param atomically 商品是否以原子方式购买 (原子方式：立即调用finishTransaction)
 @param applicationUsername 可存储userId
 @param completion 结果回调
 */
+ (void)restorePurchasesWithAtomically:(BOOL)atomically applicationUsername:(NSString * _Nullable)applicationUsername completion:(void(^_Nullable)(NSArray<HYPurchase *> * _Nullable restoredPurchases, NSArray<NSError *> * _Nullable errors))completion;

/**
 完成交易
 
 @param atomically 商品是否以原子方式购买 (例如：立即调用finishTransaction)
 @param completion 结果回调
 */
+ (void)completeTransactionsWithAtomically:(BOOL)atomically completion:(void(^_Nullable)(NSArray<HYPurchase *> *purchases))completion;

/**
 结束交易
 一旦商品被消耗或者商品的内容交付后，调用此方法以完成非原子化执行的交易
 
 @param transaction 需要结束的交易
 */
+ (void)finishTransaction:(SKPaymentTransaction *)transaction;

/**
 * 在iOS 11中注册SKPaymentQueue.shouldAddStorePayment委托方法的回调
 */
+ (void)setShouldAddStorePaymentHandler:(HYShouldAddStorePaymentHandler)shouldAddStorePaymentHandler;

/**
 * 注册paymentQueue(_:updatedDownloads:)回调
 */
+ (void)setUpdatedDownloadsHandler:(HYUpdatedDownloadsHandler)updatedDownloadsHandler;

+ (void)startDownloads:(NSArray<SKDownload *> *)downloads;
+ (void)pauseDownloads:(NSArray<SKDownload *> *)downloads;
+ (void)resumeDownloads:(NSArray<SKDownload *> *)downloads;
+ (void)cancelDownloads:(NSArray<SKDownload *> *)downloads;

#pragma mark - Receipt verification

/**
 * 从app bundle中返回小票数据。这是从mainBundle.appStoreReceiptURL中读取的
 */
+ (NSData * _Nullable)localReceiptData;

/**
 验证app小票(不会检查in_app字段是否存在)

 @param validator 使用的小票验证器
 @param forceRefresh 如果为true，即使小票已存在，也会刷新小票
 @param completion 结果回调
 */
+ (void)verifyReceiptUsingValidator:(id<HYReceiptValidator>)validator forceRefresh:(BOOL)forceRefresh completion:(void(^_Nullable)(NSDictionary<NSString *,id> * _Nullable receiptInfo, HYReceiptError * _Nullable error))completion;

/**
 获取App小票

 @param forceRefresh 如果为true，即使小票已存在，也会刷新小票
 @param completion 结果回调
 */
+ (void)fetchReceipt:(BOOL)forceRefresh completion:(void(^_Nullable)(NSData * _Nullable receiptData, HYReceiptError * _Nullable error))completion;

/**
 验证小票中的消费品或非消费品是否购买
 
 @param productId 商品id
 @param receipt 用于查询购买的小票
 @return 购买 或者 未购买
 */
+ (HYReceiptItem * _Nullable)verifyPurchaseWithProductId:(NSString *)productId inReceipt:(NSDictionary<NSString *,id> *)receipt;

/**
 验证小票中订阅的有效性（自动续订，免费或不续订）

 这个方法提取与给定productId匹配的所有交易，并按日期降序对其进行排序。然后，它将第一个交易过期日期与小票日期进行比较，以确定其有效性。
 @param subscription autoRenewable 或者 nonRenewing
 @param productId 需要验证的订阅商品ID
 @param receipt 用于查找订阅的小票
 @param date 根据订阅的到期日期进行检查的日期。仅当小票中没有日期时使用此选项
 @return 三种订阅状态
 */
+ (HYVerifySubscriptionResult *)verifySubscription:(HYSubscription *)subscription
                                         productId:(NSString *)productId
                                         inReceipt:(NSDictionary<NSString *,id> *)receipt
                                        validUntil:(NSDate * _Nullable)date;

/**
 验证小票中一组订阅的有效性。

 这个方法提取与给定productId匹配的所有交易，并按日期降序对其进行排序。然后，它将第一个交易过期日期与小票日期进行比较，以确定其有效性。
 @Note 您可以使用此方法检查订阅组中（互斥）订阅的有效性。
 @Remark type参数确定如何为所有订阅计算到期日期。确保所有productId都符合指定的订阅类型，以避免不正确的结果
 @param subscription autoRenewable 或者 nonRenewing
 @param productIds 需要验证的订阅商品ID
 @param receipt 用于查找订阅的小票
 @param date 根据订阅的到期日期进行检查的日期。仅当小票中没有日期时使用此选项
 @return 三种订阅状态
 */
+ (HYVerifySubscriptionResult *)verifySubscriptions:(HYSubscription * _Nullable)subscription
                                         productIds:(NSSet<NSString *> *)productIds
                                          inReceipt:(NSDictionary<NSString *,id> *)receipt
                                         validUntil:(NSDate * _Nullable)date;

@end

NS_ASSUME_NONNULL_END
