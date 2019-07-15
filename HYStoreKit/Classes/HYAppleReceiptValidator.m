//
//  HYAppleReceiptValidator.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/4/23.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "HYAppleReceiptValidator.h"
#import "HYStoreKit+Types.h"

NSString * const productionServerAddress = @"https://buy.itunes.apple.com/verifyReceipt";
NSString * const sanboxServerAddress = @"https://sandbox.itunes.apple.com/verifyReceipt";

@interface HYAppleReceiptValidator ()<HYReceiptValidator>

@end

@implementation HYAppleReceiptValidator

- (instancetype)init {
    self = [super init];
    if (self) {
        _serverAddress = productionServerAddress;
    }
    return self;
}

- (void)validate:(NSData *)receiptData completion:(void(^)(NSDictionary<NSString *,id> * _Nullable, HYReceiptError * _Nullable))completion {
    NSURL *storeURL = [NSURL URLWithString:self.serverAddress];
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    storeRequest.HTTPMethod = @"POST";
    storeRequest.timeoutInterval = 10.0;
    
    NSString *receipt = [receiptData base64EncodedStringWithOptions:0];
    NSMutableDictionary *requestContents = @{@"receipt-data": receipt}.mutableCopy;
    // password if defined
    if (self.sharedSecret) {
        [requestContents setValue:self.sharedSecret forKey:@"password"];
    }
    
    // 加密 request body
    NSError *error;
    storeRequest.HTTPBody = [NSJSONSerialization dataWithJSONObject:requestContents.copy options:0 error:&error];
    if (error) {
        if (completion) {
            HYReceiptError *receiptError = [HYReceiptError receiptErrorWithErrorType:HYReceiptErrorTypeRequestBodyEncodeError error:error];
            completion(nil, receiptError);
        }
        return;
    }
    
    // Remote task
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:storeRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        // there is an error
        if (error) {
            if (completion) {
                HYReceiptError *receiptError = [HYReceiptError receiptErrorWithErrorType:HYReceiptErrorTypeNetworkError error:error];
                completion(nil, receiptError);
            }
            return;
        }
        
        // there is no data
        if (!data) {
            if (completion) {
                HYReceiptError *receiptError = [HYReceiptError receiptErrorWithErrorType:HYReceiptErrorTypeNoRemoteData];
                completion(nil, receiptError);
            }
            return;
        }
        
        // cannot decode data
        NSError *decodeError;
        NSDictionary *receiptInfo = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&decodeError];
        if (decodeError) {
            if (completion) {
                NSString *jsonStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                HYReceiptError *receiptError = [HYReceiptError receiptErrorWithErrorType:HYReceiptErrorTypeJsonDecodeError decodeJson:jsonStr];
                completion(nil, receiptError);
            }
            return;
        }
        
        // get status from info
        if ([receiptInfo.allKeys containsObject:@"status"]) {
            NSInteger status = [receiptInfo[@"status"] integerValue];
            /*
             * http://stackoverflow.com/questions/16187231/how-do-i-know-if-an-in-app-purchase-receipt-comes-from-the-sandbox
             * How do I verify my receipt (iOS)?
             * Always verify your receipt first with the production URL; proceed to verify
             * with the sandbox URL if you receive a 21007 status code. Following this
             * approach ensures that you do not have to switch between URLs while your
             * application is being tested or reviewed in the sandbox or is live in the
             * App Store.
             
             * Note: The 21007 status code indicates that this receipt is a sandbox receipt,
             * but it was sent to the production service for verification.
             */
            if (status == HYReceiptStatusTestReceipt) {
                // 重新发送到sandbox环境验证
                HYAppleReceiptValidator *sandboxValidator = [HYAppleReceiptValidator new];
                sandboxValidator.serverAddress = sanboxServerAddress;
                sandboxValidator.sharedSecret = self.sharedSecret;
                [sandboxValidator validate:receiptData completion:completion];
            } else if (status == HYReceiptStatusValid) {
                if (completion) {
                    completion(receiptInfo, nil);
                }
            } else {
                if (completion) {
                    HYReceiptError *receiptError = [HYReceiptError receiptErrorWithErrorType:HYReceiptErrorTypeReceiptInvalid receipt:receiptInfo status:status];
                    completion(nil, receiptError);
                }
            }
        } else {
            if (completion) {
                HYReceiptError *receiptError = [HYReceiptError receiptErrorWithErrorType:HYReceiptErrorTypeReceiptInvalid receipt:receiptInfo status:HYReceiptStatusNone];
                completion(nil, receiptError);
            }
        }
    }];
    [task resume];
}

@end
