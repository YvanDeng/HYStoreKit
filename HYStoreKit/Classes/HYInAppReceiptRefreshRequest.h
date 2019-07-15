//
//  HYInAppReceiptRefreshRequest.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/26.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//
//  刷新小票请求

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HYInAppReceiptRefreshRequest : NSObject

+ (instancetype)refreshWithReceiptProperties:(NSDictionary<NSString *,id> * _Nullable)receiptProperties callback:(void(^)(NSError * _Nullable error))callback;

@end

NS_ASSUME_NONNULL_END
