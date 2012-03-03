//
//  DetailViewController.h
//  MGSplitView
//
//  Created by Matt Gemmell on 26/07/2010.
//  Copyright Instinctive Code 2010.
//

#import <UIKit/UIKit.h>
#import "MGSplitViewController.h"

@interface DetailViewController : UIViewController <MGSplitViewControllerDelegate>

@property (nonatomic, retain) id detailItem;
@property (nonatomic, weak)IBOutlet MGSplitViewController *splitController;

@end
