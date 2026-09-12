#import "asuka4scape.h"

@interface ASUKAAppDelegate : UIResponder <UIApplicationDelegate>
@end

@interface ASUKAViewController : UIViewController
@end

int main(int argc, char *argv[]) {
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil,
            NSStringFromClass([ASUKAAppDelegate class]));
    }
}