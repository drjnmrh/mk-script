#include "AppDelegate.h"

#if defined(PLATFORM_MACOSX)

@interface AppDelegate()

@property (weak) IBOutlet NSWindow *window;

@end


@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSNotification *)sender
{
    return YES;
}

@end

#else

@interface AppDelegate()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}

@end

#endif
