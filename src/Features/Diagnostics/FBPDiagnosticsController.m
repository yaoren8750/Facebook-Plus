// Settings → Diagnostics.
//
// Facebook loads most of its frameworks on demand, so which of the tweak's hooks
// are live depends on where the user has been. On a sideloaded build there is no
// console and no debugger, so this screen is the only way to answer "why isn't
// the button showing" without guessing.

#import "FBPDiagnosticsController.h"
#import "FBPDiagnostics.h"
#import "FBPResources.h"
#import "FBPToast.h"

static NSString *const kCellIdentifier = @"fbp.diagnostics.row";

@interface FBPDiagnosticsController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray<NSDictionary<NSString *, NSString *> *> *groups;
@property (nonatomic, copy) NSArray<NSString *> *events;
@property (nonatomic, weak) UIToolbar *toolbarView;
@end

@implementation FBPDiagnosticsController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = FBPL(@"diagnostics.title");
    self.view.backgroundColor = UIColor.systemBackgroundColor;
    self.view.tintColor = FBPTintColor();

    self.navigationItem.rightBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                      target:self
                                                      action:@selector(shareReport:)];
    self.navigationItem.leftBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:FBPL(@"diagnostics.close")
                                          style:UIBarButtonItemStylePlain
                                         target:self
                                         action:@selector(close)];

    // Two actions the user can take from here, both of which change what the
    // next export contains.
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.translatesAutoresizingMaskIntoConstraints = NO;
    toolbar.items = @[
        [[UIBarButtonItem alloc] initWithTitle:FBPL(@"diagnostics.captureScreen")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(captureScreen)],
        [[UIBarButtonItem alloc]
            initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                 target:nil
                                 action:nil],
        [[UIBarButtonItem alloc] initWithTitle:FBPL(@"diagnostics.clearLog")
                                         style:UIBarButtonItemStylePlain
                                        target:self
                                        action:@selector(clearLog)],
    ];
    [self.view addSubview:toolbar];
    self.toolbarView = toolbar;

    _tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                              style:UITableViewStyleInsetGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.estimatedRowHeight = 56.0;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [_tableView registerClass:UITableViewCell.class
       forCellReuseIdentifier:kCellIdentifier];
    [self.view addSubview:_tableView];

    [NSLayoutConstraint activateConstraints:@[
        [_tableView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [_tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [_tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [_tableView.bottomAnchor constraintEqualToAnchor:self.toolbarView.topAnchor],

        [self.toolbarView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.toolbarView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.toolbarView.bottomAnchor
            constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    // Re-read on every appearance: a framework loaded since last time changes
    // the answer, and that change is often the whole diagnosis.
    self.groups = FBPDiagnostics.shared.groupReport;
    self.events = FBPDiagnostics.shared.eventLog;
    [self.tableView reloadData];
}

/// Exports the whole session as a .txt through the share sheet.
///
/// A file rather than a string: these logs run to thousands of lines once a
/// view tree is in them, and most share targets truncate raw text.
- (void)shareReport:(UIBarButtonItem *)sender {
    NSURL *file = [FBPDiagnostics.shared exportToFile];
    NSArray *items = file ? @[file] : @[FBPDiagnostics.shared.report];

    // Also on the clipboard, so a quick paste works without picking a target.
    UIPasteboard.generalPasteboard.string = FBPDiagnostics.shared.report;

    UIActivityViewController *share =
        [[UIActivityViewController alloc] initWithActivityItems:items
                                          applicationActivities:nil];
    share.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:share animated:YES completion:nil];
}

/// Dumps whatever is on screen behind this sheet.
///
/// The controller has to get out of the way first, or the only thing captured
/// is the diagnostics screen itself.
#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section {

    if (section == 0) {
        return (NSInteger)self.groups.count;
    }

    return (NSInteger)MAX(self.events.count, (NSUInteger)1);
}

- (NSString *)tableView:(UITableView *)tableView
 titleForHeaderInSection:(NSInteger)section {

    return section == 0
        ? FBPL(@"diagnostics.hooks")
        : FBPL(@"diagnostics.events");
}

- (NSString *)tableView:(UITableView *)tableView
 titleForFooterInSection:(NSInteger)section {

    return section == 0
        ? FBPL(@"diagnostics.footer")
        : nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kCellIdentifier
                                        forIndexPath:indexPath];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.numberOfLines = 0;
    cell.detailTextLabel.numberOfLines = 0;

    if (indexPath.section == 0) {

        NSDictionary *row = self.groups[indexPath.row];

        cell.textLabel.text = row[@"title"];
        cell.textLabel.font = FBPFont(15, UIFontWeightMedium);
        cell.detailTextLabel.text = row[@"detail"];

    } else {

        cell.textLabel.text =
            self.events.count
                ? self.events[indexPath.row]
                : FBPL(@"diagnostics.empty");

        cell.textLabel.font =
            [UIFont monospacedSystemFontOfSize:12
                                        weight:UIFontWeightRegular];

        cell.detailTextLabel.text = nil;
    }

    return cell;
}

@end
