//
//  SKProduct+LocalizedPrice.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/6/14.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SKProduct (LocalizedPrice)

- (NSString * _Nullable)localizedPrice;

@end

NS_ASSUME_NONNULL_END
