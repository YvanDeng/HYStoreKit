//
//  HYViewController.m
//  HYStoreKit
//
//  Created by 邓逸远 on 06/18/2019.
//  Copyright (c) 2019 邓逸远. All rights reserved.
//

#import "HYViewController.h"
#import <HYStoreKit/HYStoreKit.h>
#import <HYStoreKit/HYAppleReceiptValidator.h>
#import "HYNetworkActivityIndicatorManager.h"

static NSString * const appBundleId = @"org.cocoapods.demo.HYStoreKit-Example";

static NSString * const purchase1 = @"purchase1";
static NSString * const purchase2 = @"purchase2";
static NSString * const nonConsumablePurchase = @"nonConsumablePurchase";
static NSString * const consumablePurchase = @"consumablePurchase";
static NSString * const nonRenewingPurchase = @"nonRenewingPurchase";
static NSString * const autoRenewableWeekly = @"autoRenewableWeekly";
static NSString * const autoRenewableMonthly = @"autoRenewableMonthly";
static NSString * const autoRenewableYearly = @"autoRenewableYearly";

@interface HYViewController ()

@property (nonatomic, weak) IBOutlet UISwitch *nonConsumableAtomicSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *consumableAtomicSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *nonRenewingAtomicSwitch;
@property (nonatomic, weak) IBOutlet UISwitch *autoRenewableAtomicSwitch;

@property (nonatomic, weak) IBOutlet UISegmentedControl *autoRenewableSubscriptionSegmentedControl;

@end

@implementation HYViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

#pragma mark - User facing alerts

- (UIAlertController *)alertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:action];
    return alert;
}

- (void)showAlert:(UIAlertController *)alert {
    if (!self.presentedViewController) {
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (UIAlertController *)alertForProductWithRetrievedProducts:(NSArray<SKProduct *> *)retrievedProducts invalidProductIDs:(NSArray<NSString *> *)invalidProductIDs error:(NSError *)error {
    if (retrievedProducts.firstObject) {
        SKProduct *product = retrievedProducts.firstObject;
        return [self alertWithTitle:product.localizedTitle message:[NSString stringWithFormat:@"%@ - %@", product.localizedDescription, product.price]];
    } else if (invalidProductIDs.firstObject) {
        NSString *invalidProductId = invalidProductIDs.firstObject;
        return [self alertWithTitle:@"Could not retrieve product info" message:[NSString stringWithFormat:@"Invalid product identifier: %@", invalidProductId]];
    } else {
        NSString *errorString = error.localizedDescription;
        if (errorString.length == 0) {
            errorString = @"Unknown error. Please contact support";
        }
        return [self alertWithTitle:@"Could not retrieve product info" message:errorString];
    }
}

- (UIAlertController *)alertForPurchase:(HYPurchase *)purchase error:(NSError *)error {
    if (purchase) {
        NSLog(@"Purchase Success: %@", purchase.productId);
        return nil;
    }
    if (error) {
        NSLog(@"Purchase Failed: %@", error);
        switch (error.code) {
            case SKErrorUnknown:
                return [self alertWithTitle:@"Purchase failed" message:error.localizedDescription];
            case SKErrorClientInvalid: // client is not allowed to issue the request, etc.
                return [self alertWithTitle:@"Purchase failed" message:@"Not allowed to make the payment"];
            case SKErrorPaymentCancelled: // user cancelled the request, etc.
                return nil;
            case SKErrorPaymentInvalid: // purchase identifier was invalid, etc.
                return [self alertWithTitle:@"Purchase failed" message:@"The purchase identifier was invalid"];
            case SKErrorPaymentNotAllowed: // this device is not allowed to make the payment
                return [self alertWithTitle:@"Purchase failed" message:@"The device is not allowed to make the payment"];
            case SKErrorStoreProductNotAvailable: // Product is not available in the current storefront
                return [self alertWithTitle:@"Purchase failed" message:@"The product is not available in the current storefront"];
            case SKErrorCloudServicePermissionDenied: // user has not allowed access to cloud service information
                return [self alertWithTitle:@"Purchase failed" message:@"Access to cloud service information is not allowed"];
            case SKErrorCloudServiceNetworkConnectionFailed: // the device could not connect to the nework
                return [self alertWithTitle:@"Purchase failed" message:@"Could not connect to the network"];
            case SKErrorCloudServiceRevoked: // user has revoked permission to use this cloud service
                return [self alertWithTitle:@"Purchase failed" message:@"Cloud service was revoked"];
            default:
                return [self alertWithTitle:@"Purchase failed" message:error.localizedDescription];
        }
    }
    return nil;
}

- (UIAlertController *)alertForRestorePurchases:(NSArray<HYPurchase *> *)restoredPurchases restoreFailedPurchases:(NSArray<HYPurchase *> *)restoreFailedPurchases {
    if (restoreFailedPurchases.count > 0) {
        NSLog(@"Restore Failed: %@", restoreFailedPurchases);
        return [self alertWithTitle:@"Restore failed" message:@"Unknown error. Please contact support"];
    } else if (restoredPurchases.count > 0) {
        NSLog(@"Restore Success: %@", restoredPurchases);
        return [self alertWithTitle:@"Purchases Restored" message:@"All purchases have been restored"];
    } else {
        NSLog(@"Nothing to Restore");
        return [self alertWithTitle:@"Nothing to Restore" message:@"No previous purchases were found"];
    }
}

- (UIAlertController *)alertForVerifyReceipt:(NSDictionary *)receipt error:(HYReceiptError *)error {
    if (receipt) {
        NSLog(@"Verify receipt Success: %@", receipt);
        return [self alertWithTitle:@"Receipt verified" message:@"Receipt verified remotely"];
    }
    
    NSLog(@"Verify receipt Failed: %@", error);
    switch (error.receiptErrorType) {
        case HYReceiptErrorTypeNoReceiptData:
            return [self alertWithTitle:@"Receipt verification" message:@"No receipt data. Try again."];
        case HYReceiptErrorTypeNetworkError:
            return [self alertWithTitle:@"Receipt verification" message:[NSString stringWithFormat:@"Network error while verifying receipt: %@", error.error]];
        default:
            return [self alertWithTitle:@"Receipt verification" message:[NSString stringWithFormat:@"Receipt verification failed: %@", error.error]];
    }
}

- (UIAlertController *)alertForVerifySubscriptions:(HYVerifySubscriptionResult *)result productIds:(NSSet<NSString *> *)productIds {
    switch (result.status) {
        case HYSubscriptionStatusPurchased:
            NSLog(@"%@ is valid until %@\n%@\n", productIds, result.expiryDate, result.items);
            return [self alertWithTitle:@"Product is purchased" message:[NSString stringWithFormat:@"Product is valid until %@", result.expiryDate]];
        case HYSubscriptionStatusExpired:
            NSLog(@"%@ is expired since %@\n%@\n", productIds, result.expiryDate, result.items);
            return [self alertWithTitle:@"Product expired" message:[NSString stringWithFormat:@"Product is expired since %@", result.expiryDate]];
        case HYSubscriptionStatusNotPurchased:
            NSLog(@"%@ has never been purchased", productIds);
            return [self alertWithTitle:@"Not purchased" message:@"This product has never been purchased"];
    }
}

- (UIAlertController *)alertForVerifyPurchase:(HYReceiptItem *)item productId:(NSString *)productId {
    if (item) {
        NSLog(@"%@ is purchased", productId);
        return [self alertWithTitle:@"Product is purchased" message:@"Product will not expire"];
    } else {
        NSLog(@"%@ has never been purchased", productId);
        return [self alertWithTitle:@"Not purchased" message:@"This product has never been purchased"];
    }
}

#pragma mark - non consumable

- (IBAction)nonConsumableGetInfo {
    [self getInfo:nonConsumablePurchase];
}

- (IBAction)nonConsumablePurchase {
    [self purchase:nonConsumablePurchase atomically:self.nonConsumableAtomicSwitch.isOn];
}

- (IBAction)nonConsumableVerifyPurchase {
    [self verifyPurchase:nonConsumablePurchase];
}

#pragma mark - consumable

- (IBAction)consumableGetInfo {
    [self getInfo:consumablePurchase];
}

- (IBAction)consumablePurchase {
    [self purchase:consumablePurchase atomically:self.consumableAtomicSwitch.isOn];
}

- (IBAction)consumableVerifyPurchase {
    [self verifyPurchase:consumablePurchase];
}

#pragma mark - non renewing

- (IBAction)nonRenewingGetInfo {
    [self getInfo:nonRenewingPurchase];
}

- (IBAction)nonRenewingPurchase {
    [self purchase:nonRenewingPurchase atomically:self.nonRenewingAtomicSwitch.isOn];
}

- (IBAction)nonRenewingVerifyPurchase {
    [self verifyPurchase:nonRenewingPurchase];
}

#pragma mark - auto renewable

- (NSString *)autoRenewableProduct {
    switch (self.autoRenewableSubscriptionSegmentedControl.selectedSegmentIndex) {
        case 0:
            return autoRenewableWeekly;
        case 1:
            return autoRenewableMonthly;
        case 2:
            return autoRenewableYearly;
        default:
            return autoRenewableWeekly;
    }
}

- (IBAction)autoRenewableGetInfo {
    [self getInfo:[self autoRenewableProduct]];
}

- (IBAction)autoRenewablePurchase {
    [self purchase:[self autoRenewableProduct] atomically:self.autoRenewableAtomicSwitch.isOn];
}

- (IBAction)autoRenewableVerifyPurchase {
    [self verifySubscriptions:@[autoRenewableWeekly, autoRenewableMonthly, autoRenewableYearly]];
}

- (IBAction)restorePurchases {
    [HYNetworkActivityIndicatorManager networkOperationStarted];
    [HYStoreKit restorePurchasesWithAtomically:YES applicationUsername:nil completion:^(NSArray<HYPurchase *> * _Nullable restoredPurchases, NSArray<NSError *> * _Nullable errors) {
        [HYNetworkActivityIndicatorManager networkOperationFinished];
        
        for (HYPurchase *purchase in restoredPurchases) {
            if (purchase.transaction.downloads > 0) {
                [HYStoreKit startDownloads:purchase.transaction.downloads];
            } else if (purchase.needsFinishTransaction) {
                [HYStoreKit finishTransaction:purchase.transaction];
            }
        }
        [self showAlert:[self alertForRestorePurchases:restoredPurchases restoreFailedPurchases:nil]];
    }];
}

- (IBAction)verifyReceipt {
    [HYNetworkActivityIndicatorManager networkOperationStarted];
    [self verifyReceiptWithCompletion:^(NSDictionary<NSString *,id> * _Nullable receipt, HYReceiptError * _Nullable error) {
        [HYNetworkActivityIndicatorManager networkOperationFinished];
        [self showAlert:[self alertForVerifyReceipt:receipt error:error]];
    }];
}

#pragma mark -

- (void)getInfo:(NSString *)purchase {
    [HYNetworkActivityIndicatorManager networkOperationStarted];
    NSString *productId = [NSString stringWithFormat:@"%@.%@", appBundleId, purchase];
    [HYStoreKit retrieveProductsInfoWithProductIds:[NSSet setWithObject:productId] completion:^(NSArray<SKProduct *> * _Nullable retrievedProducts, NSArray<NSString *> * _Nullable invalidProductIDs, NSError * _Nullable error) {
        [HYNetworkActivityIndicatorManager networkOperationFinished];
        
        [self showAlert:[self alertForProductWithRetrievedProducts:retrievedProducts invalidProductIDs:invalidProductIDs error:error]];
    }];
}

- (void)purchase:(NSString *)purchase atomically:(BOOL)atomically {
    [HYNetworkActivityIndicatorManager networkOperationStarted];
    NSString *productId = [NSString stringWithFormat:@"%@.%@", appBundleId, purchase];
    [HYStoreKit purchaseProductWithProductId:productId quantity:1 atomically:atomically applicationUsername:nil simulatesAskToBuyInSandbox:NO completion:^(HYPurchase * _Nullable purchase, NSError * _Nullable error) {
        [HYNetworkActivityIndicatorManager networkOperationFinished];
        
        if (purchase) {
            if (purchase.transaction.downloads.count > 0) {
                [HYStoreKit startDownloads:purchase.transaction.downloads];
            }
            if (purchase.needsFinishTransaction) {
                [HYStoreKit finishTransaction:purchase.transaction];
            }
        }
        
        UIAlertController *alert = [self alertForPurchase:purchase error:error];
        if (alert) {
            [self showAlert:alert];
        }
    }];
}

- (void)verifyPurchase:(NSString *)purchase {
    [HYNetworkActivityIndicatorManager networkOperationStarted];
    [self verifyReceiptWithCompletion:^(NSDictionary<NSString *,id> * _Nullable receiptInfo, HYReceiptError * _Nullable error) {
        [HYNetworkActivityIndicatorManager networkOperationFinished];
        
        if (receiptInfo) {
            NSString *productId = [NSString stringWithFormat:@"%@.%@", appBundleId, purchase];
            
            if ([purchase isEqualToString:autoRenewableWeekly] || [purchase isEqualToString:autoRenewableMonthly] || [purchase isEqualToString:autoRenewableYearly]) {
                HYSubscription *subscription = [[HYSubscription alloc] initWithSubscriptionType:HYSubscriptionTypeAutoRenewable validDuration:0];
                HYVerifySubscriptionResult *result = [HYStoreKit verifySubscription:subscription productId:productId inReceipt:receiptInfo validUntil:[NSDate date]];
                [self showAlert:[self alertForVerifySubscriptions:result productIds:[NSSet setWithObject:productId]]];
            } else if ([purchase isEqualToString:nonRenewingPurchase]) {
                HYSubscription *subscription = [[HYSubscription alloc] initWithSubscriptionType:HYSubscriptionTypeNonRenewing validDuration:60];
                HYVerifySubscriptionResult *result = [HYStoreKit verifySubscription:subscription productId:productId inReceipt:receiptInfo validUntil:[NSDate date]];
                [self showAlert:[self alertForVerifySubscriptions:result productIds:[NSSet setWithObject:productId]]];
            } else {
                HYReceiptItem *item = [HYStoreKit verifyPurchaseWithProductId:productId inReceipt:receiptInfo];
                [self showAlert:[self alertForVerifyPurchase:item productId:productId]];
            }
        }
    }];
}

- (void)verifyReceiptWithCompletion:(void(^)(NSDictionary<NSString *,id> * _Nullable, HYReceiptError * _Nullable))completion {
    HYAppleReceiptValidator *appleValidator = [[HYAppleReceiptValidator alloc] init];
    appleValidator.serverAddress = productionServerAddress;
    appleValidator.sharedSecret = @"your-shared-secret";
    [HYStoreKit verifyReceiptUsingValidator:(id<HYReceiptValidator>)appleValidator forceRefresh:NO completion:completion];
}

- (void)verifySubscriptions:(NSArray<NSString *> *)purchases {
    [HYNetworkActivityIndicatorManager networkOperationStarted];
    [self verifyReceiptWithCompletion:^(NSDictionary<NSString *,id> * _Nullable receipt, HYReceiptError * _Nullable error) {
        [HYNetworkActivityIndicatorManager networkOperationFinished];
        
        if (receipt) {
            NSMutableSet *productIds = [NSMutableSet set];
            for (NSInteger i = 0; i < purchases.count; i++) {
                NSString *productId = [NSString stringWithFormat:@"%@.%@", appBundleId, purchases[i]];
                [productIds addObject:productId];
            }
            HYSubscription *subscription = [[HYSubscription alloc] initWithSubscriptionType:HYSubscriptionTypeAutoRenewable validDuration:0];
            HYVerifySubscriptionResult *result = [HYStoreKit verifySubscriptions:subscription productIds:productIds.copy inReceipt:receipt validUntil:[NSDate date]];
            [self showAlert:[self alertForVerifySubscriptions:result productIds:productIds.copy]];
        }
        if (error) {
            [self showAlert:[self alertForVerifyReceipt:receipt error:error]];
        }
    }];
}

@end
