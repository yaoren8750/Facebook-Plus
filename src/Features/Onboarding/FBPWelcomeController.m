// 首次启动欢迎页面：展示 Logo 和产品名称、功能简介、联系方式、
// “不再显示”开关以及主要操作按钮。
// 首次启动时显示，也可以从设置中再次手动打开。

#import "FBPWelcomeController.h"
#import "FBPPrefs.h"
#import "FBPResources.h"
#import "FBPSheet.h"

static NSString *const kTelegramURL = @"https://t.me/ReFacebookPlus";
static NSString *const kGitHubURL   = @"https://github.com/SHAJON-404";

static const CGFloat kLogoSize      = 46.0;
static const CGFloat kGlyphColumn   = 52.0;
static const CGFloat kSideMargin    = 24.0;
static const CGFloat kButtonHeight  = 54.0;

@interface FBPWelcomeController ()
@property (nonatomic, strong) CAGradientLayer *backgroundGradient;
@property (nonatomic, strong) UISwitch *dontShowSwitch;
@end

@implementation FBPWelcomeController

+ (void)presentIfNeeded {
    if (FBPEnabled(FBPKeyIntroduced)) return;

    // 给 Facebook 自身的启动界面留出加载时间。
    // 如果在 -didFinishLaunching 中立即弹出，当前控制器可能随后被替换。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        [self present];
    });
}

+ (void)present {
    UIViewController *host = [FBPSheetPresenter topViewController];
    while (host.presentedViewController) host = host.presentedViewController;
    if (!host) return;

    FBPWelcomeController *welcome = [[FBPWelcomeController alloc] init];
    welcome.modalPresentationStyle = UIModalPresentationOverFullScreen;
    [host presentViewController:welcome animated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // 独立的深色界面，不受 App 当前外观模式影响，
    // 确保下方的浅色文字在渐变背景上始终清晰可见。
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    self.view.backgroundColor = UIColor.blackColor;

    [self buildBackground];

    UIScrollView *scroll = [[UIScrollView alloc] init];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.showsVerticalScrollIndicator = NO;
    [self.view addSubview:scroll];

    UIStackView *content = [[UIStackView alloc] init];
    content.axis = UILayoutConstraintAxisVertical;
    content.alignment = UIStackViewAlignmentFill;
    content.spacing = 20;
    content.translatesAutoresizingMaskIntoConstraints = NO;
    [scroll addSubview:content];

    [content addArrangedSubview:[self headerView]];
    [content setCustomSpacing:30 afterView:content.arrangedSubviews.lastObject];

    for (NSDictionary *page in [self pages]) {
        [content addArrangedSubview:[self featureRowWithImage:page[@"image"]
                                                        title:page[@"title"]
                                                  description:page[@"desc"]]];
    }

    UIView *bottom = [self bottomBar];
    [self.view addSubview:bottom];

    [NSLayoutConstraint activateConstraints:@[
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:bottom.topAnchor],

        [content.topAnchor constraintEqualToAnchor:scroll.topAnchor constant:28],
        [content.bottomAnchor constraintEqualToAnchor:scroll.bottomAnchor constant:-24],
        [content.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:kSideMargin],
        [content.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-kSideMargin],

        [bottom.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [bottom.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [bottom.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.backgroundGradient.frame = self.view.bounds;
}

#pragma mark - Background

- (void)buildBackground {
    // 深色渐变背景：顶部带有轻微的品牌色调和柔和光晕，
    // 向下逐渐过渡为黑色。
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.colors = @[
        (id)[UIColor colorWithRed:0.07 green:0.11 blue:0.20 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.02 green:0.03 blue:0.06 alpha:1.0].CGColor,
        (id)UIColor.blackColor.CGColor,
    ];
    gradient.locations = @[@0.0, @0.55, @1.0];
    [self.view.layer insertSublayer:gradient atIndex:0];
    self.backgroundGradient = gradient;
}

#pragma mark - Header

- (UIView *)headerView {
    UIStackView *row = [[UIStackView alloc] init];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 12;

    UIImage *logo = [[UIImage imageNamed:@"logo"
                               inBundle:NSBundle.fbp_resourceBundle
          compatibleWithTraitCollection:nil]
                       imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    if (logo) {
        UIImageView *logoView = [[UIImageView alloc] initWithImage:logo];
        logoView.contentMode = UIViewContentModeScaleAspectFit;
        logoView.layer.cornerRadius = 10;
        logoView.layer.cornerCurve = kCACornerCurveContinuous;
        logoView.clipsToBounds = YES;
        logoView.translatesAutoresizingMaskIntoConstraints = NO;
        [NSLayoutConstraint activateConstraints:@[
            [logoView.widthAnchor constraintEqualToConstant:kLogoSize],
            [logoView.heightAnchor constraintEqualToConstant:kLogoSize],
        ]];
        [row addArrangedSubview:logoView];
    }

    UILabel *name = [[UILabel alloc] init];
    name.text = @"Facebook Plus";
    name.font = [UIFont systemFontOfSize:30 weight:UIFontWeightBold];
    name.textColor = UIColor.labelColor;
    [row addArrangedSubview:name];

    // 将 Logo 和产品名称作为整体进行水平居中。
    UIView *wrap = [[UIView alloc] init];
    row.translatesAutoresizingMaskIntoConstraints = NO;
    [wrap addSubview:row];
    [NSLayoutConstraint activateConstraints:@[
        [row.centerXAnchor constraintEqualToAnchor:wrap.centerXAnchor],
        [row.topAnchor constraintEqualToAnchor:wrap.topAnchor],
        [row.bottomAnchor constraintEqualToAnchor:wrap.bottomAnchor],
        [row.leadingAnchor constraintGreaterThanOrEqualToAnchor:wrap.leadingAnchor],
        [row.trailingAnchor constraintLessThanOrEqualToAnchor:wrap.trailingAnchor],
    ]];
    return wrap;
}

#pragma mark - Feature rows

- (UIView *)featureRowWithImage:(NSString *)imageName
                          title:(NSString *)title
                    description:(NSString *)description {
    UIView *rowView = [[UIView alloc] init];

    UIImageView *glyph = [[UIImageView alloc] initWithImage:[UIImage fbp_imageNamed:imageName]];
    glyph.contentMode = UIViewContentModeScaleAspectFit;
    glyph.tintColor = UIColor.labelColor;
    glyph.translatesAutoresizingMaskIntoConstraints = NO;
    [rowView addSubview:glyph];

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.text = title;
    titleLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightSemibold];
    titleLabel.textColor = UIColor.labelColor;
    titleLabel.numberOfLines = 0;
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [rowView addSubview:titleLabel];

    UILabel *descLabel = [[UILabel alloc] init];
    descLabel.text = description;
    descLabel.font = [UIFont systemFontOfSize:15];
    descLabel.textColor = [UIColor.labelColor colorWithAlphaComponent:0.62];
    descLabel.numberOfLines = 0;
    descLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [rowView addSubview:descLabel];

    [NSLayoutConstraint activateConstraints:@[
        [glyph.leadingAnchor constraintEqualToAnchor:rowView.leadingAnchor],
        [glyph.widthAnchor constraintEqualToConstant:kGlyphColumn],
        [glyph.heightAnchor constraintEqualToConstant:34],
        [glyph.topAnchor constraintEqualToAnchor:rowView.topAnchor constant:3],

        [titleLabel.leadingAnchor constraintEqualToAnchor:glyph.trailingAnchor constant:10],
        [titleLabel.trailingAnchor constraintEqualToAnchor:rowView.trailingAnchor],
        [titleLabel.topAnchor constraintEqualToAnchor:rowView.topAnchor],

        [descLabel.leadingAnchor constraintEqualToAnchor:titleLabel.leadingAnchor],
        [descLabel.trailingAnchor constraintEqualToAnchor:rowView.trailingAnchor],
        [descLabel.topAnchor constraintEqualToAnchor:titleLabel.bottomAnchor constant:3],
        [descLabel.bottomAnchor constraintEqualToAnchor:rowView.bottomAnchor],
    ]];
    return rowView;
}

#pragma mark - Bottom bar

- (UIView *)bottomBar {
    UIView *bar = [[UIView alloc] init];
    bar.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.35];
    bar.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *hairline = [[UIView alloc] init];
    hairline.backgroundColor = [UIColor.labelColor colorWithAlphaComponent:0.12];
    hairline.translatesAutoresizingMaskIntoConstraints = NO;
    [bar addSubview:hairline];

    // 卡片 1：用于设置“不再显示”选项。
    UIView *toggleCard = [self cardView];
    [bar addSubview:toggleCard];

    UILabel *dontShowLabel = [[UILabel alloc] init];
    dontShowLabel.text = @"不再显示此弹窗";
    dontShowLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightMedium];
    dontShowLabel.textColor = UIColor.labelColor;
    dontShowLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [toggleCard addSubview:dontShowLabel];

    _dontShowSwitch = [[UISwitch alloc] init];
    _dontShowSwitch.onTintColor = FBPTintColor();
    _dontShowSwitch.on = NO;
    _dontShowSwitch.translatesAutoresizingMaskIntoConstraints = NO;
    [toggleCard addSubview:_dontShowSwitch];

    // 卡片 2：Telegram 和 GitHub 联系方式。
    UIView *footerCard = [self cardView];
    [bar addSubview:footerCard];

    UIButton *telegram = [self contactButtonWithImage:@"telegram"
                                                 title:@"Telegram"
                                             tintImage:NO
                                                action:@selector(openTelegram)];

    UIButton *github = [self contactButtonWithImage:@"github"
                                               title:@"GitHub"
                                           tintImage:YES
                                              action:@selector(openGitHub)];

    [footerCard addSubview:telegram];
    [footerCard addSubview:github];

    UIView *divider = [[UIView alloc] init];
    divider.backgroundColor = [UIColor.labelColor colorWithAlphaComponent:0.14];
    divider.translatesAutoresizingMaskIntoConstraints = NO;
    [footerCard addSubview:divider];

    // 主按钮。
    UIButton *continueButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [continueButton setTitle:@"开始使用" forState:UIControlStateNormal];
    continueButton.titleLabel.font = [UIFont systemFontOfSize:18 weight:UIFontWeightSemibold];

    [continueButton setTitleColor:[UIColor colorWithRed:0.04
                                                   green:0.08
                                                    blue:0.14
                                                   alpha:1.0]
                         forState:UIControlStateNormal];

    continueButton.backgroundColor = FBPTintColor();
    continueButton.layer.cornerRadius = kButtonHeight / 2.0;
    continueButton.layer.cornerCurve = kCACornerCurveContinuous;
    continueButton.translatesAutoresizingMaskIntoConstraints = NO;

    [continueButton addTarget:self
                        action:@selector(continueTapped)
              forControlEvents:UIControlEventTouchUpInside];

    [bar addSubview:continueButton];

    [NSLayoutConstraint activateConstraints:@[
        [hairline.topAnchor constraintEqualToAnchor:bar.topAnchor],
        [hairline.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor],
        [hairline.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor],
        [hairline.heightAnchor constraintEqualToConstant:1.0 / UIScreen.mainScreen.scale],

        // Toggle card.
        [toggleCard.topAnchor constraintEqualToAnchor:bar.topAnchor constant:16],
        [toggleCard.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor constant:kSideMargin],
        [toggleCard.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:-kSideMargin],
        [toggleCard.heightAnchor constraintEqualToConstant:56],

        [dontShowLabel.leadingAnchor constraintEqualToAnchor:toggleCard.leadingAnchor constant:16],
        [dontShowLabel.centerYAnchor constraintEqualToAnchor:toggleCard.centerYAnchor],

        [_dontShowSwitch.trailingAnchor constraintEqualToAnchor:toggleCard.trailingAnchor constant:-16],
        [_dontShowSwitch.centerYAnchor constraintEqualToAnchor:toggleCard.centerYAnchor],

        [_dontShowSwitch.leadingAnchor constraintGreaterThanOrEqualToAnchor:dontShowLabel.trailingAnchor constant:8],

        // Footer card.
        [footerCard.topAnchor constraintEqualToAnchor:toggleCard.bottomAnchor constant:12],
        [footerCard.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor constant:kSideMargin],
        [footerCard.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:-kSideMargin],
        [footerCard.heightAnchor constraintEqualToConstant:56],

        [telegram.leadingAnchor constraintEqualToAnchor:footerCard.leadingAnchor],
        [telegram.topAnchor constraintEqualToAnchor:footerCard.topAnchor],
        [telegram.bottomAnchor constraintEqualToAnchor:footerCard.bottomAnchor],
        [telegram.trailingAnchor constraintEqualToAnchor:footerCard.centerXAnchor],

        [github.trailingAnchor constraintEqualToAnchor:footerCard.trailingAnchor],
        [github.topAnchor constraintEqualToAnchor:footerCard.topAnchor],
        [github.bottomAnchor constraintEqualToAnchor:footerCard.bottomAnchor],
        [github.leadingAnchor constraintEqualToAnchor:footerCard.centerXAnchor],

        [divider.centerXAnchor constraintEqualToAnchor:footerCard.centerXAnchor],
        [divider.widthAnchor constraintEqualToConstant:1.0 / UIScreen.mainScreen.scale],
        [divider.topAnchor constraintEqualToAnchor:footerCard.topAnchor constant:12],
        [divider.bottomAnchor constraintEqualToAnchor:footerCard.bottomAnchor constant:-12],

        // Primary button.
        [continueButton.topAnchor constraintEqualToAnchor:footerCard.bottomAnchor constant:16],
        [continueButton.leadingAnchor constraintEqualToAnchor:bar.leadingAnchor constant:kSideMargin],
        [continueButton.trailingAnchor constraintEqualToAnchor:bar.trailingAnchor constant:-kSideMargin],
        [continueButton.heightAnchor constraintEqualToConstant:kButtonHeight],
        [continueButton.bottomAnchor constraintEqualToAnchor:bar.safeAreaLayoutGuide.bottomAnchor constant:-14],
    ]];

    return bar;
}

/// 用于将相关控件分组到独立卡片中的圆角容器。
- (UIView *)cardView {
    UIView *card = [[UIView alloc] init];
    card.backgroundColor = [UIColor.labelColor colorWithAlphaComponent:0.08];
    card.layer.cornerRadius = 16;
    card.layer.cornerCurve = kCACornerCurveContinuous;
    card.translatesAutoresizingMaskIntoConstraints = NO;
    return card;
}

- (UIButton *)contactButtonWithImage:(NSString *)imageName
                               title:(NSString *)title
                           tintImage:(BOOL)tintImage
                              action:(SEL)action {

    // 品牌图标保持原本颜色，单色图标则使用系统颜色。
    UIImage *icon = tintImage
        ? [UIImage fbp_imageNamed:imageName]
        : [[UIImage imageNamed:imageName
                     inBundle:NSBundle.fbp_resourceBundle
          compatibleWithTraitCollection:nil]
             imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];

    // 将图标缩放到适合按钮的尺寸。
    if (icon) {
        UIGraphicsImageRendererFormat *fmt = [UIGraphicsImageRendererFormat preferredFormat];
        fmt.opaque = NO;

        CGSize target = CGSizeMake(20, 20);

        UIGraphicsImageRenderer *renderer =
            [[UIGraphicsImageRenderer alloc] initWithSize:target format:fmt];

        UIImage *rendered =
            [renderer imageWithActions:^(UIGraphicsImageRendererContext *ctx) {
                [icon drawInRect:CGRectMake(0, 0, target.width, target.height)];
            }];

        icon = [rendered imageWithRenderingMode:
                tintImage ? UIImageRenderingModeAlwaysTemplate
                          : UIImageRenderingModeAlwaysOriginal];
    }

    NSDictionary *attrs = @{
        NSFontAttributeName :
            [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]
    };

    UIButton *button;

    // UIButtonConfiguration 可以更可靠地处理图标和文字布局。
    if (@available(iOS 15.0, *)) {

        UIButtonConfiguration *cfg =
            [UIButtonConfiguration plainButtonConfiguration];

        cfg.image = icon;

        cfg.attributedTitle =
            [[NSAttributedString alloc] initWithString:title
                                            attributes:attrs];

        cfg.imagePadding = 8;

        cfg.baseForegroundColor = UIColor.labelColor;

        cfg.contentInsets =
            NSDirectionalEdgeInsetsMake(0, 0, 0, 0);

        button =
            [UIButton buttonWithConfiguration:cfg
                                primaryAction:nil];

    } else {

        button = [UIButton buttonWithType:UIButtonTypeSystem];

        [button setImage:icon
                forState:UIControlStateNormal];

        [button setTitle:[@"  " stringByAppendingString:title]
                forState:UIControlStateNormal];

        [button setTitleColor:UIColor.labelColor
                     forState:UIControlStateNormal];

        button.titleLabel.font = attrs[NSFontAttributeName];
    }

    button.tintColor = UIColor.labelColor;
    button.translatesAutoresizingMaskIntoConstraints = NO;

    [button addTarget:self
               action:action
     forControlEvents:UIControlEventTouchUpInside];

    return button;
}

#pragma mark - Content

- (NSArray<NSDictionary *> *)pages {
    return @[
        @{
            @"image" : @"incognito",
            @"title" : @"悄无声息地浏览",
            @"desc"  : @"查看限时动态时不会留下已读痕迹。是否发送已读状态，由你自己决定。"
        },

        @{
            @"image" : @"alert",
            @"title" : @"防止误操作",
            @"desc"  : @"在容易误触的操作前增加确认步骤，避免不小心点出你并不想要的赞。"
        },

        @{
            @"image" : @"setting",
            @"title" : @"设置集中管理",
            @"desc"  : @"所有功能开关集中在一个页面中，每项功能都保持关闭，直到你亲自开启。"
        },

        @{
            @"image" : @"magic",
            @"title" : @"更清爽的体验",
            @"desc"  : @"减少广告和推荐内容，开启纯黑夜间模式，还可以自定义应用图标。简单调整，让界面更符合你的使用习惯。"
        },
    ];
}

#pragma mark - Actions

- (void)continueTapped {
    // 开关代表用户是否希望以后自动显示此欢迎页面：
    // 开启 = 以后不再自动显示。
    [FBPPrefs.shared setBool:self.dontShowSwitch.isOn
                      forKey:FBPKeyIntroduced];

    [FBPPrefs.shared commit];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openTelegram {
    [self openURLString:kTelegramURL];
}

- (void)openGitHub {
    [self openURLString:kGitHubURL];
}

- (void)openURLString:(NSString *)string {
    NSURL *url = [NSURL URLWithString:string];

    if (url) {
        [UIApplication.sharedApplication openURL:url
                                         options:@{}
                               completionHandler:nil];
    }
}

@end
