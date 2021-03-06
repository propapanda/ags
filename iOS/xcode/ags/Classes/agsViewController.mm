#import <QuartzCore/QuartzCore.h>

#import "agsViewController.h"
#import "EAGLView.h"

#import <Crashlytics/Crashlytics.h>

// From the engine
extern void startEngine(char* filename, char* directory, int loadLastSave);
extern int psp_rotation;
extern void start_skipping_cutscene();
extern void call_simulate_keypress(int keycode);
extern void check_skip_cutscene_drag(int startx, int starty, int endx, int endy);

//extern void FakeKeyPress(int keycode);

@interface agsViewController ()
@property (nonatomic, retain) EAGLContext *context;
@property (readwrite, retain) UIView *inputAccessoryView;
@property (readwrite, assign) BOOL isInPortraitOrientation;
@property (readwrite, assign) BOOL isKeyboardActive;
@property (readwrite, assign) BOOL isIPad;
@end

@implementation agsViewController

@synthesize context, inputAccessoryView, isInPortraitOrientation, isKeyboardActive, isIPad;


agsViewController* agsviewcontroller;

// J Is this an iPhone or iPad?
extern "C" bool isPhone()
{
    UIUserInterfaceIdiom idiom = UI_USER_INTERFACE_IDIOM();
    
    return (idiom==UIUserInterfaceIdiomPhone);
}


// Mouse

int mouse_button = 0;
int mouse_position_x = 0;
int mouse_position_y = 0;
int mouse_relative_position_x = 0;
int mouse_relative_position_y = 0;
int mouse_start_position_x = 0;
int mouse_start_position_y = 0;

extern "C" float ios_mouse_scaling_x; //j
extern "C" float ios_mouse_scaling_y; //j

extern "C"
{
	int ios_poll_mouse_buttons()
	{
		int temp_button = mouse_button;
		//j mouse_button = 0;
		return temp_button;
	}
    
	void ios_poll_mouse_relative(int* x, int* y)
	{
		*x = mouse_relative_position_x;
		*y = mouse_relative_position_y;
	}
    
    
	void ios_poll_mouse_absolute(int* x, int* y)
	{
		*x = mouse_position_x;
		*y = mouse_position_y;
	}
    
    //j
    void ios_set_mouse(int x, int y)
    {
        x = (float)x / ios_mouse_scaling_x; // rescale game coordinates to screen coordinates.
        y = (float)y / ios_mouse_scaling_y;
        mouse_position_x=x;
        mouse_position_y=y;
    }
}



// Keyboard


- (BOOL)canBecomeFirstResponder
{
	return YES;
}

extern "C" void fakekey(int keypress)
{
//#ifdef ALLEGRO_KEYBOARD_HANDLER
    
    call_simulate_keypress(keypress);
//#endif
}

int lastChar;

extern "C" int ios_get_last_keypress()
{
	int result = lastChar; 
	lastChar = 0;
	return result;
}

extern "C" void ios_show_keyboard()
{
	if (agsviewcontroller)
		[agsviewcontroller performSelectorOnMainThread:@selector(showKeyboard) withObject:nil waitUntilDone:YES];
}

extern "C" void ios_hide_keyboard()
{
	if (agsviewcontroller)
		[agsviewcontroller performSelectorOnMainThread:@selector(hideKeyboard) withObject:nil waitUntilDone:YES];
}

extern "C" int ios_is_keyboard_visible()
{
	return (agsviewcontroller.isKeyboardActive ? 1 : 0);
}

- (void)showKeyboard
{
    //[[Crashlytics sharedInstance] crash]; // j ono a bug
    //int *x = NULL; *x = 42; // j ono a bug
    //[NSObject doesNotRecognizeSelector]; // j ono an exception
	if (!self.isKeyboardActive)
	{
		[self becomeFirstResponder];
        
		if (self.isInPortraitOrientation)
			[self moveViewAnimated:YES duration:0.25];
        
		self.isKeyboardActive = TRUE;
	}
}

- (void)hideKeyboard
{
	if (self.isKeyboardActive)
	{
		[self resignFirstResponder];
        
		if (self.isInPortraitOrientation)
			[self moveViewAnimated:NO duration:0.25];
		
		self.isKeyboardActive = FALSE;
	}
}

- (BOOL)hasText
{
	return NO;
}

- (void)insertText:(NSString *)theText
{
	const char* text = [theText cStringUsingEncoding:NSASCIIStringEncoding];
	if (text)
		lastChar = text[0];
}

- (void)deleteBackward
{
	lastChar = 8; // Backspace
}


- (void)createKeyboardButtonBar:(int)openedKeylist
{
	UIToolbar *toolbar;
	BOOL alreadyExists = (self.inputAccessoryView != NULL);
    
    //J Make bar height bigger on iPad 
    int buttonBarHeight=40;
    
    if (isIPad){
        buttonBarHeight=80;
    }
	
	if (alreadyExists)
		toolbar = self.inputAccessoryView;
	else
		toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, buttonBarHeight)];
    
	toolbar.barStyle = UIBarStyleBlackTranslucent;
    
	NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:6];
	
    //J Don't need f keys
	UIBarButtonItem *esc = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(buttonClicked:)]; //J
    
	[array addObject:esc];
	
    /*
	if ((openedKeylist == 1) || self.isIPad)
	{
		UIBarButtonItem* f1 = [[UIBarButtonItem alloc] initWithTitle:@"F1" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		UIBarButtonItem* f2 = [[UIBarButtonItem alloc] initWithTitle:@"F2" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		UIBarButtonItem* f3 = [[UIBarButtonItem alloc] initWithTitle:@"F3" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		UIBarButtonItem* f4 = [[UIBarButtonItem alloc] initWithTitle:@"F4" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		[array addObject:f1];
		[array addObject:f2];
		[array addObject:f3];
		[array addObject:f4];
	}
	else
	{
		UIBarButtonItem* openf1 = [[UIBarButtonItem alloc] initWithTitle:@"F1..." style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		[array addObject:openf1];
	}
    
	if ((openedKeylist == 5) || self.isIPad)
	{
		UIBarButtonItem* f5 = [[UIBarButtonItem alloc] initWithTitle:@"F5" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		UIBarButtonItem* f6 = [[UIBarButtonItem alloc] initWithTitle:@"F6" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		UIBarButtonItem* f7 = [[UIBarButtonItem alloc] initWithTitle:@"F7" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		UIBarButtonItem* f8 = [[UIBarButtonItem alloc] initWithTitle:@"F8" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		[array addObject:f5];
		[array addObject:f6];
		[array addObject:f7];
		[array addObject:f8];
	}
	else
	{
		UIBarButtonItem* openf5 = [[UIBarButtonItem alloc] initWithTitle:@"F5..." style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		[array addObject:openf5];
	}
	
	if ((openedKeylist == 9) || self.isIPad)
	{
		UIBarButtonItem* f9 = [[UIBarButtonItem alloc] initWithTitle:@"F9" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		UIBarButtonItem* f10 = [[UIBarButtonItem alloc] initWithTitle:@"F10" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		UIBarButtonItem* f11 = [[UIBarButtonItem alloc] initWithTitle:@"F11" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		UIBarButtonItem* f12 = [[UIBarButtonItem alloc] initWithTitle:@"F12" style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		[array addObject:f9];
		[array addObject:f10];
		[array addObject:f11];
		[array addObject:f12];
	}
	else
	{
		UIBarButtonItem* openf9 = [[UIBarButtonItem alloc] initWithTitle:@"F9..." style:UIBarButtonItemStyleBordered target:self action:@selector(buttonClicked:)];
		[array addObject:openf9];
	}*/
    
	[toolbar setItems:array animated:YES];
    
	if (!alreadyExists)
	{
		self.inputAccessoryView = toolbar;
		[toolbar release];
	}
    
    [array release];
}


- (IBAction)buttonClicked:(UIBarButtonItem *)sender
{
	if (sender.title == @"Cancel")
		lastChar = 27;
	else if (sender.title == @"F1")
		lastChar = 0x1000 + 47;
	else if (sender.title == @"F2")
		lastChar = 0x1000 + 48;
	else if (sender.title == @"F3")
		lastChar = 0x1000 + 49;
	else if (sender.title == @"F4")
		lastChar = 0x1000 + 50;
	else if (sender.title == @"F5")
		lastChar = 0x1000 + 51;
	else if (sender.title == @"F6")
		lastChar = 0x1000 + 52;
	else if (sender.title == @"F7")
		lastChar = 0x1000 + 53;
	else if (sender.title == @"F8")
		lastChar = 0x1000 + 54;
	else if (sender.title == @"F9")
		lastChar = 0x1000 + 55;
	else if (sender.title == @"F10")
		lastChar = 0x1000 + 56;
	else if (sender.title == @"F11")
		lastChar = 0x1000 + 57;
	else if (sender.title == @"F12")
		lastChar = 0x1000 + 58;
	else if (sender.title == @"F1...")
		[self createKeyboardButtonBar:1];
	else if (sender.title == @"F5...")
		[self createKeyboardButtonBar:5];
	else if (sender.title == @"F9...")
		[self createKeyboardButtonBar:9];
}



// Touching
/*
 
 - (IBAction)handleSingleFingerTap:(UIGestureRecognizer *)sender
 {
 mouse_button = 1;
 }
 
 - (IBAction)handleTwoFingerTap:(UIGestureRecognizer *)sender
 {
 mouse_button = 2;
 }
 */

- (void)moveViewAnimated:(BOOL)upwards duration:(float)duration
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:duration];
	
	int newTop = 0;
	if (upwards)
	{
		if (self.isIPad)
			newTop = self.view.frame.size.height / -6;
		else
			newTop = self.view.frame.size.height / -4;
	}
    
	self.view.frame = CGRectMake(0, newTop, self.view.frame.size.width, self.view.frame.size.height);
	[UIView commitAnimations];
}
/*
- (IBAction)handleLongPress:(UIGestureRecognizer *)sender
{
    if (sender.state != UIGestureRecognizerStateBegan)
        return;
    
    start_skipping_cutscene();
}*/

/*- (IBAction)handleSwipe:(UISwipeGestureRecognizer *)sender
{
    if (sender.state != UIGestureRecognizerStateEnded)
        return;
    
    CGPoint point = [sender locationInView:[self view]];
    //NSLog(@"Swipe down - start location: %f,%f", point.x, point.y);
    //int dist_x = mouse_position_x-point.x;
    //int dist_y = mouse_position_y-point.y;
    
    start_skipping_cutscene();
}*/

/*
 - (IBAction)handleLongPress:(UIGestureRecognizer *)sender
 {
 if (sender.state != UIGestureRecognizerStateBegan)
 return;
 
 if (self.isKeyboardActive)
 {
 [self resignFirstResponder];
 
 if (self.isInPortraitOrientation)
 [self moveViewAnimated:NO duration:0.25];
 }
 else
 {
 [self becomeFirstResponder];
 if (self.isInPortraitOrientation)
 [self moveViewAnimated:YES duration:0.25];
 }
 
 self.isKeyboardActive = !self.isKeyboardActive;
 }
 
 - (IBAction)handleShortLongPress:(UIGestureRecognizer *)sender
 {
 if (sender.state != UIGestureRecognizerStateBegan)
 return;
 
 mouse_button = 10;
 }*/

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
	UITouch* touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self.view];
	mouse_position_x = touchPoint.x;
	mouse_position_y = touchPoint.y;
    mouse_button=1;
}

-(void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
	UITouch* touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self.view];
	mouse_position_x = touchPoint.x;
	mouse_position_y = touchPoint.y;
	mouse_start_position_x = touchPoint.x;
	mouse_start_position_y = touchPoint.y;
    
    mouse_button=1;
}

-(void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
	UITouch* touch = [touches anyObject];
	CGPoint touchPoint = [touch locationInView:self.view];
	mouse_position_x = touchPoint.x;
	mouse_position_y = touchPoint.y;
    mouse_button=0;
    
    // Check skip cutscene
   
    check_skip_cutscene_drag(mouse_start_position_x, mouse_start_position_y, mouse_position_x, mouse_position_y);
 
    
}

- (void)createGestureRecognizers
{
	/*UITapGestureRecognizer* singleFingerTap = [[UITapGestureRecognizer alloc]
     initWithTarget:self action:@selector(handleSingleFingerTap:)];
     singleFingerTap.numberOfTapsRequired = 1;
     singleFingerTap.numberOfTouchesRequired = 1;
     [self.view addGestureRecognizer:singleFingerTap];
     [singleFingerTap release];
     
     UITapGestureRecognizer* twoFingerTap = [[UITapGestureRecognizer alloc]
     initWithTarget:self action:@selector(handleTwoFingerTap:)];
     twoFingerTap.numberOfTapsRequired = 1;
     twoFingerTap.numberOfTouchesRequired = 2;
     [self.view addGestureRecognizer:twoFingerTap];
     [twoFingerTap release];
     
     UILongPressGestureRecognizer* longPressGesture = [[UILongPressGestureRecognizer alloc]
     initWithTarget:self action:@selector(handleLongPress:)];
     longPressGesture.minimumPressDuration = 1.5;
     [self.view addGestureRecognizer:longPressGesture];
     [longPressGesture release];
     
     UILongPressGestureRecognizer* shortLongPressGesture = [[UILongPressGestureRecognizer alloc]
     initWithTarget:self action:@selector(handleShortLongPress:)];
     shortLongPressGesture.minimumPressDuration = 0.7;
     [shortLongPressGesture requireGestureRecognizerToFail:longPressGesture];
     [self.view addGestureRecognizer:shortLongPressGesture];
     [shortLongPressGesture release];*/
    
    /*UILongPressGestureRecognizer* longPressGesture = [[UILongPressGestureRecognizer alloc]
    initWithTarget:self action:@selector(handleLongPress:)];
    longPressGesture.minimumPressDuration = 3;
    [self.view addGestureRecognizer:longPressGesture];
    [longPressGesture release];*/
    
    /*UISwipeGestureRecognizer* swipeGesture = [[UISwipeGestureRecognizer alloc]
    initWithTarget:self action:@selector(handleSwipe:)];
    [swipeGesture setDirection:UISwipeGestureRecognizerDirectionRight];
    [self.view addGestureRecognizer:swipeGesture];
    [swipeGesture release];*/
}






- (void)showActivityIndicator
{
	UIActivityIndicatorView* indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	[indicatorView startAnimating];
	indicatorView.center = self.view.center;
	indicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	[self.view addSubview:indicatorView];
	[indicatorView release];
}

- (void)hideActivityIndicator
{
	NSArray *subviews = [self.view subviews];
	for (UIView *view in subviews)
		[view removeFromSuperview];
}


extern "C" void ios_create_screen()
{
	[agsviewcontroller performSelectorOnMainThread:@selector(hideActivityIndicator) withObject:nil waitUntilDone:YES];
}



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
	[self showActivityIndicator];
    
	[super viewDidLoad];
	[self.view setMultipleTouchEnabled:YES];
	[self createGestureRecognizers];
	agsviewcontroller = self;
	self.isIPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	// Return YES for supported orientations
	if (psp_rotation == 0)
		return YES;
	else if (psp_rotation == 1)
		return UIInterfaceOrientationIsPortrait(interfaceOrientation);
	else if (psp_rotation == 2)
		return UIInterfaceOrientationIsLandscape(interfaceOrientation);
    
    return YES;
}


//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	self.isInPortraitOrientation = !UIInterfaceOrientationIsLandscape(agsviewcontroller.interfaceOrientation);
	if (self.isKeyboardActive && self.isInPortraitOrientation)
		[self moveViewAnimated:YES duration:0.1];
}

// J For ios 6.0 and above
-(NSInteger)supportedInterfaceOrientations{
    if (psp_rotation == 0)
		return UIInterfaceOrientationMaskAllButUpsideDown;
	else if (psp_rotation == 1)
		return UIInterfaceOrientationMaskPortrait;
	else if (psp_rotation == 2)
		return UIInterfaceOrientationMaskLandscape;
    
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

// J For ios 6.0 and above
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    if (psp_rotation == 0)
		return UIInterfaceOrientationMaskAllButUpsideDown;
	else if (psp_rotation == 1)
		return UIInterfaceOrientationMaskPortrait;
	else if (psp_rotation == 2)
		return UIInterfaceOrientationMaskLandscape;
    
    return UIInterfaceOrientationMaskAllButUpsideDown;
}


- (void)awakeFromNib
{
	EAGLContext* aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
	
	if (!aContext)
		NSLog(@"Failed to create ES context");
	else if (![EAGLContext setCurrentContext:aContext])
		NSLog(@"Failed to set ES context current");
	
	self.context = aContext;
	[aContext release];
	
	[(EAGLView *)self.view setContext:context];
	[(EAGLView *)self.view setFramebuffer];
	
	self.isKeyboardActive = FALSE;
	self.isInPortraitOrientation = !UIInterfaceOrientationIsLandscape(agsviewcontroller.interfaceOrientation);
 
	[self createKeyboardButtonBar:1];
	
	[NSThread detachNewThreadSelector:@selector(startThread) toTarget:self withObject:nil];
}
// this should not use a plain path todo
- (void)startThread
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
	// Handle any foreground procedures not related to animation here.
	NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentPath = [searchPaths objectAtIndex:0];
	
	const char* bla = [documentPath UTF8String];
	char path[300];
	strcpy(path, bla);
	//strcat(path, "/game/");// /ags/game/
    
    /*char path[300];
     NSString * resourceStr = [[[NSBundle mainBundle] resourcePath] stringByDeletingLastPathComponent];
     const char * resourceChars = [resourceStr UTF8String];
     
     strcpy(path, resourceChars);
     strcat(path, "/game/");*/
    
    char filename[300];
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"ac2game"
                                                         ofType:@"dat"];
    //inDirectory:@"game"];
    const char * resourceChars = [filePath UTF8String];
	strcpy(filename, resourceChars);
    
	/*NSString * pathn = [filePath stringByDeletingLastPathComponent];
     const char * pathc = [pathn UTF8String];
     char path[300];
     strcpy(path, pathc);
     
     
     strcat(filename, "ac2game.dat");*/
	
	startEngine(filename, path, 0);
    
	[pool release];
}


extern volatile int ios_wait_for_ui;

void ios_show_message_box(char* buffer)
{
	NSString* string = [[NSString alloc] initWithUTF8String: buffer];
	[agsviewcontroller performSelectorOnMainThread:@selector(showMessageBox:) withObject:string waitUntilDone:YES];
}

- (void)showMessageBox:(NSString*)text
{
	ios_wait_for_ui = 1;
	UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"Error" message:text delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[message show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    ios_wait_for_ui = 0;
}

- (void)dealloc
{
	if ([EAGLContext currentContext] == context)
		[EAGLContext setCurrentContext:nil];
	
	[context release];
	
	[super dealloc];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidUnload
{
	[super viewDidUnload];
    
	// Tear down context.
	if ([EAGLContext currentContext] == context)
		[EAGLContext setCurrentContext:nil];
	self.context = nil;
}

- (void)didReceiveMemoryWarning
{
	// Releases the view if it doesn't have a superview.
	[super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc. that aren't in use.
}


@end