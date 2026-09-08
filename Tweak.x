#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
#import <substrate.h>

// ============================================================
// SatellaJailed Preferences ( controls BOTH IAP and Telegram menu )
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

// One-time defaults seeding
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
// МОИ ФУНКЦИИ: Telegram Menu (Код из вашего последнего сообщения)
// ============================================================

static UIButton *telegramButton = nil;
static UIView *menuView = nil;
static BOOL menuVisible = NO;
static CGPoint initialCenter;

// Forward declaration for gesture-activation entry point
@class SatellaToggleHost;


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
- (void)installSatellaGesture;
- (void)handlePan:(UIPanGestureRecognizer *)gesture;


// IAP Control buttons
- (UIButton *)createToggleButtonWithTitle:(NSString *)title on:(BOOL)isOn tagKey:(NSString *)key y:(CGFloat)y;
- (void)iapButtonTapped:(UIButton *)sender;
@end


@implementation SatellaToggleHost
+ (instancetype)shared {
    static SatellaToggleHost *s; static dispatch_once_t once;
    dispatch_once(&once, ^{ s = [SatellaToggleHost new]; });
    return s;
}
- (void)toggleAllToggles {
    BOOL hidden = TellaPref(kTellaIsHidden, NO);
    if (hidden) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kTellaIsHidden];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return;
    }
    if (!TellaPref(kTellaIsGesture, YES)) return;
    UIWindow *key = nil;
    for (UIScene *s in [UIApplication sharedApplication].connectedScenes) {
        if ([s isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow *w in ((UIWindowScene *)s).windows) {
                if (w.isKeyWindow) { key = w; break; }
            }
        }
        if (key) break;
    }
    if (!key) return;
    UIView *flash = [[UIView alloc] initWithFrame:key.bounds];
    flash.backgroundColor = [UIColor colorWithRed:0.5 green:0.2 blue:0.8 alpha:0.35];
    flash.userInteractionEnabled = NO;
    [key addSubview:flash];
    [UIView animateWithDuration:0.6 animations:^{ flash.alpha = 0.0; }
                     completion:^(BOOL f){ [flash removeFromSuperview]; }];
}
@end


%hook UIWindow

- (void)makeKeyAndVisible {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self addTelegramMenu];
        [self installSatellaGesture];
    });
}


%new
- (void)installSatellaGesture {
    UITapGestureRecognizer *triple = [[UITapGestureRecognizer alloc] initWithTarget:[SatellaToggleHost shared]
                                                                             action:@selector(toggleAllToggles)];
    triple.numberOfTouchesRequired = 3;
    triple.numberOfTapsRequired = 2;
    triple.cancelsTouchesInView = NO;
    [self addGestureRecognizer:triple];
}


%new
- (void)addTelegramMenu {
    if (telegramButton) return;
    if (TellaPref(kTellaIsHidden, NO)) return;

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

    CGFloat rowH = 44.0;
    CGFloat gap  = 8.0;
    CGFloat menuWidth  = 300;

    CGFloat topSectionH = 254.0;
    CGFloat iapHeaderH = 32.0;
    NSInteger rowCount = 7;
    CGFloat scrollContentH = iapHeaderH + rowH * rowCount + gap * (rowCount - 1) + 16.0;
    CGFloat bottomPad = 16.0;
    CGFloat idealMenuH = topSectionH + scrollContentH + bottomPad;

    CGFloat maxH = self.bounds.size.height - 40.0;
    CGFloat menuHeight = MIN(idealMenuH, maxH);

    CGFloat menuX = (self.bounds.size.width - menuWidth) / 2;
    CGFloat menuY = (self.bounds.size.height - menuHeight) / 2;
    if (menuY < 20) menuY = 20;

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
    menuView.clipsToBounds = YES;

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
    channelButton.frame = CGRectMake(20, 84, menuWidth - 40, 48);
    channelButton.backgroundColor = [UIColor colorWithRed:0.13 green:0.59 blue:0.95 alpha:1.0];
    channelButton.layer.cornerRadius = 14;
    [channelButton setTitle:@"📢  Наш канал" forState:UIControlStateNormal];
    [channelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    channelButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [channelButton addTarget:self action:@selector(openChannel) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:channelButton];


    UIButton *chatButton = [UIButton buttonWithType:UIButtonTypeSystem];
    chatButton.frame = CGRectMake(20, 140, menuWidth - 40, 48);
    chatButton.backgroundColor = [UIColor colorWithRed:0.20 green:0.70 blue:0.55 alpha:1.0];
    chatButton.layer.cornerRadius = 14;
    [chatButton setTitle:@"💬  Наш чат" forState:UIControlStateNormal];
    [chatButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    chatButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [chatButton addTarget:self action:@selector(openChat) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:chatButton];


    UIButton *creatorButton = [UIButton buttonWithType:UIButtonTypeSystem];
    creatorButton.frame = CGRectMake(20, 196, menuWidth - 40, 48);
    creatorButton.backgroundColor = [UIColor colorWithRed:0.85 green:0.35 blue:0.55 alpha:1.0];
    creatorButton.layer.cornerRadius = 14;
    [creatorButton setTitle:@"👑  Создатель" forState:UIControlStateNormal];
    [creatorButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    creatorButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [creatorButton addTarget:self action:@selector(openCreator) forControlEvents:UIControlEventTouchUpInside];
    [menuView addSubview:creatorButton];


    UIView *separator2 = [[UIView alloc] initWithFrame:CGRectMake(20, 254, menuWidth - 40, 0.5)];
    separator2.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
    [menuView addSubview:separator2];


    CGFloat scrollY = topSectionH;
    CGFloat scrollH = menuHeight - scrollY - bottomPad;

    UIScrollView *scroll = [[UIScrollView alloc] initWithFrame:CGRectMake(0, scrollY, menuWidth, scrollH)];
    scroll.backgroundColor = [UIColor clearColor];
    scroll.showsVerticalScrollIndicator = YES;
    scroll.showsHorizontalScrollIndicator = NO;
    scroll.alwaysBounceVertical = YES;
    scroll.contentInset = UIEdgeInsetsMake(0, 0, 8, 0);
    [menuView addSubview:scroll];


    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, menuWidth, scrollContentH)];
    contentView.backgroundColor = [UIColor clearColor];
    [scroll addSubview:contentView];
    scroll.contentSize = CGSizeMake(menuWidth, scrollContentH);


    UILabel *iapTitle = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, menuWidth - 40, 22)];
    iapTitle.text = @"⚙️  SatellaJailed IAP";
    iapTitle.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
    iapTitle.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    iapTitle.textAlignment = NSTextAlignmentCenter;
    [contentView addSubview:iapTitle];


    CGFloat y = iapHeaderH;
    [contentView addSubview:[self createToggleButtonWithTitle:@"🔓  IAP Bypass"      on:TellaPref(kTellaIsEnabled,  YES) tagKey:kTellaIsEnabled  y:y]]; y += rowH + gap;
    [contentView addSubview:[self createToggleButtonWithTitle:@"👆  3-finger Gesture" on:TellaPref(kTellaIsGesture,  YES) tagKey:kTellaIsGesture  y:y]]; y += rowH + gap;
    [contentView addSubview:[self createToggleButtonWithTitle:@"🙈  Hide Toggle"      on:TellaPref(kTellaIsHidden,   NO)  tagKey:kTellaIsHidden   y:y]]; y += rowH + gap;
    [contentView addSubview:[self createToggleButtonWithTitle:@"👁  Observer Hook"    on:TellaPref(kTellaIsObserver, NO)  tagKey:kTellaIsObserver y:y]]; y += rowH + gap;
    [contentView addSubview:[self createToggleButtonWithTitle:@"💰  Price = $0.01"    on:TellaPref(kTellaIsPriceZero,NO)  tagKey:kTellaIsPriceZero y:y]]; y += rowH + gap;
    [contentView addSubview:[self createToggleButtonWithTitle:@"🧾  Fake Receipt"     on:TellaPref(kTellaIsReceipt,  NO)  tagKey:kTellaIsReceipt  y:y]]; y += rowH + gap;
    [contentView addSubview:[self createToggleButtonWithTitle:@"🥷  Stealth Mode"     on:TellaPref(kTellaIsStealth,  NO)  tagKey:kTellaIsStealth  y:y]];


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
- (UIButton *)createToggleButtonWithTitle:(NSString *)title on:(BOOL)isOn tagKey:(NSString *)key y:(CGFloat)y {
    CGFloat menuWidth = 300;
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.frame = CGRectMake(20, y, menuWidth - 40, 44);
    btn.backgroundColor = isOn ? [UIColor colorWithRed:0.2 green:0.6 blue:0.3 alpha:1.0] : [UIColor colorWithRed:0.6 green:0.2 blue:0.2 alpha:1.0];
    btn.layer.cornerRadius = 12;
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btn.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
    [btn setTitle:[NSString stringWithFormat:@"%@  %@", title, isOn ? @"✅ ВКЛ" : @"❌ ВЫКЛ"] forState:UIControlStateNormal];
    objc_setAssociatedObject(btn, "tellaKey", key, OBJC_ASSOCIATION_COPY_NONATOMIC);
    [btn addTarget:self action:@selector(iapButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    return btn;
}


%new
- (void)iapButtonTapped:(UIButton *)sender {
    NSString *key = objc_getAssociatedObject(sender, "tellaKey");
    if (![key isKindOfClass:[NSString class]]) return;


    BOOL newValue = !TellaPref(key, NO);
    [[NSUserDefaults standardUserDefaults] setBool:newValue forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];


    if ([key isEqualToString:kTellaIsStealth] && newValue) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kTellaIsPriceZero];
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kTellaIsReceipt];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }


    sender.backgroundColor = newValue ? [UIColor colorWithRed:0.2 green:0.6 blue:0.3 alpha:1.0] : [UIColor colorWithRed:0.6 green:0.2 blue:0.2 alpha:1.0];
    NSString *current = sender.titleLabel.text ?: @"";
    NSArray *parts = [current componentsSeparatedByString:@"  "];
    NSString *baseTitle = (parts.count >= 2) ? parts[0] : current;
    [sender setTitle:[NSString stringWithFormat:@"%@  %@", baseTitle, newValue ? @"✅ ВКЛ" : @"❌ ВЫКЛ"] forState:UIControlStateNormal];


    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedback prepare];
    [feedback impactOccurred];


    if ([key isEqualToString:kTellaIsHidden] && newValue) {
        if (telegramButton) {
            [UIView animateWithDuration:0.25 animations:^{
                telegramButton.alpha = 0.0;
                telegramButton.transform = CGAffineTransformMakeScale(0.6, 0.6);
            } completion:^(BOOL f) {
                [telegramButton removeFromSuperview];
                telegramButton = nil;
            }];
        }
        [self hideMenu];
    }
}


%end



// ============================================================
// СТИЛЬ САТЕЛЛЫ: IAP Hooks (Swizzling - без Mock-классов)
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


// 3. ProductHook - Make products appear free (price = 0.01) — disabled in Stealth
%hook SKProduct
- (NSDecimalNumber *)price {
    if (TellaPref(kTellaIsStealth,  NO)) return %orig;
    if (!TellaPref(kTellaIsPriceZero, NO)) return %orig;
    return [NSDecimalNumber decimalNumberWithString:@"0.01"];
}
%end


// 4. ReceiptHook - Provide fake transaction receipt — disabled in Stealth
%hook SKPaymentTransaction
- (NSData *)transactionReceipt {
    if (TellaPref(kTellaIsStealth,  NO)) return %orig;
    if (!TellaPref(kTellaIsReceipt, NO)) return %orig;
    return [NSData data];
}
%end