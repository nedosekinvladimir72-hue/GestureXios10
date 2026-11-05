#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

static const CGFloat GXBottomZone = 26.0;
static const CGFloat GXTopZone = 38.0;
static const CGFloat GXIndicatorWidth = 92.0;
static const CGFloat GXIndicatorHeight = 4.0;

static id GXShared(NSString *className) {
    Class cls = objc_getClass(className.UTF8String);
    SEL sel = @selector(sharedInstance);
    if (cls && [cls respondsToSelector:sel]) {
        return ((id (*)(id, SEL))objc_msgSend)(cls, sel);
    }
    return nil;
}

static BOOL GXSendNoArg(id object, NSArray<NSString *> *names) {
    if (!object) return NO;
    for (NSString *name in names) {
        SEL sel = NSSelectorFromString(name);
        if ([object respondsToSelector:sel]) {
            ((void (*)(id, SEL))objc_msgSend)(object, sel);
            return YES;
        }
    }
    return NO;
}

@interface GXIndicatorView : UIView
@property(nonatomic, strong) UIView *pill;
- (void)showAnimated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;
@end

@implementation GXIndicatorView
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;

        _pill = [[UIView alloc] initWithFrame:CGRectZero];
        _pill.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.96];
        _pill.layer.cornerRadius = GXIndicatorHeight / 2.0;
        _pill.layer.masksToBounds = YES;
        _pill.layer.shadowColor = UIColor.blackColor.CGColor;
        _pill.layer.shadowOpacity = 0.18;
        _pill.layer.shadowRadius = 2.0;
        _pill.layer.shadowOffset = CGSizeMake(0, 1);
        [self addSubview:_pill];

        self.alpha = 0.0;
        [self setNeedsLayout];
    }
    return self;
}
- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat w = GXIndicatorWidth;
    CGFloat h = GXIndicatorHeight;
    CGFloat x = (CGRectGetWidth(self.bounds) - w) / 2.0;
    CGFloat y = CGRectGetHeight(self.bounds) - 10.0 - h;
    // Pixel-align the pill for the iPhone 5's @2x display.
    x = round(x * scale) / scale;
    y = round(y * scale) / scale;
    self.pill.frame = CGRectMake(x, y, w, h);
}
- (void)showAnimated:(BOOL)animated {
    [self setNeedsLayout];
    if (animated) {
        self.pill.transform = CGAffineTransformMakeScale(0.82, 0.82);
        [UIView animateWithDuration:0.22
                              delay:0
             usingSpringWithDamping:0.78
              initialSpringVelocity:0.4
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            self.alpha = 1.0;
            self.pill.transform = CGAffineTransformIdentity;
        } completion:nil];
    } else {
        self.alpha = 1.0;
        self.pill.transform = CGAffineTransformIdentity;
    }
}
- (void)hideAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.18
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
            self.alpha = 0.0;
            self.pill.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:nil];
    } else {
        self.alpha = 0.0;
    }
}
@end

@interface GXOverlayView : UIView
@end
@implementation GXOverlayView
- (BOOL)pointInside:(CGPoint)p withEvent:(UIEvent *)event {
    CGFloat w = CGRectGetWidth(self.bounds);
    CGFloat h = CGRectGetHeight(self.bounds);
    BOOL bottom = p.y >= h - GXBottomZone;
    BOOL topRight = p.y <= GXTopZone && p.x >= w - 76.0;
    BOOL topLeft = p.y <= GXTopZone && p.x <= 76.0;
    return bottom || topRight || topLeft;
}
@end

@interface GXGestureController : UIViewController <UIGestureRecognizerDelegate>
@property(nonatomic, strong) UIPanGestureRecognizer *bottomPan;
@property(nonatomic, strong) UIPanGestureRecognizer *rightPan;
@property(nonatomic, strong) UIPanGestureRecognizer *leftPan;
@property(nonatomic, strong) GXIndicatorView *indicator;
@property(nonatomic) CGPoint startPoint;
@property(nonatomic) BOOL didTrigger;
@end

@implementation GXGestureController

- (void)loadView {
    GXOverlayView *v = [[GXOverlayView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    v.backgroundColor = UIColor.clearColor;
    self.view = v;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.indicator = [[GXIndicatorView alloc] initWithFrame:self.view.bounds];
    self.indicator.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.indicator];
    [self.indicator showAnimated:YES];

    self.bottomPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleBottom:)];
    self.rightPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleRight:)];
    self.leftPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleLeft:)];
    for (UIPanGestureRecognizer *g in @[self.bottomPan, self.rightPan, self.leftPan]) {
        g.delegate = self;
        g.cancelsTouchesInView = NO;
        g.maximumNumberOfTouches = 1;
        [self.view addGestureRecognizer:g];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gr shouldReceiveTouch:(UITouch *)touch {
    CGPoint p = [touch locationInView:self.view];
    CGFloat w = CGRectGetWidth(self.view.bounds);
    CGFloat h = CGRectGetHeight(self.view.bounds);
    if (gr == self.bottomPan) return p.y >= h - GXBottomZone;
    if (gr == self.rightPan) return p.y <= GXTopZone && p.x >= w - 76.0;
    if (gr == self.leftPan) return p.y <= GXTopZone && p.x <= 76.0;
    return NO;
}

- (void)handleBottom:(UIPanGestureRecognizer *)g {
    CGPoint p = [g locationInView:self.view];
    CGPoint v = [g velocityInView:self.view];
    if (g.state == UIGestureRecognizerStateBegan) {
        self.startPoint = p;
        self.didTrigger = NO;
        [self.indicator showAnimated:YES];
    } else if (g.state == UIGestureRecognizerStateEnded && !self.didTrigger) {
        CGFloat dy = self.startPoint.y - p.y;
        if (dy >= 55.0 && dy < 125.0 && v.y < -220.0) {
            self.didTrigger = YES;
            [self performHome];
        } else if (dy >= 125.0 || (dy >= 85.0 && v.y < -650.0)) {
            self.didTrigger = YES;
            [self performSwitcher];
        }
    }
}

- (void)handleRight:(UIPanGestureRecognizer *)g {
    CGPoint p = [g locationInView:self.view];
    CGPoint v = [g velocityInView:self.view];
    if (g.state == UIGestureRecognizerStateBegan) self.startPoint = p;
    if (g.state == UIGestureRecognizerStateEnded &&
        p.y - self.startPoint.y > 30.0 && v.y > 0) {
        [self performControlCenter];
    }
}

- (void)handleLeft:(UIPanGestureRecognizer *)g {
    CGPoint p = [g locationInView:self.view];
    CGPoint v = [g velocityInView:self.view];
    if (g.state == UIGestureRecognizerStateBegan) self.startPoint = p;
    if (g.state == UIGestureRecognizerStateEnded &&
        p.y - self.startPoint.y > 30.0 && v.y > 0) {
        [self performNotificationCenter];
    }
}

- (void)performHome {
    id sb = GXShared(@"SBUIController");
    BOOL ok = GXSendNoArg(sb, @[@"handleHomeButtonPress", @"_handleHomeButtonPress", @"clickedHomeButton"]);
    NSLog(@"[GestureX] Home selector found: %@", ok ? @"YES" : @"NO");
}

- (void)performSwitcher {
    id sb = GXShared(@"SBUIController");
    BOOL ok = GXSendNoArg(sb, @[@"_toggleSwitcher", @"toggleSwitcher", @"activateSwitcher"]);
    NSLog(@"[GestureX] Switcher selector found: %@", ok ? @"YES" : @"NO");
}

- (void)performControlCenter {
    id cc = GXShared(@"SBControlCenterController");
    BOOL ok = GXSendNoArg(cc, @[@"present", @"_present", @"presentControlCenter"]);
    NSLog(@"[GestureX] Control Center selector found: %@", ok ? @"YES" : @"NO");
}

- (void)performNotificationCenter {
    id nc = GXShared(@"SBNotificationCenterController");
    BOOL ok = GXSendNoArg(nc, @[@"present", @"_present", @"presentNotificationCenter"]);
    NSLog(@"[GestureX] Notification Center selector found: %@", ok ? @"YES" : @"NO");
}

@end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            GXGestureController *vc = [GXGestureController new];
            UIWindow *window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
            window.windowLevel = UIWindowLevelStatusBar + 1;
            window.rootViewController = vc;
            window.backgroundColor = UIColor.clearColor;
            window.opaque = NO;
            window.userInteractionEnabled = YES;
            window.hidden = NO;
            objc_setAssociatedObject(self, "com.gesturex.window", window, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            NSLog(@"[GestureX] v0.2 overlay loaded (experimental).");
        });
    });
}
%end
