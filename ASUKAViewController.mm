#import "asuka4scape.h"

@interface ASUKAAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic) UIWindow *window;
@end

@interface ASUKAViewController : UIViewController
@property (strong, nonatomic) UITextView *logView;
@property (strong, nonatomic) UIButton *jbButton;
@property (strong, nonatomic) UIButton *restoreButton;
@property (strong, nonatomic) UIButton *respButton;
@property (strong, nonatomic) ASUKAExploit *exploit;
@end

@implementation ASUKAAppDelegate
- (BOOL)application:(UIApplication *)application
 didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = [[ASUKAViewController alloc] init];
    self.window.backgroundColor = ASUKA_BLACK;
    [self.window makeKeyAndVisible];
    return YES;
}
@end

@implementation ASUKAViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = ASUKA_DARK_BG;
    self.title = @"asuka4scape";
    self.exploit = [[ASUKAExploit alloc] init];
    __weak typeof(self) weakSelf = self;
    self.exploit.logCallback = ^(NSString *log) {
        weakSelf.logView.text = log;
        NSRange bottom = NSMakeRange(log.length - 1, 1);
        [weakSelf.logView scrollRangeToVisible:bottom];
    };
    [self setupUI];
}

- (void)setupUI {
    CGRect screen = self.view.bounds;
    UILabel *title = [[UILabel alloc] init];
    title.text = @"asuka4scape";
    title.font = [UIFont fontWithName:@"Menlo" size:28];
    title.textColor = ASUKA_PURPLE;
    title.textAlignment = NSTextAlignmentCenter;
    title.frame = CGRectMake(20, 60, screen.size.width - 40, 40);
    [self.view addSubview:title];
    UILabel *subtitle = [[UILabel alloc] init];
    subtitle.text = @"iOS 27 beta 6 - iPhone 14";
    subtitle.font = [UIFont fontWithName:@"Menlo" size:12];
    subtitle.textColor = ASUKA_ORANGE;
    subtitle.textAlignment = NSTextAlignmentCenter;
    subtitle.frame = CGRectMake(20, 100, screen.size.width - 40, 20);
    [self.view addSubview:subtitle];
    self.logView = [[UITextView alloc] init];
    self.logView.backgroundColor = ASUKA_BLACK;
    self.logView.textColor = ASUKA_GREEN;
    self.logView.font = [UIFont fontWithName:@"Menlo" size:10];
    self.logView.editable = NO;
    self.logView.frame = CGRectMake(10, 140, screen.size.width - 20, screen.size.height - 280);
    self.logView.layer.borderColor = ASUKA_PURPLE.CGColor;
    self.logView.layer.borderWidth = 1;
    self.logView.layer.cornerRadius = 8;
    [self.view addSubview:self.logView];
    self.jbButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.jbButton setTitle:@"JAILBREAK" forState:UIControlStateNormal];
    self.jbButton.titleLabel.font = [UIFont fontWithName:@"Menlo" size:18];
    [self.jbButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.jbButton.backgroundColor = ASUKA_RED;
    self.jbButton.frame = CGRectMake(20, screen.size.height - 120, (screen.size.width - 60) / 2, 40);
    self.jbButton.layer.cornerRadius = 8;
    [self.jbButton addTarget:self action:@selector(jbPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.jbButton];
    self.respButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.respButton setTitle:@"RESPRING" forState:UIControlStateNormal];
    self.respButton.titleLabel.font = [UIFont fontWithName:@"Menlo" size:18];
    [self.respButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.respButton.backgroundColor = ASUKA_PURPLE;
    self.respButton.frame = CGRectMake(40 + (screen.size.width - 60) / 2, screen.size.height - 120, (screen.size.width - 60) / 2, 40);
    self.respButton.layer.cornerRadius = 8;
    [self.respButton addTarget:self action:@selector(respPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.respButton];
    self.restoreButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.restoreButton setTitle:@"RESTORE" forState:UIControlStateNormal];
    self.restoreButton.titleLabel.font = [UIFont fontWithName:@"Menlo" size:14];
    [self.restoreButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.restoreButton.backgroundColor = ASUKA_ORANGE;
    self.restoreButton.frame = CGRectMake(20, screen.size.height - 70, screen.size.width - 40, 40);
    self.restoreButton.layer.cornerRadius = 8;
    [self.restoreButton addTarget:self action:@selector(restorePressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.restoreButton];
}

- (void)jbPressed { [self.exploit runFullChain]; }
- (void)respPressed { [self.exploit appendLog:@"[!] Respringing..."]; }
- (void)restorePressed { [self.exploit appendLog:@"[!] Restore not implemented"]; }

@end
