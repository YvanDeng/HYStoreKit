//
//  HYProductsInfoController.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYProductsInfoController.h"
#import "HYInAppProductQueryRequest.h"

#import <StoreKit/StoreKit.h>

@interface HYInAppProductQuery : NSObject

@property (nonatomic, strong) HYInAppProductQueryRequest *request;
@property (nonatomic, strong) NSMutableArray *completionHandlers;

- (instancetype)initWithRequest:(HYInAppProductQueryRequest *)request completionHandlers:(NSMutableArray *)completion;

@end

@implementation HYInAppProductQuery

- (instancetype)initWithRequest:(HYInAppProductQueryRequest *)request completionHandlers:(NSMutableArray *)completion {
    self = [super init];
    if (self) {
        _request = request;
        if ([completion isKindOfClass:[NSArray class]]) {
            _completionHandlers = completion.mutableCopy;
        } else if ([completion isKindOfClass:[NSMutableArray class]]) {
            _completionHandlers = completion;
        } else {
            _completionHandlers = @[].mutableCopy;
        }
    }
    return self;
}

@end

@interface HYProductsInfoController ()

// 由于我们可以有多个进行中的请求，我们会按product id将它们存储在字典中
@property (nonatomic, strong) NSMutableDictionary<NSSet *,HYInAppProductQuery *> *inflightRequests;

@end

@implementation HYProductsInfoController

- (instancetype)init {
    self = [super init];
    if (self) {
        _inflightRequests = @{}.mutableCopy;
    }
    return self;
}

- (void)retrieveProductsInfoWithProductIds:(NSSet<NSString *> *)productIds completion:(void (^)(NSArray<SKProduct *> * _Nonnull, NSArray<NSString *> * _Nonnull, NSError * _Nullable))completion {
    
    HYInAppProductQuery *query = _inflightRequests[productIds];
    if (!query) {
        __weak typeof(self) weakSelf = self;
        HYInAppProductQueryRequest *request = [[HYInAppProductQueryRequest alloc] initWithProductIds:productIds callback:^(NSArray<SKProduct *> * _Nonnull retrievedProducts, NSArray<NSString *> * _Nonnull invalidProductIDs, NSError * _Nullable error) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            HYInAppProductQuery *query = strongSelf.inflightRequests[productIds];
            if (query) {
                for (void(^completion)(NSArray<SKProduct *> * _Nonnull, NSArray<NSString *> * _Nonnull, NSError * _Nullable) in query.completionHandlers) {
                    completion(retrievedProducts, invalidProductIDs, error);
                }
                strongSelf.inflightRequests[productIds] = nil;
            } else {
                // should not get here, but if it does it seems reasonable to call the outer completion block
                if (completion) completion(retrievedProducts, invalidProductIDs, error);
            }
        }];
        _inflightRequests[productIds] = [[HYInAppProductQuery alloc] initWithRequest:request completionHandlers:@[completion].mutableCopy];
        [request start];
    } else {
        [query.completionHandlers addObject:completion];
    }
}

@end
