//
//  MGSplitViewController.m
//  MGSplitView
//
//  Created by Matt Gemmell on 26/07/2010.
//  Copyright 2010 Instinctive Code.
//

#import "MGSplitViewController.h"
#import "MGSplitDividerView.h"
#import "MGSplitCornersView.h"
#import "MGSplitCornersView+protectedMethods.h"

#define MG_DEFAULT_SPLIT_POSITION		320.0	// default width of master view in UISplitViewController.
#define MG_DEFAULT_SPLIT_WIDTH			1.0		// default width of split-gutter in UISplitViewController.
#define MG_DEFAULT_CORNER_RADIUS		5.0		// default corner-radius of overlapping split-inner corners on the master and detail views.
#define MG_DEFAULT_CORNER_COLOR			[UIColor blackColor]	// default color of intruding inner corners (and divider background).

#define MG_PANESPLITTER_CORNER_RADIUS	0.0		// corner-radius of split-inner corners for MGSplitViewDividerStylePaneSplitter style.
#define MG_PANESPLITTER_SPLIT_WIDTH		25.0	// width of split-gutter for MGSplitViewDividerStylePaneSplitter style.

#define MG_MIN_VIEW_WIDTH				200.0	// minimum width a view is allowed to become as a result of changing the splitPosition.

#define MG_ANIMATION_CHANGE_SPLIT_ORIENTATION	@"ChangeSplitOrientation"	// Animation ID for internal use.
#define MG_ANIMATION_CHANGE_SUBVIEWS_ORDER		@"ChangeSubviewsOrder"	// Animation ID for internal use.


@interface MGSplitViewController () <UIPopoverControllerDelegate> {
    //	BOOL _showsMasterInPortrait;
    //	BOOL _showsMasterInLandscape;
    //	float _splitWidth;
    //	id _delegate;
    //	BOOL _vertical;
    //	BOOL _masterBeforeDetail;
    NSMutableArray *_viewControllers;
	UIBarButtonItem *_barButtonItem; // To be compliant with wacky UISplitViewController behaviour.
    UIPopoverController *_privateHiddenPopoverController; // Popover used to hold the master view if it's not always visible.
    //	MGSplitDividerView *_dividerView; // View that draws the divider between the master and detail views.
    //	NSArray *_cornerViews; // Views to draw the inner rounded corners between master and detail views.
    //	float _splitPosition;
	BOOL _reconfigurePopup;
    //	MGSplitViewDividerStyle _dividerStyle; // Meta-setting which configures several aspects of appearance and behaviour.
}

@property(nonatomic, readwrite, strong)NSArray *cornerViews;

- (void)setup;
- (CGSize)splitViewSizeForOrientation:(UIInterfaceOrientation)theOrientation;
- (void)layoutSubviews;
- (void)layoutSubviewsWithAnimation:(BOOL)animate;
- (void)layoutSubviewsForInterfaceOrientation:(UIInterfaceOrientation)theOrientation withAnimation:(BOOL)animate;
- (BOOL)shouldShowMasterForInterfaceOrientation:(UIInterfaceOrientation)theOrientation;
- (BOOL)shouldShowMaster;
- (NSString *)nameOfInterfaceOrientation:(UIInterfaceOrientation)theOrientation;
- (void)reconfigureForMasterInPopover:(BOOL)inPopover;

@end


@implementation MGSplitViewController


#pragma mark -
#pragma mark Orientation helpers


- (NSString *)nameOfInterfaceOrientation:(UIInterfaceOrientation)theOrientation
{
	NSString *orientationName = nil;
	switch (theOrientation) {
		case UIInterfaceOrientationPortrait:
			orientationName = @"Portrait"; // Home button at bottom
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			orientationName = @"Portrait (Upside Down)"; // Home button at top
			break;
		case UIInterfaceOrientationLandscapeLeft:
			orientationName = @"Landscape (Left)"; // Home button on left
			break;
		case UIInterfaceOrientationLandscapeRight:
			orientationName = @"Landscape (Right)"; // Home button on right
			break;
		default:
			break;
	}
	
	return orientationName;
}


- (BOOL)isLandscape
{
	return UIInterfaceOrientationIsLandscape(self.interfaceOrientation);
}


- (BOOL)shouldShowMasterForInterfaceOrientation:(UIInterfaceOrientation)theOrientation
{
	// Returns YES if master view should be shown directly embedded in the splitview, instead of hidden in a popover.
	return ((UIInterfaceOrientationIsLandscape(theOrientation)) ? self.showsMasterInLandscape : self.showsMasterInPortrait);
}


- (BOOL)shouldShowMaster
{
	return [self shouldShowMasterForInterfaceOrientation:self.interfaceOrientation];
}


- (BOOL)isShowingMaster
{
	return [self shouldShowMaster] && self.masterViewController && self.masterViewController.view && ([self.masterViewController.view superview] == self.view);
}


#pragma mark -
#pragma mark Setup and Teardown


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		[self setup];
	}
	
	return self;
}


- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder:aDecoder])) {
		[self setup];
	}
	
	return self;
}


- (void)setup
{
	// Configure default behaviour.
	self.viewControllers = [[NSMutableArray alloc] initWithObjects:[NSNull null], [NSNull null], nil];
	self.splitWidth = MG_DEFAULT_SPLIT_WIDTH;
	self.showsMasterInPortrait = NO;
	self.showsMasterInLandscape = YES;
	_reconfigurePopup = NO;
	self.vertical = YES;
	self.masterBeforeDetail = YES;
	self.splitPosition = MG_DEFAULT_SPLIT_POSITION;
	CGRect divRect = self.view.bounds;
	if ([self isVertical]) {
		divRect.origin.y = self.splitPosition;
		divRect.size.height = self.splitWidth;
	} else {
		divRect.origin.x = self.splitPosition;
		divRect.size.width = self.splitWidth;
	}
	self.dividerView = [[MGSplitDividerView alloc] initWithFrame:divRect];
	self.dividerView.splitViewController = self;
	self.dividerView.backgroundColor = MG_DEFAULT_CORNER_COLOR;
	self.dividerStyle = MGSplitViewDividerStyleThin;
}


- (void)dealloc
{
	self.delegate = nil;
	[self.view.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}


#pragma mark -
#pragma mark View management

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //Default to landscape only
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.masterViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.detailViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.masterViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self.detailViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}


- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation 
										 duration:(NSTimeInterval)duration
{
	[self.masterViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.detailViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	
	// Hide popover.
	if (_privateHiddenPopoverController && _privateHiddenPopoverController.popoverVisible) {
		[_privateHiddenPopoverController dismissPopoverAnimated:NO];
	}
	
	// Re-tile views.
	_reconfigurePopup = YES;
	[self layoutSubviewsForInterfaceOrientation:toInterfaceOrientation withAnimation:YES];
}


- (void)willAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.masterViewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
	[self.detailViewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}


- (void)didAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	[self.masterViewController didAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation];
	[self.detailViewController didAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation];
}


- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation duration:(NSTimeInterval)duration
{
	[self.masterViewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
	[self.detailViewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
}


- (CGSize)splitViewSizeForOrientation:(UIInterfaceOrientation)theOrientation
{
	UIScreen *screen = [UIScreen mainScreen];
	CGRect fullScreenRect = screen.bounds; // always implicitly in Portrait orientation.
	CGRect appFrame = screen.applicationFrame;
	
	// Find status bar height by checking which dimension of the applicationFrame is narrower than screen bounds.
	// Little bit ugly looking, but it'll still work even if they change the status bar height in future.
	float statusBarHeight = MAX((fullScreenRect.size.width - appFrame.size.width), (fullScreenRect.size.height - appFrame.size.height));
	
	float navigationBarHeight = 0;
	if ((self.navigationController)&&(!self.navigationController.navigationBarHidden)) {
		navigationBarHeight = self.navigationController.navigationBar.frame.size.height;
	}
    CGFloat tabBarHeight = 0;
    if (self.tabBarController) {
        tabBarHeight = self.tabBarController.tabBar.frame.size.height;
    }
	
	// Initially assume portrait orientation.
	float width = fullScreenRect.size.width;
	float height = fullScreenRect.size.height;
	
	// Correct for orientation.
	if (UIInterfaceOrientationIsLandscape(theOrientation)) {
		width = height;
		height = fullScreenRect.size.width;
	}
	
	// Account for status bar, which always subtracts from the height (since it's always at the top of the screen).
	height -= statusBarHeight;
	height -= navigationBarHeight;
    height -= tabBarHeight;
	
	return CGSizeMake(width, height);
}


- (void)layoutSubviewsForInterfaceOrientation:(UIInterfaceOrientation)theOrientation withAnimation:(BOOL)animate
{
	if (_reconfigurePopup) {
		[self reconfigureForMasterInPopover:![self shouldShowMasterForInterfaceOrientation:theOrientation]];
	}
	
	// Layout the master, detail and divider views appropriately, adding/removing subviews as needed.
	// First obtain relevant geometry.
	CGSize fullSize = [self splitViewSizeForOrientation:theOrientation];
	float width = fullSize.width;
	float height = fullSize.height;
	
	if (NO) { // Just for debugging.
		NSLog(@"Target orientation is %@, dimensions will be %.0f x %.0f", 
			  [self nameOfInterfaceOrientation:theOrientation], width, height);
	}
	
	// Layout the master, divider and detail views.
	CGRect newFrame = CGRectMake(0, 0, width, height);
	UIViewController *controller;
	UIView *theView;
	BOOL shouldShowMaster = [self shouldShowMasterForInterfaceOrientation:theOrientation];
	BOOL masterFirst = [self isMasterBeforeDetail];
	if ([self isVertical]) {
		// Master on left, detail on right (or vice versa).
		CGRect masterRect, dividerRect, detailRect;
		if (masterFirst) {
			if (!shouldShowMaster) {
				// Move off-screen.
				newFrame.origin.x -= (_splitPosition + _splitWidth);
			}
			
			newFrame.size.width = _splitPosition;
			masterRect = newFrame;
			
			newFrame.origin.x += newFrame.size.width;
			newFrame.size.width = _splitWidth;
			dividerRect = newFrame;
			
			newFrame.origin.x += newFrame.size.width;
			newFrame.size.width = width - newFrame.origin.x;
			detailRect = newFrame;
			
		} else {
			if (!shouldShowMaster) {
				// Move off-screen.
				newFrame.size.width += (_splitPosition + _splitWidth);
			}
			
			newFrame.size.width -= (_splitPosition + _splitWidth);
			detailRect = newFrame;
			
			newFrame.origin.x += newFrame.size.width;
			newFrame.size.width = _splitWidth;
			dividerRect = newFrame;
			
			newFrame.origin.x += newFrame.size.width;
			newFrame.size.width = _splitPosition;
			masterRect = newFrame;
		}
		
		// Position master.
		controller = self.masterViewController;
		if (controller && [controller isKindOfClass:[UIViewController class]])  {
			theView = controller.view;
			if (theView) {
				theView.frame = masterRect;
				if (!theView.superview) {
					[controller viewWillAppear:NO];
					[self.view addSubview:theView];
					[controller viewDidAppear:NO];
				}
			}
		}
		
		// Position divider.
		theView = _dividerView;
		theView.frame = dividerRect;
		if (!theView.superview) {
			[self.view addSubview:theView];
		}
		
		// Position detail.
		controller = self.detailViewController;
		if (controller && [controller isKindOfClass:[UIViewController class]])  {
			theView = controller.view;
			if (theView) {
				theView.frame = detailRect;
				if (!theView.superview) {
					[self.view insertSubview:theView aboveSubview:self.masterViewController.view];
				} else {
					[self.view bringSubviewToFront:theView];
				}
			}
		}
		
	} else {
		// Master above, detail below (or vice versa).
		CGRect masterRect, dividerRect, detailRect;
		if (masterFirst) {
			if (!shouldShowMaster) {
				// Move off-screen.
				newFrame.origin.y -= (_splitPosition + _splitWidth);
			}
			
			newFrame.size.height = _splitPosition;
			masterRect = newFrame;
			
			newFrame.origin.y += newFrame.size.height;
			newFrame.size.height = _splitWidth;
			dividerRect = newFrame;
			
			newFrame.origin.y += newFrame.size.height;
			newFrame.size.height = height - newFrame.origin.y;
			detailRect = newFrame;
			
		} else {
			if (!shouldShowMaster) {
				// Move off-screen.
				newFrame.size.height += (_splitPosition + _splitWidth);
			}
			
			newFrame.size.height -= (_splitPosition + _splitWidth);
			detailRect = newFrame;
			
			newFrame.origin.y += newFrame.size.height;
			newFrame.size.height = _splitWidth;
			dividerRect = newFrame;
			
			newFrame.origin.y += newFrame.size.height;
			newFrame.size.height = _splitPosition;
			masterRect = newFrame;
		}
		
		// Position master.
		controller = self.masterViewController;
		if (controller && [controller isKindOfClass:[UIViewController class]])  {
			theView = controller.view;
			if (theView) {
				theView.frame = masterRect;
				if (!theView.superview) {
					[controller viewWillAppear:NO];
					[self.view addSubview:theView];
					[controller viewDidAppear:NO];
				}
			}
		}
		
		// Position divider.
		theView = _dividerView;
		theView.frame = dividerRect;
		if (!theView.superview) {
			[self.view addSubview:theView];
		}
		
		// Position detail.
		controller = self.detailViewController;
		if (controller && [controller isKindOfClass:[UIViewController class]])  {
			theView = controller.view;
			if (theView) {
				theView.frame = detailRect;
				if (!theView.superview) {
					[self.view insertSubview:theView aboveSubview:self.masterViewController.view];
				} else {
					[self.view bringSubviewToFront:theView];
				}
			}
		}
	}
	
	// Create corner views if necessary.
	MGSplitCornersView *leadingCorners = nil; // top/left of screen in vertical/horizontal split.
	MGSplitCornersView *trailingCorners = nil; // bottom/right of screen in vertical/horizontal split.
	if (!self.cornerViews) {
		CGRect cornerRect = CGRectMake(0, 0, 10, 10); // arbitrary, will be resized below.
		leadingCorners = [[MGSplitCornersView alloc] initWithFrame:cornerRect];
		leadingCorners.splitViewController = self;
		leadingCorners.cornerBackgroundColor = MG_DEFAULT_CORNER_COLOR;
		leadingCorners.cornerRadius = MG_DEFAULT_CORNER_RADIUS;
		trailingCorners = [[MGSplitCornersView alloc] initWithFrame:cornerRect];
		trailingCorners.splitViewController = self;
		trailingCorners.cornerBackgroundColor = MG_DEFAULT_CORNER_COLOR;
		trailingCorners.cornerRadius = MG_DEFAULT_CORNER_RADIUS;
		self.cornerViews = [[NSArray alloc] initWithObjects:leadingCorners, trailingCorners, nil];
		
	} else if ([self.cornerViews count] == 2) {
		leadingCorners = [self.cornerViews objectAtIndex:0];
		trailingCorners = [self.cornerViews objectAtIndex:1];
	}
	
	// Configure and layout the corner-views.
	leadingCorners.cornersPosition = (_vertical) ? MGCornersPositionLeadingVertical : MGCornersPositionLeadingHorizontal;
	trailingCorners.cornersPosition = (_vertical) ? MGCornersPositionTrailingVertical : MGCornersPositionTrailingHorizontal;
	leadingCorners.autoresizingMask = (_vertical) ? UIViewAutoresizingFlexibleBottomMargin : UIViewAutoresizingFlexibleRightMargin;
	trailingCorners.autoresizingMask = (_vertical) ? UIViewAutoresizingFlexibleTopMargin : UIViewAutoresizingFlexibleLeftMargin;
	
	float x, y, cornersWidth, cornersHeight;
	CGRect leadingRect, trailingRect;
	float radius = leadingCorners.cornerRadius;
	if (_vertical) { // left/right split
		cornersWidth = (radius * 2.0) + _splitWidth;
		cornersHeight = radius;
		x = ((shouldShowMaster) ? ((masterFirst) ? _splitPosition : width - (_splitPosition + _splitWidth)) : (0 - _splitWidth)) - radius;
		y = 0;
		leadingRect = CGRectMake(x, y, cornersWidth, cornersHeight); // top corners
		trailingRect = CGRectMake(x, (height - cornersHeight), cornersWidth, cornersHeight); // bottom corners
		
	} else { // top/bottom split
		x = 0;
		y = ((shouldShowMaster) ? ((masterFirst) ? _splitPosition : height - (_splitPosition + _splitWidth)) : (0 - _splitWidth)) - radius;
		cornersWidth = radius;
		cornersHeight = (radius * 2.0) + _splitWidth;
		leadingRect = CGRectMake(x, y, cornersWidth, cornersHeight); // left corners
		trailingRect = CGRectMake((width - cornersWidth), y, cornersWidth, cornersHeight); // right corners
	}
	
	leadingCorners.frame = leadingRect;
	trailingCorners.frame = trailingRect;
	
	// Ensure corners are visible and frontmost.
	if (!leadingCorners.superview) {
		[self.view insertSubview:leadingCorners aboveSubview:self.detailViewController.view];
		[self.view insertSubview:trailingCorners aboveSubview:self.detailViewController.view];
	} else {
		[self.view bringSubviewToFront:leadingCorners];
		[self.view bringSubviewToFront:trailingCorners];
	}
}


- (void)layoutSubviewsWithAnimation:(BOOL)animate
{
	[self layoutSubviewsForInterfaceOrientation:self.interfaceOrientation withAnimation:animate];
}


- (void)layoutSubviews
{
	[self layoutSubviewsForInterfaceOrientation:self.interfaceOrientation withAnimation:YES];
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	if ([self isShowingMaster]) {
		[self.masterViewController viewWillAppear:animated];
	}
	[self.detailViewController viewWillAppear:animated];
	
	_reconfigurePopup = YES;
	[self layoutSubviews];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if ([self isShowingMaster]) {
		[self.masterViewController viewDidAppear:animated];
	}
	[self.detailViewController viewDidAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
	if ([self isShowingMaster]) {
		[self.masterViewController viewWillDisappear:animated];
	}
	[self.detailViewController viewWillDisappear:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
	if ([self isShowingMaster]) {
		[self.masterViewController viewDidDisappear:animated];
	}
	[self.detailViewController viewDidDisappear:animated];
}


#pragma mark -
#pragma mark Popover handling


- (void)reconfigureForMasterInPopover:(BOOL)inPopover
{
	_reconfigurePopup = NO;
	
	if ((inPopover && _privateHiddenPopoverController) || (!inPopover && !_privateHiddenPopoverController) || !self.masterViewController) {
		// Nothing to do.
		return;
	}
	NSObject <MGSplitViewControllerDelegate> *delegate = (NSObject <MGSplitViewControllerDelegate> *)[self delegate];
	if (inPopover && !_privateHiddenPopoverController && !_barButtonItem) {
		// Create and configure popover for our masterViewController.
		_privateHiddenPopoverController = nil;
		[self.masterViewController viewWillDisappear:NO];
		_privateHiddenPopoverController = [[UIPopoverController alloc] initWithContentViewController:self.masterViewController];
		[self.masterViewController viewDidDisappear:NO];
		
		// Create and configure _barButtonItem.
        NSString *barButtonItemTitle = self.masterViewController.title;
        if (barButtonItemTitle == nil) {
            barButtonItemTitle = @"Master";
        }
		_barButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(barButtonItemTitle, nil) 
														  style:UIBarButtonItemStyleBordered 
														 target:self 
														 action:@selector(showMasterPopover:)];
		
		// Inform delegate of this state of affairs.
		if (delegate && [delegate respondsToSelector:@selector(splitViewController:willHideViewController:withBarButtonItem:forPopoverController:)]) {
			[delegate splitViewController:self 
                   willHideViewController:self.masterViewController 
                        withBarButtonItem:_barButtonItem 
                     forPopoverController:_privateHiddenPopoverController];
		}
		
	} else if (!inPopover && _privateHiddenPopoverController && _barButtonItem) {
		// I know this looks strange, but it fixes a bizarre issue with UIPopoverController leaving masterViewController's views in disarray.
        if (self.view.window != nil) {
            [_privateHiddenPopoverController presentPopoverFromRect:CGRectZero inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:NO];
		}
		// Remove master from popover and destroy popover, if it exists.
		[_privateHiddenPopoverController dismissPopoverAnimated:NO];
		_privateHiddenPopoverController = nil;
		
		// Inform delegate that the _barButtonItem will become invalid.
		if (delegate && [delegate respondsToSelector:@selector(splitViewController:willShowViewController:invalidatingBarButtonItem:)]) {
			[delegate splitViewController:self 
                   willShowViewController:self.masterViewController 
                invalidatingBarButtonItem:_barButtonItem];
		}
		
		// Destroy _barButtonItem.
		_barButtonItem = nil;
		
		// Move master view.
		UIView *masterView = self.masterViewController.view;
		if (masterView && masterView.superview != self.view) {
			[masterView removeFromSuperview];
		}
	}
}


- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	[self reconfigureForMasterInPopover:NO];
}


- (void)notePopoverDismissed
{
	[self popoverControllerDidDismissPopover:_privateHiddenPopoverController];
}


#pragma mark -
#pragma mark Animations


- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	if (([animationID isEqualToString:MG_ANIMATION_CHANGE_SPLIT_ORIENTATION] || 
		 [animationID isEqualToString:MG_ANIMATION_CHANGE_SUBVIEWS_ORDER])
		&& _cornerViews) {
		for (UIView *corner in _cornerViews) {
			corner.hidden = NO;
		}
		_dividerView.hidden = NO;
	}
}


#pragma mark -
#pragma mark IB Actions


- (IBAction)toggleSplitOrientation:(id)sender
{
	BOOL showingMaster = [self isShowingMaster];
	if (showingMaster) {
		if (_cornerViews) {
			for (UIView *corner in _cornerViews) {
				corner.hidden = YES;
			}
			_dividerView.hidden = YES;
		}
		[UIView beginAnimations:MG_ANIMATION_CHANGE_SPLIT_ORIENTATION context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	}
	self.vertical = (!self.vertical);
	if (showingMaster) {
		[UIView commitAnimations];
	}
}


- (IBAction)toggleMasterBeforeDetail:(id)sender
{
	BOOL showingMaster = [self isShowingMaster];
	if (showingMaster) {
		if (_cornerViews) {
			for (UIView *corner in _cornerViews) {
				corner.hidden = YES;
			}
			_dividerView.hidden = YES;
		}
		[UIView beginAnimations:MG_ANIMATION_CHANGE_SUBVIEWS_ORDER context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
	}
	self.masterBeforeDetail = (!self.masterBeforeDetail);
	if (showingMaster) {
		[UIView commitAnimations];
	}
}


- (IBAction)toggleMasterView:(id)sender
{
	if (_privateHiddenPopoverController && _privateHiddenPopoverController.popoverVisible) {
		[_privateHiddenPopoverController dismissPopoverAnimated:NO];
	}
	
	if (![self isShowingMaster]) {
		// We're about to show the master view. Ensure it's in place off-screen to be animated in.
		_reconfigurePopup = YES;
		[self reconfigureForMasterInPopover:NO];
		[self layoutSubviews];
	}
	
	// This action functions on the current primary orientation; it is independent of the other primary orientation.
	[UIView beginAnimations:@"toggleMaster" context:nil];
	if (self.isLandscape) {
		self.showsMasterInLandscape = !_showsMasterInLandscape;
	} else {
		self.showsMasterInPortrait = !_showsMasterInPortrait;
	}
	[UIView commitAnimations];
}


- (IBAction)showMasterPopover:(id)sender
{
	if (_privateHiddenPopoverController) {
        if (_privateHiddenPopoverController.popoverVisible) {
            [_privateHiddenPopoverController dismissPopoverAnimated:YES];
        }
        else {
            // Inform delegate.
            NSObject <MGSplitViewControllerDelegate> *delegate = (NSObject <MGSplitViewControllerDelegate> *)[self delegate];
            
            if (delegate && [delegate respondsToSelector:@selector(splitViewController:popoverController:willPresentViewController:)]) {
                [delegate splitViewController:self 
                            popoverController:_privateHiddenPopoverController 
                    willPresentViewController:self.masterViewController];
            }
            
            // Show popover.
            [_privateHiddenPopoverController presentPopoverFromBarButtonItem:_barButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
	}
}


#pragma mark -
#pragma mark Accessors and properties


@synthesize delegate = _delegate;
- (void)setDelegate:(id <MGSplitViewControllerDelegate>)newDelegate
{
	if (newDelegate != _delegate && 
		(!newDelegate || [(NSObject *)newDelegate conformsToProtocol:@protocol(MGSplitViewControllerDelegate)])) {
		_delegate = newDelegate;
	}
}

@synthesize showsMasterInPortrait = _showsMasterInPortrait;
- (void)setShowsMasterInPortrait:(BOOL)flag
{
	if (flag != _showsMasterInPortrait) {
		_showsMasterInPortrait = flag;
		
		if (![self isLandscape]) { // i.e. if this will cause a visual change.
			if (_privateHiddenPopoverController && _privateHiddenPopoverController.popoverVisible) {
				[_privateHiddenPopoverController dismissPopoverAnimated:NO];
			}
			
			// Rearrange views.
			_reconfigurePopup = YES;
			[self layoutSubviews];
		}
	}
}

@synthesize showsMasterInLandscape = _showsMasterInLandscape;
- (void)setShowsMasterInLandscape:(BOOL)flag
{
	if (flag != _showsMasterInLandscape) {
		_showsMasterInLandscape = flag;
		
		if ([self isLandscape]) { // i.e. if this will cause a visual change.
			if (_privateHiddenPopoverController && _privateHiddenPopoverController.popoverVisible) {
				[_privateHiddenPopoverController dismissPopoverAnimated:NO];
			}
			
			// Rearrange views.
			_reconfigurePopup = YES;
			[self layoutSubviews];
		}
	}
}

@synthesize vertical = _vertical;
- (void)setVertical:(BOOL)flag
{
	if (flag != _vertical) {
		if (_privateHiddenPopoverController && _privateHiddenPopoverController.popoverVisible) {
			[_privateHiddenPopoverController dismissPopoverAnimated:NO];
		}
		
		_vertical = flag;
		
		// Inform delegate.	
        NSObject <MGSplitViewControllerDelegate> *delegate = (NSObject <MGSplitViewControllerDelegate> *)[self delegate];

		if (delegate && [delegate respondsToSelector:@selector(splitViewController:willChangeSplitOrientationToVertical:)]) {
			[delegate splitViewController:self willChangeSplitOrientationToVertical:_vertical];
		}
		
		[self layoutSubviews];
	}
}


@synthesize masterBeforeDetail = _masterBeforeDetail;
- (void)setMasterBeforeDetail:(BOOL)flag
{
	if (flag != _masterBeforeDetail) {
		if (_privateHiddenPopoverController && _privateHiddenPopoverController.popoverVisible) {
			[_privateHiddenPopoverController dismissPopoverAnimated:NO];
		}
		
		_masterBeforeDetail = flag;
		
		if ([self isShowingMaster]) {
			[self layoutSubviews];
		}
	}
}

@synthesize splitPosition = _splitPosition;
- (void)setSplitPosition:(float)posn
{
	// Check to see if delegate wishes to constrain the position.
	float newPosn = posn;
	BOOL constrained = NO;
	CGSize fullSize = [self splitViewSizeForOrientation:self.interfaceOrientation];
    NSObject <MGSplitViewControllerDelegate> *delegate = (NSObject <MGSplitViewControllerDelegate> *)[self delegate];

	if (delegate && [delegate respondsToSelector:@selector(splitViewController:constrainSplitPosition:splitViewSize:)]) {
		newPosn = [delegate splitViewController:self constrainSplitPosition:newPosn splitViewSize:fullSize];
		constrained = YES; // implicitly trust delegate's response.
		
	} else {
		// Apply default constraints if delegate doesn't wish to participate.
		float minPos = MG_MIN_VIEW_WIDTH;
		float maxPos = ((_vertical) ? fullSize.width : fullSize.height) - (MG_MIN_VIEW_WIDTH + _splitWidth);
		constrained = (newPosn != _splitPosition && newPosn >= minPos && newPosn <= maxPos);
	}
	
	if (constrained) {
		if (_privateHiddenPopoverController && _privateHiddenPopoverController.popoverVisible) {
			[_privateHiddenPopoverController dismissPopoverAnimated:NO];
		}
		
		_splitPosition = newPosn;
		
		// Inform delegate.
		if (delegate && [delegate respondsToSelector:@selector(splitViewController:willMoveSplitToPosition:)]) {
			[delegate splitViewController:self willMoveSplitToPosition:_splitPosition];
		}
		
		if ([self isShowingMaster]) {
			[self layoutSubviews];
		}
	}
}


- (void)setSplitPosition:(float)posn animated:(BOOL)animate
{
	BOOL shouldAnimate = (animate && [self isShowingMaster]);
	if (shouldAnimate) {
		[UIView beginAnimations:@"SplitPosition" context:nil];
	}
	[self setSplitPosition:posn];
	if (shouldAnimate) {
		[UIView commitAnimations];
	}
}

@synthesize splitWidth = _splitWidth;
- (void)setSplitWidth:(float)width
{
	if (width != _splitWidth && width >= 0) {
		_splitWidth = width;
		if ([self isShowingMaster]) {
			[self layoutSubviews];
		}
	}
}


-(NSArray *)viewControllers
{
    return _viewControllers;
}
- (void)setViewControllers:(NSArray *)controllers
{
	if (controllers != _viewControllers) {
		for (UIViewController *controller in _viewControllers) {
			if ([controller isKindOfClass:[UIViewController class]]) {
				[controller.view removeFromSuperview];
			}
		}
		_viewControllers = [[NSMutableArray alloc] initWithCapacity:2];
		if (controllers && [controllers count] >= 2) {
			self.masterViewController = [controllers objectAtIndex:0];
			self.detailViewController = [controllers objectAtIndex:1];
		} else {
			NSLog(@"Error: %@ requires 2 view-controllers. (%@)", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
		}
		
		[self layoutSubviews];
	}
}

- (UIViewController *)masterViewController
{
	if (_viewControllers && [_viewControllers count] > 0) {
		id controller = [_viewControllers objectAtIndex:0];
		if ([controller isKindOfClass:[UIViewController class]]) {
			return controller;
		}
	}
	return nil;
}
- (void)setMasterViewController:(UIViewController *)master
{
	if (!_viewControllers) {
		_viewControllers = [[NSMutableArray alloc] initWithCapacity:2];
	}
	
	NSObject *newMaster = master;
	if (!newMaster) {
		newMaster = [NSNull null];
	}
	
	BOOL changed = YES;
	if ([_viewControllers count] > 0) {
		if ([_viewControllers objectAtIndex:0] == newMaster) {
			changed = NO;
		} else {
			[_viewControllers replaceObjectAtIndex:0 withObject:newMaster];
		}
		
	} else {
		[_viewControllers addObject:newMaster];
	}
	
	if (changed) {
		[self layoutSubviews];
	}
}

@synthesize detailViewController;
- (UIViewController *)detailViewController
{
	if (_viewControllers && [_viewControllers count] > 1) {
		id controller = [_viewControllers objectAtIndex:1];
		if ([controller isKindOfClass:[UIViewController class]]) {
			return controller;
		}
	}
	return nil;
}

- (void)setDetailViewController:(UIViewController *)detail
{
	if (!_viewControllers) {
		_viewControllers = [[NSMutableArray alloc] initWithCapacity:2];
		[_viewControllers addObject:[NSNull null]];
	}
	
	BOOL changed = YES;
	if ([_viewControllers count] > 1) {
		if ([_viewControllers objectAtIndex:1] == detail) {
			changed = NO;
		} else {
			[_viewControllers replaceObjectAtIndex:1 withObject:detail];
		}
		
	} else {
		[_viewControllers addObject:detail];
	}
	
	if (changed) {
		[self layoutSubviews];
	}
}

@synthesize dividerView = _dividerView;
- (void)setDividerView:(MGSplitDividerView *)divider
{
	if (divider != _dividerView) {
		[_dividerView removeFromSuperview];
		_dividerView = divider;
		_dividerView.splitViewController = self;
		_dividerView.backgroundColor = MG_DEFAULT_CORNER_COLOR;
		if ([self isShowingMaster]) {
			[self layoutSubviews];
		}
	}
}

@synthesize allowsDraggingDivider;
- (BOOL)allowsDraggingDivider
{
	if (_dividerView) {
		return _dividerView.allowsDragging;
	}
	return NO;
}
- (void)setAllowsDraggingDivider:(BOOL)flag
{
	if (self.allowsDraggingDivider != flag && _dividerView) {
		_dividerView.allowsDragging = flag;
	}
}

@synthesize dividerStyle = _dividerStyle;
- (void)setDividerStyle:(MGSplitViewDividerStyle)newStyle
{
	if (_privateHiddenPopoverController && _privateHiddenPopoverController.popoverVisible) {
		[_privateHiddenPopoverController dismissPopoverAnimated:NO];
	}
	
	// We don't check to see if newStyle equals _dividerStyle, because it's a meta-setting.
	// Aspects could have been changed since it was set.
	_dividerStyle = newStyle;
	
	// Reconfigure general appearance and behaviour.
	float cornerRadius = 0.0;
	if (_dividerStyle == MGSplitViewDividerStyleThin) {
		cornerRadius = MG_DEFAULT_CORNER_RADIUS;
		_splitWidth = MG_DEFAULT_SPLIT_WIDTH;
		self.allowsDraggingDivider = NO;
		
	} else if (_dividerStyle == MGSplitViewDividerStylePaneSplitter) {
		cornerRadius = MG_PANESPLITTER_CORNER_RADIUS;
		_splitWidth = MG_PANESPLITTER_SPLIT_WIDTH;
		self.allowsDraggingDivider = YES;
	}
	
	// Update divider and corners.
	[_dividerView setNeedsDisplay];
	if (_cornerViews) {
		for (MGSplitCornersView *corner in _cornerViews) {
			corner.cornerRadius = cornerRadius;
		}
	}
	
	// Layout all views.
	[self layoutSubviews];
}


- (void)setDividerStyle:(MGSplitViewDividerStyle)newStyle animated:(BOOL)animate
{
	BOOL shouldAnimate = (animate && [self isShowingMaster]);
	if (shouldAnimate) {
		[UIView beginAnimations:@"DividerStyle" context:nil];
	}
	[self setDividerStyle:newStyle];
	if (shouldAnimate) {
		[UIView commitAnimations];
	}
}

@synthesize cornerViews = _cornerViews;
- (NSArray *)cornerViews
{
	if (_cornerViews) {
		return _cornerViews;
	}
	
	return nil;
}




@end
