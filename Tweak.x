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
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    id val = [prefs objectForKey:key];
    return val ? [val boolValue] : defaultValue;
}

// One-time defaults seeding (matches original Preferences.swift defaults)
__attribute__((constructor))
static void SatellaSeedDefaults(void) {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    if ([prefs objectForKey:kTellaIsEnabled]  == nil) [prefs setBool:YES  forKey:kTellaIsEnabled];
    if ([prefs objectForKey:kTellaIsGesture]  == nil) [prefs setBool:YES  forKey:kTellaIsGesture];
    if ([prefs objectForKey:kTellaIsHidden]   == nil) [prefs setBool:NO   forKey:kTellaIsHidden];
    if ([prefs objectForKey:kTellaIsObserver] == nil) [prefs setBool:NO   forKey:kTellaIsObserver];
    if ([prefs objectForKey:kTellaIsPriceZero]== nil) [prefs setBool:NO   forKey:kTellaIsPriceZero];
    if ([prefs objectForKey:kTellaIsReceipt]  == nil) [prefs setBool:NO   forKey:kTellaIsReceipt];
    if ([prefs objectForKey:kTellaIsStealth]  == nil) [prefs setBool:NO   forKey:kTellaIsStealth];
    [prefs synchronize];

    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"(unknown)";
    NSLog(@"[botcczz] loaded into bundle: %@  defaults seeded", bundleID);
}

// ============================================================
// Mock Transaction Implementation
// ============================================================

// Helper function to generate a stable transaction ID
static NSString *GenerateStableTransactionID(NSString *productIdentifier) {
    // Use a simple hash for demo purposes; in production use proper cryptographic hash
    unsigned long hash = 5381;
    const char *ptr = [productIdentifier UTF8String];
    int c;
    while ((c = *ptr++)) {
        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
    }
    return [NSString stringWithFormat:@"MOCK_%lu", hash];
}

// Helper function to generate a mock receipt as JSON-plist data
static NSData *GenerateMockReceipt(NSString *productIdentifier, NSString *transactionIdentifier) {
    NSDictionary *receiptDict = @{
        @"product_id": productIdentifier,
        @"transaction_id": transactionIdentifier,
        @"purchase_date": [NSDate date],
        @"original_transaction_id": transactionIdentifier,
        @"quantity": @1,
        @"is_trial_period": @false,
        @"in_app_ownership_type": @"Purchased"
    };
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:receiptDict options:0 error:nil];
    // Wrap in a simple plist structure that mimics a receipt (for demo purposes)
    NSDictionary *plistDict = @{
        @"receipt": receiptDict,
        @"environment": @"Sandbox"
    };
    return [NSPropertyListSerialization dataWithPropertyList:plistDict format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
}

// Mock transaction class that mimics SKPaymentTransaction
@interface MockTransaction : NSObject
@property (readonly, nonatomic) SKPaymentTransactionState transactionState;
@property (readonly, nonatomic, copy) NSString *transactionIdentifier;
@property (readonly, nonatomic, copy) NSString *matchingIdentifier;
@property (readonly, nonatomic, copy) NSData *transactionReceipt;
@property (readonly, nonatomic, copy) NSDate *transactionDate;
@property (readonly, nonatomic, copy) SKPayment *payment;
@property (readonly, nonatomic, copy) NSError *error;

- (instancetype)initWithPayment:(SKPayment *)payment;
- (void)setTransactionState:(SKPaymentTransactionState)state;
@end

@implementation MockTransaction {
    SKPaymentTransactionState _transactionState;
    NSString *_transactionIdentifier;
    NSString *_matchingIdentifier;
    NSData *_transactionReceipt;
    NSDate *_transactionDate;
    SKPayment *_payment;
    NSError *_error;
}

- (instancetype)initWithPayment:(SKPayment *)payment {
    self = [super init];
    if (self) {
        _payment = payment;
        _transactionIdentifier = GenerateStableTransactionID(payment.productIdentifier);
        _matchingIdentifier = _transactionIdentifier; // Simplified
        _transactionReceipt = GenerateMockReceipt(payment.productIdentifier, _transactionIdentifier);
        _transactionDate = [NSDate date];
        _transactionState = SKPaymentTransactionStatePurchasing;
        _error = nil;
    }
    return self;
}

- (void)setTransactionState:(SKPaymentTransactionState)state {
    _transactionState = state;
}

// We don't need to implement dealloc unless we have resources
@end

// Global store for active mock payments
static NSMutableDictionary *ActiveMockPayments = nil;

// Constructor to initialize the mock store
__attribute__((constructor))
static void InitializeMockStore(void) {
    ActiveMockPayments = [NSMutableDictionary new];
}

// ============================================================
// SatellaJailed IAP Hooks (Updated Architecture)
// ============================================================

%hook SKPaymentQueue
+ (BOOL)canMakePayments {
    if (!TellaPref(kTellaIsEnabled, YES)) return %orig;
    return YES;
}

// Intercept addPayment: to create and register mock transaction
- (void)addPayment:(SKPayment *)payment {
    if (!TellaPref(kTellaIsEnabled, YES)) {
        return %orig;
    }

    NSLog(@"[botcczz] addPayment for product: %@", payment.productIdentifier);

    // Create mock transaction
    MockTransaction *mock = [[MockTransaction alloc] initWithPayment:payment];
    NSLog(@"[botcczz] created MockTransaction id=%@ product=%@", mock.transactionIdentifier, mock.productIdentifier);

    // Register in active mock payments
    ActiveMockPayments[payment] = mock;

    // Simulate transition to purchased after a small delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        mock.transactionState = SKPaymentTransactionStatePurchased;
        NSLog(@"[botcczz] MockTransaction state updated to purchased: %@", mock.transactionIdentifier);
        // Note: The actual injection happens in paymentQueue:updatedTransactions:
    });

    // Do NOT call %orig to prevent real StoreKit payment
}
%end

%hook SKPaymentQueue
- (void)paymentQueue:(SKPaymentQueue *)queue
     updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    if (!TellaPref(kTellaIsEnabled, YES)) {
        return %orig;
    }

    NSMutableArray *newTransactions = [transactions mutableCopy];
    NSUInteger originalCount = transactions.count;
    NSUInteger mockCount = 0;

    // Inject mock transactions that are in purchased state
    for (MockTransaction *mock in [ActiveMockPayments allValues]) {
        if (mock.transactionState == SKPaymentTransactionStatePurchased) {
            [newTransactions addObject:mock];
            mockCount++;
            NSLog(@"[botcczz] injecting MockTransaction: %@ (%@)", mock.transactionIdentifier, mock.payment.productIdentifier);
        }
    }

    NSLog(@"[botcczz] updatedTransactions: %lu original, %lu mock added", (unsigned long)originalCount, (unsigned long)mockCount);
    return %orig(queue, newTransactions);
}
%end

%hook SKPaymentQueue
- (void)finishTransaction:(SKPaymentTransaction *)transaction {
    if (!TellaPref(kTellaIsEnabled, YES)) {
        return %orig;
    }

    if ([transaction isKindOfClass:[MockTransaction class]]) {
        MockTransaction *mock = (MockTransaction *)transaction;
        mock.transactionState = SKPaymentTransactionStateFinished;
        NSLog(@"[botcczz] finishTransaction called for MockTransaction: %@", mock.transactionIdentifier);

        // Remove from active mock payments by finding the payment key
        for (SKPayment *payment in [ActiveMockPayments keyEnumerator]) {
            if ([ActiveMockPayments[payment] isIdenticalTo:mock]) {
                [ActiveMockPayments removeObjectForKey:payment];
                NSLog(@"[botcczz] removed MockTransaction from active store for product: %@", payment.productIdentifier);
                break;
            }
        }
        return;
    }

    return %orig;
}
%end

// Optional: Hook SKProductsRequest to log and ensure product availability
%hook SKProductsRequest
- (void)start {
    if (!TellaPref(kTellaIsEnabled, YES)) {
        return %orig;
    }
    NSLog(@"[botcczz] SKProductsRequest started");
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

    // Optionally, we could modify the response to ensure products are available
    // but we'll just log for now

    return %orig(request, response);
}
%end