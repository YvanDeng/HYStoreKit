//
//  HYInAppProductQueryRequest.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYInAppProductQueryRequest.h"
#import <StoreKit/StoreKit.h>

@interface HYInAppProductQueryRequest ()<SKProductsRequestDelegate>

@property (nonatomic, copy) void(^callback)(NSArray<SKProduct *> *, NSArray<NSString *> *, NSError * _Nullable);
@property (nonatomic, strong) SKProductsRequest *request;

@end

@implementation HYInAppProductQueryRequest

- (instancetype)initWithProductIds:(NSSet<NSString *> *)productIds callback:(nonnull void (^)(NSArray<SKProduct *> * _Nonnull, NSArray<NSString *> * _Nonnull, NSError * _Nullable))callback {
    self = [super init];
    if (self) {
        _callback = callback;
        _request = [[SKProductsRequest alloc] initWithProductIdentifiers:productIds];
        _request.delegate = self;
    }
    return self;
}

- (void)dealloc {
    self.request.delegate = nil;
}

- (void)start {
    [self.request start];
}

- (void)cancel {
    [self.request cancel];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    NSArray<SKProduct *> *retrievedProducts = response.products;
    NSArray<NSString *> *invalidProductIDs = response.invalidProductIdentifiers;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.callback) {
            strongSelf.callback(retrievedProducts, invalidProductIDs, nil);
        }
    });
}

- (void)requestDidFinish:(SKRequest *)request {
    
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.callback) {
            strongSelf.callback(@[], @[], error);
        }
    });
}

@end
