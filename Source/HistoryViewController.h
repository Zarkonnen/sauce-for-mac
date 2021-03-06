//
//  HistoryViewController.h
//  scout
//
//  Created by ackerman dudley on 7/4/12.
//  Copyright (c) 2012 Sauce Labs. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RFBView.h"
@class historyTableView;

@interface HistoryViewController : NSViewController
{
    NSMutableDictionary *rowDict;
    NSMutableDictionary *indxDict;
    IBOutlet historyTableView *tableView;
}
- (void)addRow:(NSView*)view rowArr:(NSArray*)rarr;
- (void)updateRuntime:(NSView*)view;
- (void)updateActive:(NSView*)view;     // set not active; assumes we can only deactivate an active session
- (IBAction)doNewSession:(id)sender;
- (void)browseJobs:(NSInteger)row;
@end
