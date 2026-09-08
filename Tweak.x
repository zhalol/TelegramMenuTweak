#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import <substrate.h>

// ============================================================
// SatellaJailed Preferences (must be before UIWindow hook)
// ============================================================
static NSString *const kTellaIsEnabled    = @"tella_isEnabled";
static NSString *const kTellaIsGesture    = @"tella_isGesture";
static NSString *const kTellaIsHidden     = @"tella_isHidden";
static NSString *const kTellaIsObserver   = @"tella_isObserver";
static NSString *const kTellaIsPriceZero  = @"tella_isPriceZero";
static NSString *const kTellaIsReceipt    = @"tella_isReceipt";
static NSString *const kTellaIsStealth    = @"tella_isStealth";

static inline BOOL TellaPref(NSString *key, BOOL defaultValue) {
    NSUserDefaults *prefs = [UserDefaults.standardDefaults];
    id val = [prefs forKey:key];
    return val ? [val boolValue] : defaultValue;
}

// One-time defaults seeding (matches original Preferences.swift defaults)
__attribute__((constructor))
static void SatellaSeedDefaults(void) {
    NSUserDefaults *prefs = [UserDefaults.standardDefaults];
    if ([prefs forKey:kTellaIsEnabled]  == nil) [prefs setBool:YES  forKey:kTellaIsEnabled];
    if ([prefs forKey:kTellaIsGesture]  == nil) [prefs setBool:YES  forKey:kTellaIsGesture];
    if ([prefs forKey:kTellaIsHidden]   == nil) [prefs setBool:NO   forKey:kTellaIsHidden];
    if ([prefs forKey:kTellaIsObserver] == nil) [prefs setBool:NO   forKey:kTellaIsObserver];
    if ([prefs forKey:kTellaIsPriceZero]== nil) [prefs setBool:NO   forKey:kTellaIsPriceZero];
    if ([prefs forKey:kTellaIsReceipt]  == nil) [prefs setBool:NO   forKey:kTellaIsReceipt];
    if ([prefs forKey:kTellaIsStealth]  == nil) [prefs setBool:NO   forKey:kTellaIsStealth];
    [prefs synchronize];

    NSString *bundleID = [[bundles mainBundle] bundleIdentifier] ?: @"(unknown)";
    NSLog(@"[botcczz] loaded into bundle: %@  defaults seeded", bundleID);
}

// ============================================================
// SatellaJailed-style IAP Hooks (Updated Architecture)
// ============================================================

%hook SKPaymentQueue
+ (BOOL)canMakePayments {
    if (!TellaPref(kTellaIsEnabled, YES)) return %orig;
    return YES;
}

// Intercept addPayment: - forward to original (Satella style)
- (void)addPayment:(SKPayment *)payment {
    if (!TellaPref(kTellaIsEnabled, YES)) {
        return %orig;
    }
    NSLog(@"[botcczz] addPayment for product: %@", payment.productIdentifier);
    return %orig;
}
%end

%hook SKPaymentQueue
- (void)paymentQueue:(SKPaymentQueue *)queue
     updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    if (!TellaPref(kTellaIsEnabled, YES)) {
        return %orig;
    }

    // SatellaJailed style: inject mock by swizzling transaction state
    for (SKPaymentTransaction *transaction in transactions) {
        if ([transaction isa:[MockTransaction class]]) {
            transaction.transactionState = SKPaymentTransactionStatePurchased;
            NSLog(@"[botcczz] injected MockTransaction: %@", transaction.transactionIdentifier);
        }
    }
    return %orig(queue, transactions);
}
%end

%hook SKPaymentQueue
- (void)finishTransaction:(SKPaymentTransaction *)transaction {
    if (!TellaPref(kTellaIsEnabled, YES)) {
        return %orig;
    }
    return %orig;
}
%end

%hook <SKProductsRequestDelegate>
- (void)productsRequest:(SKProductsRequest *)request
      didReceiveResponse:(SKProductsResponse *)response {
    if (!TellaPref(kTellaIsEnabled, YES)) {
        return %orig;
    }

    NSLog(@"[botcczz] productsRequest didReceiveResponse: %lu products", (unsigned long)response.products.count);
    for (SKProduct *product in response.products) {
        NSLog(@"[botcczz] available product: %@", product.productIdentifier);
    }
    return %orig(request, response);
}
%end
