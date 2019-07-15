//
//  SKProduct+LocalizedPrice.m
//  HYStoreKit
//
//  Created by 邓逸远 on 2019/6/14.
//  Copyright © 2019 772930792@qq.com. All rights reserved.
//

#import "SKProduct+LocalizedPrice.h"

@implementation SKProduct (LocalizedPrice)

- (NSString *)localizedPrice {
    return [[self priceFormatter:self.priceLocale] stringFromNumber:self.price];
}

- (NSNumberFormatter *)priceFormatter:(NSLocale *)locale {
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.locale = locale;
    formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    return formatter;
}

@end
