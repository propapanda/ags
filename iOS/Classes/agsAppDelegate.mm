#import "agsAppDelegate.h"
#import "agsViewController.h"


@implementation agsAppDelegate

@synthesize window;
@synthesize viewController;

volatile int is_in_foreground = 1;
volatile int drawing_in_progress = 0;

extern "C" void ios_resume_sound();
extern "C" volatile int ios_audio_must_restart;//jg

extern "C" void logdebugc(const char *message);
extern "C" void logdebugc_int(const char *message, int num);
extern "C" void logdebugc_str(const char *message, const char *extra);


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    logdebugc("JGS didFinishLaunchingWithOptions");
    
	[[UIApplication sharedApplication] setIdleTimerDisabled:YES];
	//self.window.rootViewController = self.viewController;
    //self.window.rootViewController = self.viewController;
   // [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    logdebugc("JGS applicationWillResignActive is_in_foreground = 0");
	//is_in_foreground = 0;
	do
	{
		//printf("waiting for drawing to finish %d...\n", drawing_in_progress);
		usleep(1000 * 100);
	}
	while (drawing_in_progress);
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    logdebugc("JGS applicationDidBecomeActive is_in_foreground = 1");
    
	is_in_foreground = 1;
    ios_audio_must_restart = 1;//jg
    usleep(1000 * 1000); //jg Crude hack to try and make the audio start up after answering a phone call.
	ios_resume_sound();
}

- (void)applicationWillTerminate:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Handle any background procedures not related to animation here.
    logdebugc("JGS applicationDidEnterBackground is_in_foreground = 0");
	is_in_foreground = 0;
	while (drawing_in_progress)
	{
		//printf("waiting for drawing to finish (background) %d...\n", drawing_in_progress);
		usleep(1000 * 100);
	};
	glFinish();
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Handle any foreground procedures not related to animation here.
    logdebugc("JGS applicationWillEnterForeground is_in_foreground = 1");
	is_in_foreground = 1;
}

- (void)dealloc
{
	[viewController release];
	[window release];
	
	[super dealloc];
}

@end
