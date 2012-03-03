//
//  MGSplitViewAppDelegate.m
//  MGSplitView
//
//  Created by Matt Gemmell on 26/07/2010.
//  Copyright Instinctive Code 2010.
//

#import "MGSplitViewAppDelegate.h"
#import "RootViewController.h"
#import "DetailViewController.h"
#import "MGSplitViewController.h"

@interface MGSplitViewAppDelegate ()

@property (nonatomic, strong) MGSplitViewController *splitViewController;
@property (nonatomic, strong) RootViewController *rootViewController;
@property (nonatomic, strong) DetailViewController *detailViewController;

@end

@implementation MGSplitViewAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Add the split view controller's view to the window and display.
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    MGSplitViewController *splitViewController = [[MGSplitViewController alloc] init];
    RootViewController *rootViewController = [[RootViewController alloc] init];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:rootViewController];
    DetailViewController *detailViewController = [[DetailViewController alloc] initWithNibName:@"DetailView" bundle:nil];
    [splitViewController setViewControllers:[NSArray arrayWithObjects:navigationController, detailViewController, nil]];
    [detailViewController setSplitController:splitViewController];
    [self setSplitViewController:splitViewController];
    [splitViewController setDelegate:detailViewController];
    [self setRootViewController:rootViewController];
    [self setDetailViewController:detailViewController];
    
    [self.window setRootViewController:self.splitViewController];
    [self.window makeKeyAndVisible];
	
	[self.rootViewController performSelector:@selector(selectFirstRow) withObject:nil afterDelay:0];
	[self.detailViewController performSelector:@selector(configureView) withObject:nil afterDelay:0];
	
	if (NO) { // whether to allow dragging the divider to move the split.
		self.splitViewController.splitWidth = 15.0; // make it wide enough to actually drag!
		self.splitViewController.allowsDraggingDivider = YES;
	}
	
    return YES;
}

@synthesize splitViewController = _splitViewController;
@synthesize rootViewController = _rootViewController;
@synthesize detailViewController = _detailViewController;
@synthesize window = _window;

@end

