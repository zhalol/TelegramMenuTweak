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

static UIButton *telegramButton = nil;
static UIView *menuView = nil;
static BOOL menuVisible = NO;
static CGPoint initialCenter; // For pan gesture tracking

@interface UIApplication (Private)
- (void)openURL:(NSURL *)url options:(NSDictionary *)options completionHandler:(void (^)(BOOL success))completion;
@end

@interface UIWindow (TelegramMenu)
- (void)addTelegramMenu;
- (void)toggleMenu;
- (void)showMenu;
- (void)hideMenu;
- (void)openChannel;
- (void)openChat;
- (void)openCreator;
- (void)closeButtonTouchDown:(UIButton *)sender;
- (void)closeButtonTouchUp:(UIButton *)sender;
- (void)dismissMenuTap:(UITapGestureRecognizer *)gesture;

// IAP Control buttons
- (UIButton *)createToggleButtonWithTitle:(NSString *)title on:(BOOL)isOn y:(CGFloat)y;
- (void)iapButtonTapped:(UIButton *)sender;
@end

%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addTelegramMenu];
    });
}

%new
- (void)addTelegramMenu {
    if (telegramButton) return;

    CGFloat buttonSize = 56.0;
    CGFloat margin = 16.0;

    telegramButton = [UIButton buttonWithType:UIButtonTypeCustom];
    telegramButton.frame = CGRectMake(self.bounds.size.width - buttonSize - margin,
                                      self.bounds.size.height - buttonSize - margin,
                                      buttonSize,
                                      buttonSize);
    telegramButton.backgroundColor = [UIColor clearColor];
    telegramButton.layer.cornerRadius = buttonSize / 2;
    telegramButton.layer.shadowColor = [UIColor blackColor].CGColor;
    telegramButton.layer.shadowOffset = CGSizeMake(0, 2);
    telegramButton.layer.shadowOpacity = 0.3;
    telegramButton.layer.shadowRadius = 4;
    telegramButton.layer.masksToBounds = NO;
    telegramButton.layer.borderWidth = 1.0;
    telegramButton.layer.borderColor = [UIColor whiteColor].CGColor;

    UIImage *customIcon = [UIImage imageNamed:@"botcczz.bundle/icon"];
    if (customIcon) {
        UIImageView *iconView = [[UIImageView alloc] initWithImage:customIcon];
        iconView.frame = telegramButton.bounds;
        iconView.contentMode = UIViewContentModeScaleAspectFill;
        iconView.layer.cornerRadius = buttonSize / 2;
        iconView.layer.masksToBounds = YES;
        iconView.userInteractionEnabled = NO;
        [telegramButton addSubview:iconView];
    } else {
        telegramButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:0.8];
        UILabel *label = [[UILabel alloc] initWithFrame:telegramButton.bounds];
        label.text = @"💬";
        label.font = [UIFont systemFontOfSize:28];
        label.textAlignment = NSTextAlignmentCenter;
        label.userInteractionEnabled = NO;
        [telegramButton addSubview:label];
    }

    [telegramButton addTarget:self
                       action:@selector(toggleMenu)
             forControlEvents:UIControlEventTouchUpInside];

    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [telegramButton addGestureRecognizer:panGesture];

    [self addSubview:telegramButton];
}

%new
- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *view = gesture.view;
    CGPoint translation = [gesture translationInView:self];

    if (gesture.state == UIGestureRecognizerStateBegan) {
        initialCenter = view.center;
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint newCenter = CGPointMake(initialCenter.x + translation.x, initialCenter.y + translation.y);
        CGFloat padding = 20.0;
        newCenter.x = MAX(padding + view.bounds.size.width/2, MIN(newCenter.x, self.bounds.size.width - padding - view.bounds.size.width/2));
        newCenter.y = MAX(padding + view.bounds.size.height/2, MIN(newCenter.y, self.bounds.size.height - padding - view.bounds.size.height/2));
        view.center = newCenter;
    } else if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled) {
        UIView *button = gesture.view;
        CGFloat midX = self.bounds.size.width / 2.0;
        CGFloat targetX = (button.center.x < midX)
            ? button.bounds.size.width/2 + 20.0
            : self.bounds.size.width - button.bounds.size.width/2 - 20.0;

        [UIView animateWithDuration:0.25
                              delay:0
                 usingSpringWithDamping:0.8
                  initialSpringVelocity:0.5
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            button.center = CGPointMake(targetX, button.center.y);
        } completion:nil];
    }
}

%new
- (void)toggleMenu {
    if (menuVisible) {
        [self hideMenu];
    } else {
        [self showMenu];
    }
}

%new
- (void)showMenu {
    if (menuView) return;

    CGFloat menuWidth = 290;
    CGFloat menuHeight = 460;
    CGFloat menuX = (self.bounds.size.width - menuWidth) / 2;
    CGFloat menuY = (self.bounds.size.height - menuHeight) / 2;

    UIView *overlay = [[UIView alloc] initWithFrame:self.bounds];
    overlay.tag = 9999;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissMenuTap:)];
    [overlay addGestureRecognizer:tap];
    [self addSubview:overlay];

    menuView = [[UIView alloc] initWithFrame:CGRectMake(menuX, menuY, menuWidth, menuHeight)];
    menuView.backgroundColor = [UIColor colorWithRed:0.08 green:0.09 blue:0.12 alpha:0.97];
    menuView.layer.cornerRadius = 24;
    menuView.layer.shadowColor = [UIColor blackColor].CGColor;
    menuView.layer.shadowOffset = CGSizeMake(0, 6);
    menuView.layer.shadowOpacity = 0.4;
    menuView.layer.shadowRadius = 12;
    menuView.layer.borderWidth = 0.5;
    menuView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 20, menuWidth, 30)];
    titleLabel.text = @"WSC IOS";
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont boldSystemFontOfSize:24];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [menuView addSubview:titleLabel];

    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(20, 64, menuWidth - 40, 0.5)];
    separator.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
    [menuView addSubview:separator];

    UIButton *channelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    channelButton.frame = CGRectMake(20, 84, menuWidth - 40, 52);
    channelButton.backgroundColor = [UIColor colorWithRed:0.13 green:0.59 blue:0.95 alpha:1.0];
    channelButton.layer.cornerRadius = 14;
    [channelButton setTitle:@"📢  Наш канал" forState:UIControlStateNormal];
    [channelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    channelButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [channelButton addTarget:self action:@selector(openChannel) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:channelButton];

    UIButton *chatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    chatButton.frame = CGRectMake(20, 146, menuWidth - 40, 52);
    chatButton.backgroundColor = [UIColor colorWithRed:0.20 green:0.70 blue:0.55 alpha:1.0];
    chatButton.layer.cornerRadius = 14;
    [chatButton setTitle:@"💬  Наш чат" forState:UIControlStateNormal];
    [chatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    chatButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [chatButton addTarget:self action:@selector(openChat) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:chatButton];

    UIButton *creatorButton = [UIButton buttonWithType:UIButtonTypeSystem];
    creatorButton.frame = CGRectMake(20, 208, menuWidth - 40, 52);
    creatorButton.backgroundColor = [UIColor colorWithRed:0.85 green:0.35 blue:0.55 alpha:1.0];
    creatorButton.layer.cornerRadius = 14;
    [creatorButton setTitle:@"👑  Создатель" forState:UIControlStateNormal];
    [creatorButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    creatorButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [creatorButton addTarget:self action:@selector(openCreator) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:creatorButton];

    UIView *separator2 = [[UIView alloc] initWithFrame:CGRectMake(20, 270, menuWidth - 40, 0.5)];
    separator2.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
    [menuView addSubview:separator2];

    UILabel *iapTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 280, menuWidth - 40, 24)];
    iapTitle.text = @"⚙️  SatellaJailed IAP";
    iapTitle.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    iapTitle.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    iapTitle.textAlignment = NSTextAlignmentCenter;
    [menuView addSubview:iapTitle];

    BOOL iapEnabled = TellaPref(kTellaIsEnabled, YES);
    BOOL priceZero = TellaPref(kTellaIsPriceZero, NO);
    BOOL receipt = TellaPref(kTellaIsReceipt, NO);
    BOOL observer = TellaPref(kTellaIsObserver, NO);

    [menuView addSubview:[self createToggleButtonWithTitle:@"🔓  IAP Bypass" on:iapEnabled y:314]];
    [menuView addSubview:[self createToggleButtonWithTitle:@"💰  Price = $0.01" on:priceZero y:366]];
    [menuView addSubview:[self createToggleButtonWithTitle:@"🧾  Fake Receipt" on:receipt y:418]];
    [menuView addSubview:[self createToggleButtonWithTitle:@"👁  Observer Hook" on:observer y:470]];

    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    closeButton.frame = CGRectMake(menuWidth - 44, 8, 36, 36);
    [closeButton setTitle:@"✕" forState:UIControlStateNormal];
    [closeButton setTitleColor:[UIColor colorWithWhite:0.8 alpha:1.0] forState:UIControlStateNormal];
    closeButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];
    closeButton.layer.cornerRadius = 18;
    [closeButton addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:closeButton];

    menuView.alpha = 0;
    menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    [self addSubview:menuView];

    [UIView animateWithDuration:0.35
                          delay:0
                 usingSpringWithDamping:0.7
                  initialSpringVelocity:0.5
                            options:UIViewAnimationOptionAllowUserInteraction
                         animations:^{
        overlay.alpha = 1.0;
        menuView.alpha = 1.0;
        menuView.transform = CGAffineTransformIdentity;
    } completion:nil];

    menuVisible = YES;
}

%new
- (void)hideMenu {
    if (!menuView) return;

    UIView *overlay = [self viewWithTag:9999];

    [UIView animateWithDuration:0.2
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction
                     animations:^{
        if (overlay) overlay.alpha = 0;
        menuView.alpha = 0;
        menuView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    } completion:^(BOOL finished) {
        [menuView removeFromSuperview];
        menuView = nil;
        [overlay removeFromSuperview];
        menuVisible = NO;
    }];
}

%new
- (void)dismissMenuTap:(UITapGestureRecognizer *)gesture {
    [self hideMenu];
}

%new
- (void)openChannel {
    NSURL *url = [NSURL URLWithString:@"https://t.me/wsciosipa"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
    [self hideMenu];
}

%new
- (void)openChat {
    NSURL *url = [NSURL URLWithString:@"https://t.me/wsciosipachat"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
    [self hideMenu];
}

%new
- (void)openCreator {
    NSURL *url = [NSURL URLWithString:@"https://t.me/botcczz"];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
    [self hideMenu];
}

%new
- (UIButton *)createToggleButtonWithTitle:(NSString *)title on:(BOOL)isOn y:(CGFloat)y {
    CGFloat menuWidth = 290;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(20, y, menuWidth - 40, 44);
    btn.backgroundColor = isOn ? [UIColor colorWithRed:0.2 green:0.6 blue:0.3 alpha:1.0] : [UIColor colorWithRed:0.6 green:0.2 blue:0.2 alpha:1.0];
    btn.layer.cornerRadius = 12;
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [btn setTitle:[NSString stringWithFormat:@"%@  %@", title, isOn ? @"✅ ВКЛ" : @"❌ ВЫКЛ"] forState:UIControlStateNormal];
    btn.tag = (int)y;
    [btn addTarget:self action:@selector(iapButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}

%new
- (void)iapButtonTapped:(UIButton *)sender {
    NSString *key = nil;
    switch ((int)sender.tag) {
        case 314: key = kTellaIsEnabled; break;
        case 366: key = kTellaIsPriceZero; break;
        case 418: key = kTellaIsReceipt; break;
        case 470: key = kTellaIsObserver; break;
        default: return;
    }

    BOOL newValue = !TellaPref(key, NO);
    [[NSUserDefaults standardUserDefaults] setBool:newValue forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];

    sender.backgroundColor = newValue ? [UIColor colorWithRed:0.2 green:0.6 blue:0.3 alpha:1.0] : [UIColor colorWithRed:0.6 green:0.2 blue:0.2 alpha:1.0];
    NSString *baseTitle = [sender.titleLabel.text componentsSeparatedByString:@"  "][0];
    [sender setTitle:[NSString stringWithFormat:@"%@  %@", baseTitle, newValue ? @"✅ ВКЛ" : @"❌ ВЫКЛ"] forState:UIControlStateNormal];

    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedback prepare];
    [feedback impactOccurred];
}

%end


// ============================================================
// SatellaJailed IAP Hooks (core working hooks only)
// ============================================================

// 1. CanPayHook - Always allow purchases
%hook SKPaymentQueue
+ (BOOL)canMakePayments {
    if (!TellaPref(kTellaIsEnabled, YES)) return %orig;
    return YES;
}
%end

// 2. TransactionHook - Force transaction state to purchased, fake identifiers, clear errors
%hook SKPaymentTransaction
- (SKPaymentTransactionState)transactionState {
    if (!TellaPref(kTellaIsEnabled, YES)) return %orig;
    return SKPaymentTransactionStatePurchased;
}

- (NSString *)transactionIdentifier {
    if (!TellaPref(kTellaIsEnabled, YES)) return %orig;
    return [[NSUUID UUID] UUIDString];
}

- (NSString *)matchingIdentifier {
    if (!TellaPref(kTellaIsEnabled, YES)) return %orig;
    return [[NSUUID UUID] UUIDString];
}

- (NSError *)error {
    if (!TellaPref(kTellaIsEnabled, YES)) return %orig;
    return nil;
}

- (NSDate *)transactionDate {
    if (!TellaPref(kTellaIsEnabled, YES)) return %orig;
    return [NSDate date];
}
%end

// 3. ProductHook - Make products appear free (price = 0.01)
%hook SKProduct
- (NSDecimalNumber *)price {
    if (!TellaPref(kTellaIsPriceZero, NO)) return %orig;
    return [NSDecimalNumber decimalNumberWithString:@"0.01"];
}
%end

// 4. ReceiptHook - Provide fake transaction receipt
%hook SKPaymentTransaction
- (NSData *)transactionReceipt {
    if (!TellaPref(kTellaIsReceipt, NO)) return %orig;
    return [NSData data];
}
%end