//
//  SauceLinkTextField.m
//  scout
//
//  Created by Sauce Labs on 11/10/12.
//  Copyright (c) 2012 Sauce Labs. All rights reserved.
//

#import "SauceLinkTextField.h"

@implementation SauceLinkTextField

#if 0
- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}
#endif

-(void)mouseDown:(NSEvent *)theEvent
{
    [self sendAction:[self action] to:[self target]];    
}

@end