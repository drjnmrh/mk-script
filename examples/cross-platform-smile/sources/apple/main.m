#if defined(PLATFORM_MACOSX)
#   import "Cocoa/Cocoa.h"
#else
#   import <UIKit/UIKit.h>
#   include "AppDelegate.h"
#endif
int main(int argc, char* argv[]) {
    @autoreleasepool {
#if defined(PLATFORM_MACOSX)
        return NSApplicationMain(argc, (const char**)argv);
#else
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
#endif
    }
}

