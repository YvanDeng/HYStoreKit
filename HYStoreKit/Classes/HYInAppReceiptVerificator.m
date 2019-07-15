//
//  HYInAppReceiptVerificator.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYInAppReceiptVerificator.h"
#import "HYInAppReceiptRefreshRequest.h"
#import "HYStoreKit+Types.h"

@interface HYInAppReceiptVerificator ()

@property (nonatomic, strong) HYInAppReceiptRefreshRequest *receiptRefreshRequest;
@property (nonatomic, copy) NSURL *appStoreReceiptURL;
@property (nonatomic, strong) NSData *appStoreReceiptData;

@end

@implementation HYInAppReceiptVerificator

- (instancetype)init {
    self = [super init];
    if (self) {
        _appStoreReceiptURL = [NSBundle mainBundle].appStoreReceiptURL;
    }
    return self;
}

- (NSData *)appStoreReceiptData {
    if (self.appStoreReceiptURL) {
        return [NSData dataWithContentsOfURL:self.appStoreReceiptURL];
    }
    return nil;
}

#pragma mark - public methods

- (void)verifyReceiptUsingValidator:(id<HYReceiptValidator>)validator forceRefresh:(BOOL)forceRefresh completion:(nonnull void (^)(NSDictionary<NSString *,id> * _Nullable, HYReceiptError * _Nullable))completion {
    [self fetchReceipt:forceRefresh completion:^(NSData * _Nullable receiptData, HYReceiptError * _Nullable error) {
        if (error) {
            if (completion) completion(nil, error);
            return;
        }
        
        if (receiptData) {
            [self verifyReceiptData:receiptData usingValidator:validator completion:completion];
        }
    }];
}

- (void)fetchReceipt:(BOOL)forceRefresh completion:(void (^)(NSData * _Nullable, HYReceiptError * _Nullable))completion {
    if (self.appStoreReceiptData && !forceRefresh) {
        if (completion) {
            completion(self.appStoreReceiptData, nil);
        }
        return;
    }
    
    // 强制刷新小票
    __weak typeof(self) weakSelf = self;
    self.receiptRefreshRequest = [HYInAppReceiptRefreshRequest refreshWithReceiptProperties:nil callback:^(NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.receiptRefreshRequest = nil;
        
        if (error) {
            if (completion) {
                HYReceiptError *receiptError = [HYReceiptError receiptErrorWithErrorType:HYReceiptErrorTypeNetworkError error:error];
                completion(nil, receiptError);
            }
            return;
        }
        
        if (self.appStoreReceiptData) {
            if (completion) {
                completion(self.appStoreReceiptData, nil);
            }
        } else {
            if (completion) {
                HYReceiptError *receiptError = [HYReceiptError receiptErrorWithErrorType:HYReceiptErrorTypeNoReceiptData];
                completion(nil, receiptError);
            }
        }
    }];
}

#pragma mark - private method

/**
 @param receiptData 加密后的小票数据
 @param validator 验证器检查加密小票并以可读格式返回小票
 */
- (void)verifyReceiptData:(NSData *)receiptData usingValidator:(id<HYReceiptValidator>)validator completion:(void(^)(NSDictionary<NSString *,id> * _Nullable, HYReceiptError * _Nullable))completion {
    [validator validate:receiptData completion:^(NSDictionary<NSString *,id> * _Nullable receiptInfo, HYReceiptError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(receiptInfo, error);
            }
        });
    }];
}

@end
