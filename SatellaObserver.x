// SatellaObserver.m
// Ports SatellaJailed's SatellaObserver + SatellaDelegate (Helpers) and the
// ObserverHook / DelegateHook from the original Swift tweak into Logos/ObjC.
// Activated by kTellaIsObserver.

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import <objc/runtime.h>
#import <substrate.h>

// Re-declare preference keys (must match Tweak.x)
static NSString *const kObsIsEnabled  = @"tella_isEnabled";
static NSString *const kObsIsObserver = @"tella_isObserver";
static NSString *const kObsIsStealth  = @"tella_isStealth";

static inline BOOL ObsPref(NSString *key, BOOL defv) {
    NSUserDefaults *p = [NSUserDefaults standardUserDefaults];
    id v = [p objectForKey:key];
    return v ? [v boolValue] : defv;
}

// ============================================================
// SatellaObserver — singleton that replaces SKPaymentQueue's transaction observer
// ============================================================
@interface SatellaObserver : NSObject <SKPaymentTransactionObserver>
@property (nonatomic, strong) NSMutableArray *observers;
@property (nonatomic, strong) NSMutableSet   *seenPointers;  // prevent double-fire
+ (instancetype)shared;
@end

@implementation SatellaObserver

+ (instancetype)shared {
    static SatellaObserver *s; static dispatch_once_t once;
    dispatch_once(&once, ^{
        s = [SatellaObserver new];
        s.observers = [NSMutableArray array];
        s.seenPointers = [NSMutableSet set];
    });
    return s;
}

- (void)paymentQueue:(SKPaymentQueue *)queue
   updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    if (!ObsPref(kObsIsObserver, NO)) {
        // Disabled — forward to original observers unmodified
        for (id<SKPaymentTransactionObserver> o in self.observers) {
            @try { [o paymentQueue:queue updatedTransactions:transactions]; }
            @catch (__unused id e) {}
        }
        return;
    }

    NSMutableArray<SKPaymentTransaction *> *current = [NSMutableArray array];
    @synchronized (self.seenPointers) {
        for (SKPaymentTransaction *t in transactions) {
            NSValue *key = [NSValue valueWithPointer:(__bridge const void *)t];
            if ([self.seenPointers containsObject:key]) continue;
            [self.seenPointers addObject:key];
            [current addObject:t];
        }
    }

    for (id<SKPaymentTransactionObserver> o in self.observers) {
        if (!o) continue;
        @try { [o paymentQueue:queue updatedTransactions:current]; }
        @catch (__unused id e) {}
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray<SKPaymentTransaction *> *)transactions {
    for (id<SKPaymentTransactionObserver> o in self.observers) {
        if (!o) continue;
        if ([o respondsToSelector:@selector(paymentQueue:removedTransactions:)]) {
            @try { [o paymentQueue:queue removedTransactions:transactions]; }
            @catch (__unused id e) {}
        }
    }
    @synchronized (self.seenPointers) {
        for (SKPaymentTransaction *t in transactions) {
            [self.seenPointers removeObject:[NSValue valueWithPointer:(__bridge const void *)t]];
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    for (id<SKPaymentTransactionObserver> o in self.observers) {
        if (!o) continue;
        if ([o respondsToSelector:@selector(paymentQueue:restoreCompletedTransactionsFailedWithError:)]) {
            @try { [o paymentQueue:queue restoreCompletedTransactionsFailedWithError:error]; }
            @catch (__unused id e) {}
        }
    }
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    for (id<SKPaymentTransactionObserver> o in self.observers) {
        if (!o) continue;
        if ([o respondsToSelector:@selector(paymentQueueRestoreCompletedTransactionsFinished:)]) {
            @try { [o paymentQueueRestoreCompletedTransactionsFinished:queue]; }
            @catch (__unused id e) {}
        }
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedDownloads:(NSArray<SKDownload *> *)downloads {
    for (id<SKPaymentTransactionObserver> o in self.observers) {
        if (!o) continue;
        if ([o respondsToSelector:@selector(paymentQueue:updatedDownloads:)]) {
            @try { [o paymentQueue:queue updatedDownloads:downloads]; }
            @catch (__unused id e) {}
        }
    }
}
@end


// ============================================================
// SKPaymentQueue.addTransactionObserver: hook
// ============================================================
%hook SKPaymentQueue

- (void)addTransactionObserver:(id<SKPaymentTransactionObserver>)observer {
    if (!ObsPref(kObsIsObserver, NO)) {
        %orig(observer);
        return;
    }
    // Stealth: keep observer chain minimal — only register our wrapper if hidden
    if (ObsPref(kObsIsStealth, NO)) {
        %orig(observer);
        return;
    }
    SatellaObserver *tella = [SatellaObserver shared];
    if (observer && observer != tella) {
        [tella.observers addObject:observer];
        NSLog(@"[botcczz] SatellaObserver wrapped original observer: %@", observer);
    }
    %orig(tella);
}

%end

// ============================================================
// +load log — confirms the SatellaObserver class is initialized
// ============================================================
%ctor {
    NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier] ?: @"(unknown)";
    NSLog(@"[botcczz] SatellaObserver online in bundle: %@", bundleID);
}
