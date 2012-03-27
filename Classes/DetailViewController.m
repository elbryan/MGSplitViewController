//
//  DetailViewController.m
//  MGSplitView
//
//  Created by Matt Gemmell on 26/07/2010.
//  Copyright Instinctive Code 2010.
//

#import "DetailViewController.h"
#import "RootViewController.h"
#import "MGSplitViewController.h"

@interface DetailViewController () <UIPopoverControllerDelegate> 

@property (nonatomic, weak)IBOutlet UIBarButtonItem *toggleItem;
@property (nonatomic, weak)IBOutlet UIBarButtonItem *verticalItem;
@property (nonatomic, weak)IBOutlet UIBarButtonItem *dividerStyleItem;
@property (nonatomic, weak)IBOutlet UIBarButtonItem *masterBeforeDetailItem;
@property (nonatomic, weak) IBOutlet UIToolbar *toolbar;
@property (nonatomic, weak) IBOutlet UILabel *detailDescriptionLabel;

@property (nonatomic, retain)UIPopoverController *popoverController;

- (IBAction)toggleMasterView:(id)sender;
- (IBAction)toggleVertical:(id)sender;
- (IBAction)toggleDividerStyle:(id)sender;
- (IBAction)toggleMasterBeforeDetail:(id)sender;

- (void)configureView;

@end


@implementation DetailViewController


#pragma mark -
#pragma mark Managing the detail item


// When setting the detail item, update the view and dismiss the popover controller if it's showing.
- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
	
    if (self.popoverController != nil) {
        [self.popoverController dismissPopoverAnimated:YES];
    }        
}


- (void)configureView
{
    // Update the user interface for the detail item.
    self.detailDescriptionLabel.text = [self.detailItem description];
	self.toggleItem.title = ([self.splitController isShowingMaster]) ? @"Hide Master" : @"Show Master"; // "I... AM... THE MASTER!" Derek Jacobi. Gave me chills.
	self.verticalItem.title = (self.splitController.vertical) ? @"Horizontal Split" : @"Vertical Split";
	self.dividerStyleItem.title = (self.splitController.dividerStyle == MGSplitViewDividerStyleThin) ? @"Enable Dragging" : @"Disable Dragging";
	self.masterBeforeDetailItem.title = (self.splitController.masterBeforeDetail) ? @"Detail First" : @"Master First";
}


#pragma mark -
#pragma mark Split view support


- (void)splitViewController:(MGSplitViewController*)svc 
	 willHideViewController:(UIViewController *)aViewController 
		  withBarButtonItem:(UIBarButtonItem*)barButtonItem 
	   forPopoverController: (UIPopoverController*)pc
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
	
	if (barButtonItem) {
		barButtonItem.title = @"Popover";
		NSMutableArray *items = [[self.toolbar items] mutableCopy];
		[items insertObject:barButtonItem atIndex:0];
		[self.toolbar setItems:items animated:YES];
	}
    self.popoverController = pc;
}


// Called when the view is shown again in the split view, invalidating the button and popover controller.
- (void)splitViewController:(MGSplitViewController*)svc 
	 willShowViewController:(UIViewController *)aViewController 
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
	
	if (barButtonItem) {
		NSMutableArray *items = [[self.toolbar items] mutableCopy];
		[items removeObject:barButtonItem];
		[self.toolbar setItems:items animated:YES];
	}
    self.popoverController = nil;
}


- (void)splitViewController:(MGSplitViewController*)svc 
		  popoverController:(UIPopoverController*)pc 
  willPresentViewController:(UIViewController *)aViewController
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
}


- (void)splitViewController:(MGSplitViewController*)svc willChangeSplitOrientationToVertical:(BOOL)isVertical
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
}


- (void)splitViewController:(MGSplitViewController*)svc willMoveSplitToPosition:(float)position
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
}


- (float)splitViewController:(MGSplitViewController *)svc constrainSplitPosition:(float)proposedPosition splitViewSize:(CGSize)viewSize
{
	//NSLog(@"%@", NSStringFromSelector(_cmd));
	return proposedPosition;
}


#pragma mark -
#pragma mark Actions


- (IBAction)toggleMasterView:(id)sender
{
	[self.splitController toggleMasterView:sender];
	[self configureView];
}


- (IBAction)toggleVertical:(id)sender
{
	[self.splitController toggleSplitOrientation:self];
	[self configureView];
}


- (IBAction)toggleDividerStyle:(id)sender
{
	MGSplitViewDividerStyle newStyle = ((self.splitController.dividerStyle == MGSplitViewDividerStyleThin) ? MGSplitViewDividerStylePaneSplitter : MGSplitViewDividerStyleThin);
	[self.splitController setDividerStyle:newStyle animated:YES];
	[self configureView];
}


- (IBAction)toggleMasterBeforeDetail:(id)sender
{
	[self.splitController toggleMasterBeforeDetail:sender];
	[self configureView];
}


#pragma mark -
#pragma mark Rotation support


// Ensure that the view controller supports rotation and that the split view can therefore show in both portrait and landscape.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self configureView];
}

#pragma mark - properties
@synthesize splitController = _splitController;
@synthesize toggleItem = _toggleItem;
@synthesize verticalItem = _verticalItem;
@synthesize dividerStyleItem = _dividerStyleItem;
@synthesize masterBeforeDetailItem = _masterBeforeDetailItem;
@synthesize toolbar = _toolbar;
@synthesize detailDescriptionLabel = _detailDescriptionLabel;
@synthesize detailItem = _detailItem;
@synthesize popoverController = _privatePopoverController;


@end
