//
//  HYInAppReceiptRefreshRequest.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/26.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYInAppReceiptRefreshRequest.h"
#import <StoreKit/StoreKit.h>

@interface HYInAppReceiptRefreshRequest ()<SKRequestDelegate>

@property (nonatomic, strong) SKReceiptRefreshRequest *refreshReceiptRequest;
@property (nonatomic, copy) void(^callback)(NSError *);

@end

@implementation HYInAppReceiptRefreshRequest

- (instancetype)initWithReceiptProperties:(NSDictionary<NSString *,id> *)receiptProperties callback:(void (^)(NSError * _Nullable))callback {
    self = [super init];
    if (self) {
        _callback = [callback copy];
        _refreshReceiptRequest = [[SKReceiptRefreshRequest alloc] initWithReceiptProperties:receiptProperties];
        _refreshReceiptRequest.delegate = self;
    }
    return self;
}

- (void)dealloc {
    _refreshReceiptRequest.delegate = nil;
}

- (void)start {
    [self.refreshReceiptRequest start];
}

+ (instancetype)refreshWithReceiptProperties:(NSDictionary<NSString *,id> *)receiptProperties callback:(void (^)(NSError * _Nullable))callback {
    HYInAppReceiptRefreshRequest *request = [[HYInAppReceiptRefreshRequest alloc] initWithReceiptProperties:receiptProperties callback:callback];
    [request start];
    
    return request;
}
    
#pragma mark - SKRequestDelegate

- (void)requestDidFinish:(SKRequest *)request {
    /*if let resoreRequest = request as? SKReceiptRefreshRequest {
     let receiptProperties = resoreRequest.receiptProperties ?? [:]
     for (k, v) in receiptProperties {
     print("\(k): \(v)")
     }
     }*/
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.callback) {
            strongSelf.callback(nil);
        }
    });
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    // XXX could here check domain and error code to return typed exception
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.callback) {
            strongSelf.callback(error);
        }
    });
}

@end
