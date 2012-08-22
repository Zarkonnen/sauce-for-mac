//
//  historyTableView.m
//  scout
//
//  Created by ackerman dudley on 8/21/12.
//  Copyright (c) 2012 Sauce Labs. All rights reserved.
//

#import "historyTableView.h"
#import "HistoryViewController.h"

@implementation historyTableView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

-(void)setVwCtlr:(HistoryViewController*)histVCtlr
{
    vwCtlr = histVCtlr;
    
}
-(void)mouseDown:(NSEvent *)event
{
    int row = [self rowAtPoint:[self convertPoint:[event locationInWindow] fromView:nil]];
    if(row==-1)
        return;
    NSTableColumn *aCol = [[self tableColumns] 
                        objectAtIndex:[self columnAtPoint:
                                       [self convertPoint:[event  locationInWindow]
                                                 fromView:nil]]];
    NSString *colId = [aCol identifier];
    if([colId isEqualToString:@"session"])
        [vwCtlr browseJobs:row];

    [super mouseDown:event];         
}
                                                                                         
@end
