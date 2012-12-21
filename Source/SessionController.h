//
//  SessionController.h
//  scout-desktop
//
//  Created by ackerman dudley on 4/2/12.
//  Copyright (c) 2012 __SauceLabs__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define kNumTabs 3

typedef enum {tt_windows, tt_linux, tt_apple} ttType;

@interface SessionController : NSObject <NSBrowserDelegate>
{
    ttType curTabIndx;
    NSInteger curNumBrowsers;
    BOOL lastpop1;
    BOOL lastpop2;
    NSInteger sessionIndxs[kNumTabs];
    NSInteger resolutionIndxs[kNumTabs];
    NSTextField *url;
    NSProgressIndicator *connectIndicator;
    NSTextField *connectIndicatorText;
    NSButton *connectBtn;
    NSPanel *panel;
    NSView *view;
    NSButton *defaultBrowser;
    IBOutlet NSBrowser *browserTbl;
    NSMutableArray *configWindows;          // os/browsers for windows
    NSMutableArray *configLinux;            // os/browsers for linux
    NSMutableArray *configOSX;              // os/browsers for osx
    NSMutableArray *brAStrsWindows;         // browser attributed strings
    NSMutableArray *brAStrsLinux;
    NSMutableArray *brAStrsApple;
    NSMutableArray *brAStrsMobile;    
    NSAttributedString* osAStrs[4];
}
@property (assign) IBOutlet NSButton *defaultBrowser;
@property (assign) IBOutlet NSPanel *panel;
@property (assign) IBOutlet NSView *view;

@property (assign) IBOutlet NSButton *connectBtn;
@property (assign) IBOutlet NSTextField *connectIndicatorText;
@property (assign) IBOutlet NSProgressIndicator *connectIndicator;
@property (assign) IBOutlet NSTextField *url;

- (IBAction)doBrowserClick:(NSBrowser *)sender;
- (IBAction)doDoubleClick:(id)sender;
- (void)quitSheet;
- (void)terminateApp;
- (void)runSheet;
- (IBAction)connect:(id)sender;
- (IBAction)cancel:(id)sender;
- (void)showError:(NSString *)errStr;
- (IBAction)visitSauce:(id)sender;



@end


