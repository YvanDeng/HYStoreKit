//
//  HYInAppReceiptVerificator.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//
//  内购小票验证器

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HYReceiptValidator;
@class HYReceiptError;
@interface HYInAppReceiptVerificator : NSObject

@property (nonatomic, readonly) NSData *appStoreReceiptData;

/**
 验证App小票

 @param validator 验证器，检查加密后的小票并以可读格式返回小票
 @param forceRefresh 如果为YES，即使小票已存在，也会刷新小票
 @param completion 结果回调
 */
- (void)verifyReceiptUsingValidator:(id<HYReceiptValidator>)validator
                       forceRefresh:(BOOL)forceRefresh
                         completion:(void(^)(NSDictionary<NSString *,id> * _Nullable receiptInfo, HYReceiptError * _Nullable error))completion;

/**
 获取App小票，这个方法做了两件事:
 * 如果小票丢失，则刷新
 * 如果小票可用或者已刷新，则对其进行验证

 @param forceRefresh 如果为YES，即使小票已存在，也会刷新小票
 @param completion 结果回调
 */
- (void)fetchReceipt:(BOOL)forceRefresh completion:(void(^)(NSData * _Nullable receiptData, HYReceiptError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
