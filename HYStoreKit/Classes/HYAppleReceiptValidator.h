//
//  HYAppleReceiptValidator.h
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//
//  去苹果小票服务器验证小票

#import <Foundation/Foundation.h>

// https://developer.apple.com/library/ios/releasenotes/General/ValidateAppStoreReceipt/Chapters/ValidateRemotely.html

NS_ASSUME_NONNULL_BEGIN

extern NSString * const productionServerAddress;
extern NSString * const sanboxServerAddress;

@class HYReceiptError;
@interface HYAppleReceiptValidator : NSObject

@property (nonatomic, copy) NSString *serverAddress;
@property (nonatomic, copy, nullable) NSString *sharedSecret;

@end

NS_ASSUME_NONNULL_END
