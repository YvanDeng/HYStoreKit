//
//  HYStoreKit+Types.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

extern NSErrorUserInfoKey const HYInvalidProductIdentifierKey;

typedef NS_ENUM(NSInteger, HYSubscriptionStatus) {
    HYSubscriptionStatusPurchased,
    HYSubscriptionStatusExpired,
    HYSubscriptionStatusNotPurchased
};

typedef NS_ENUM(NSInteger, HYSubscriptionType) {
    HYSubscriptionTypeAutoRenewable,
    HYSubscriptionTypeNonRenewing
};

typedef NS_ENUM(NSInteger, HYReceiptErrorType) {
    HYReceiptErrorTypeNoReceiptData,    // 没有小票数据
    HYReceiptErrorTypeNoRemoteData,     // 没有接收到小票数据
    HYReceiptErrorTypeRequestBodyEncodeError, // 当编码HTTP body转换成JSON时发生错误
    HYReceiptErrorTypeNetworkError,     // 进行验证小票请求时发生错误
    HYReceiptErrorTypeJsonDecodeError,  // 解码http响应时发生错误
    HYReceiptErrorTypeReceiptInvalid    // 小票无效 - 返回小票具体错误状态
};

// 苹果服务器返回的状态码
typedef NS_ENUM(NSInteger, HYReceiptStatus) {
    // 不可解码的状态
    HYReceiptStatusUnknown = -2,
    // 没有状态码返回
    HYReceiptStatusNone = -1,
    // 有效状态码
    HYReceiptStatusValid = 0,
    // App Store无法读取传给它的JSON对象
    HYReceiptStatusJsonNotReadable = 21000,
    // receipt-data属性中的数据格式错误或缺失
    HYReceiptStatusMalformedOrMissingData = 21002,
    // 小票无法通过身份验证
    HYReceiptStatusReceiptCouldNotBeAuthenticated = 21003,
    // 提供的共享密码与您帐户的共享密钥不符
    HYReceiptStatusSecretNotMatching = 21004,
    // 小票服务器当前不可用
    HYReceiptStatusReceiptServerUnavailable = 21005,
    // 小票有效但订阅已过期。当这个状态码返回到你的服务器时，小票数据也会被解码并作为响应的一部分返回
    HYReceiptStatusSubscriptionExpired = 21006,
    // 小票来自测试环境，但已发送到生产环境进行验证
    HYReceiptStatusTestReceipt = 21007,
    // 小票来自生产环境，但已发送到测试环境进行验证。
    HYReceiptStatusProductionEnvironment = 21008
};

#pragma mark - Purchases

@interface HYPurchase : NSObject

@property (nonatomic, copy, readonly) NSString *productId;
/** 恢复购买时为nil */
@property (nonatomic, strong, readonly, nullable) SKProduct *product;
@property (nonatomic, readonly) NSUInteger quantity;
@property (nonatomic, strong, readonly) SKPaymentTransaction *transaction;
@property (nonatomic, readonly) BOOL needsFinishTransaction;

- (instancetype)initWithProductId:(NSString *)product
                          product:(SKProduct * _Nullable)product
                         quantity:(NSUInteger)quantity
                      transaction:(SKPaymentTransaction *)transaction
           needsFinishTransaction:(BOOL)needsFinishTransaction;

@end

@class HYReceiptError;
@protocol HYReceiptValidator <NSObject>

- (void)validate:(NSData *)receiptData completion:(void(^)(NSDictionary<NSString *,id> * _Nullable, HYReceiptError * _Nullable))completion;

@end

typedef BOOL(^HYShouldAddStorePaymentHandler)(SKPayment *, SKProduct *);
typedef void(^HYUpdatedDownloadsHandler)(NSArray<SKDownload *> *);

#pragma mark - Receipt verification

@class HYReceiptItem;
@interface HYVerifySubscriptionResult : NSObject

@property (nonatomic, readonly) HYSubscriptionStatus status;
@property (nonatomic, copy, readonly, nullable) NSArray<HYReceiptItem *> *items;

- (instancetype)initWithSubscriptionStatus:(HYSubscriptionStatus)status items:(NSArray<HYReceiptItem *> * _Nullable)items;

@end

@interface HYSubscription : NSObject

@property (nonatomic, readonly) HYSubscriptionType subscriptionType;
@property (nonatomic, readonly) NSTimeInterval validDuration;

- (instancetype)initWithSubscriptionType:(HYSubscriptionType)subscriptionType validDuration:(NSTimeInterval)validDuration;

@end

@interface HYReceiptItem : NSObject

// 购买的商品Id
@property (nonatomic, copy, readonly) NSString *productId;
// 购买的商品数量
@property (nonatomic, readonly) NSUInteger quantity;
// 已购买商品的交易Id
@property (nonatomic, copy, readonly) NSString *transactionId;
// 如果是恢复之前的交易，表示原始交易的交易Id；否则, 与transactionId相同
@property (nonatomic, copy, readonly) NSString *originalTransactionId;
// 购买商品的日期和时间
@property (nonatomic, strong, readonly) NSDate *purchaseDate;
// 如果是恢复之前的交易，表示原始交易的日期。在自动续订订阅的小票中，这表示订阅期的开始，即使订阅已续订
@property (nonatomic, strong, readonly) NSDate *originalPurchaseDate;
// 用于识别订阅购买的主键
@property (nonatomic, copy, readonly, nullable) NSString *webOrderLineItemId;
// 订阅的到期日期，表示为 自1970年1月1日00:00:00 GMT以来 的毫秒数。仅适用于自动续订订阅的小票.
@property (nonatomic, strong, readonly, nullable) NSDate *subscriptionExpirationDate;
// 对于Apple客户支持取消的交易，取消的时间和日期。对已取消的小票进行处理，就像没有进行任何购买一样。
@property (nonatomic, strong, readonly, nullable) NSDate *cancellationDate;
// 是否免费体验期
@property (nonatomic, readonly) BOOL isTrialPeriod;
// 是否推介优惠期
@property (nonatomic, readonly) BOOL isInIntroOfferPeriod;

- (nullable instancetype)initWithReceiptInfo:(NSDictionary<NSString *,id> *)receiptInfo;

@end

// Error when managing receipt
@interface HYReceiptError : NSObject

@property (nonatomic, readonly) HYReceiptErrorType receiptErrorType;
@property (nonatomic, strong, readonly, nullable) NSError *error;
@property (nonatomic, copy, readonly, nullable) NSString *decodeJson;
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *,id> *receipt;
@property (nonatomic, readonly) HYReceiptStatus status;

+ (instancetype)receiptErrorWithErrorType:(HYReceiptErrorType)errorType;
+ (instancetype)receiptErrorWithErrorType:(HYReceiptErrorType)errorType error:(NSError *)error;
+ (instancetype)receiptErrorWithErrorType:(HYReceiptErrorType)errorType decodeJson:(NSString *)decodeJson;
+ (instancetype)receiptErrorWithErrorType:(HYReceiptErrorType)errorType receipt:(NSDictionary<NSString *,id> *)receipt status:(HYReceiptStatus)status;

@end

// 小票字段定义如下 : https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ReceiptFields.html#//apple_ref/doc/uid/TP40010573-CH106-SW1
@class HYInApp;
@interface HYReceiptInfoField : NSObject

// Bundle标识，即 Info.plist 文件中的 CFBundleIdentifier 字段
@property (nonatomic, copy) NSString *bundle_id;
// 应用程序的版本号，即 Info.plist 文件中的 CFBundleVersion 字段
@property (nonatomic, copy) NSString *application_version;
// 最初购买的应用程序版本, 即 Info.plist 文件中的 CFBundleVersion 字段
@property (nonatomic, copy) NSString *original_application_version;
// 创建小票的日期
@property (nonatomic, copy) NSString *creation_date;
// 小票到期的日期。仅适用于通过 Volume Purchase Program 购买的应用程序。
@property (nonatomic, copy) NSString *expiration_date;
// in_app小票
@property (nonatomic, copy) HYInApp *in_app;

@end

@interface HYInApp : NSObject

// 购买的商品数量
@property (nonatomic, copy) NSString *quantity;
// 已购买商品的productId
@property (nonatomic, copy) NSString *product_id;
// 已购买商品的transationId
@property (nonatomic, copy) NSString *transaction_id;
// 对于恢复购买的交易，表示原始交易的transationId。否则，与transationId相同。自动续订订阅的续订链中的所有小票对此字段具有相同的值。
@property (nonatomic, copy) NSString *original_transaction_id;
// 购买商品的日期和时间
@property (nonatomic, copy) NSString *purchase_date;
// 对于恢复购买的交易，表示原始交易的transactionDate。在自动续订的订阅小票中，这表示订阅期的开始，即使订阅已续订。
@property (nonatomic, copy) NSString *original_purchase_date;
// 订阅的到期日期，表示为自1970年1月1日00:00:00 GMT以来的毫秒数。仅适用于自动续订订阅的小票。
@property (nonatomic, copy) NSString *expires_date;
// 对于Apple客户支持取消的交易，表示取消交易的时间和日期。注意：对已取消的收据进行处理，就像没有进行任何购买一样。
@property (nonatomic, copy) NSString *cancellation_date;
// App Store用于唯一标识创建交易的应用程序的字符串。如果您的服务器支持多个应用程序，则可以使用此值来区分它们。仅在生产环境中为应用程序分配标识符，因此对于在测试环境中创建的小票，此密钥不存在。
@property (nonatomic, copy) NSString *app_item_id;
// 唯一标识应用程序修订的任意数字。对于在测试环境中创建的小票，此密钥不存在。
@property (nonatomic, copy) NSString *version_external_identifier;
// 用于识别订阅购买的主键。
@property (nonatomic, copy) NSString *web_order_line_item_id;

@end

NS_ASSUME_NONNULL_END
