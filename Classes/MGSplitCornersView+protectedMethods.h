//
//  MGSplitCornersView+protectedMethods.h
//  MGSplitView
//
//  Created by Jonathan Saggau on 3/2/12.
//  Copyright (c) 2012 Sounds Broken inc. All rights reserved.
//

#import "MGSplitCornersView.h"

@interface MGSplitCornersView ()

@property (nonatomic, assign) float cornerRadius;
@property (nonatomic, weak) MGSplitViewController *splitViewController; 
@property (nonatomic, assign) MGCornersPosition cornersPosition;
@property (nonatomic) UIColor *cornerBackgroundColor;

@end
