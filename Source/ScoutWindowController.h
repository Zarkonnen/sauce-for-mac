//
//  WindowController.h
//  PSMTabBarControl
//
//  Created by John Pannell on 4/6/06.
//  Copyright 2006 Positive Spin Media. All rights reserved.
//  modified by RDA for SauceLabs 2012.
//

#import <Cocoa/Cocoa.h>

typedef enum { login,options,session } tabType;

@class PSMTabBarControl;
@class Session;

@interface ScoutWindowController : NSWindowController <NSToolbarDelegate, NSWindowDelegate> {
	IBOutlet NSTabView					*tabView;
	IBOutlet PSMTabBarControl			*tabBar;
    IBOutlet NSTextField *statusMessage;
    IBOutlet NSSegmentedControl *playstop;
    IBOutlet NSSegmentedControl *bugcamera;
    IBOutlet NSTextField *timeRemainingStat;
    IBOutlet NSTextField *osbrowser;
    IBOutlet NSTextField *userStat;
    NSTextField *urlmsg;
    NSImageView *osmsg;
    NSTextField *osversionmsg;
    NSImageView *browsermsg;
    NSTextField *browserversmsg;
    NSTextField *timeRemainingMsg;
    NSTextField *vmsize;
    Session *curSession;
    NSBox *msgBox;
    NSToolbar *toolbar;
    NSString *bugTitle;
    NSString *bugDesc;
    NSString *bugTo;
    NSImageView *tunnelImage;
}
@property (assign) IBOutlet NSImageView *tunnelImage;
@property (assign) IBOutlet NSToolbar *toolbar;
@property (assign) IBOutlet NSBox *msgBox;
@property (assign) IBOutlet NSTextField *statusMessage;
@property (assign) IBOutlet NSTextField *urlmsg;
@property (assign) IBOutlet NSImageView *osmsg;
@property (assign) IBOutlet NSTextField *osversionmsg;
@property (assign) IBOutlet NSImageView *browsermsg;
@property (assign) IBOutlet NSTextField *browserversmsg;
@property (assign) IBOutlet NSTextField *timeRemainingMsg;
@property (assign) IBOutlet NSTextField *vmsize;
@property (assign)IBOutlet NSTextField *timeRemainingStat;
@property (assign)IBOutlet NSTextField *userStat;
@property (assign)IBOutlet NSTextField *osbrowser;
@property (assign) Session *curSession;
@property (copy) NSString *bugTitle;
@property (copy) NSString *bugDesc;
@property (copy) NSString *bugTo;


+(ScoutWindowController*)sharedScout;
- (IBAction)addNewTab:(id)sender;

- (IBAction)doPlayStop:(id)sender;
- (IBAction)doBugCamera:(id)sender;
- (IBAction)newSession:(id)sender;
- (void)tunnelConnected:(BOOL)is;     // tunnel is ready to use - or not

// UI
- (void)toggleToolbar;
- (int)tabCount;
- (void)addTabWithView:(NSView*)view; 
- (IBAction)closeTab:(id)sender;
- (void)setTabLabel:(NSString*)lbl;

- (PSMTabBarControl *)tabBar;

// tabview delegate
- (void)tabView:(NSTabView *)aTabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem;
- (BOOL)tabView:(NSTabView *)aTabView shouldCloseTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem;
- (void)closeAllTabs;

//window delegate messages
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)windowDidResignKey:(NSNotification *)aNotification;
- (void)windowDidDeminiaturize:(NSNotification *)aNotification;
- (void)windowDidMiniaturize:(NSNotification *)aNotification;
- (void)windowWillClose:(NSNotification *)aNotification;
- (void)windowDidResize:(NSNotification *)aNotification;
- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)proposedFrameSize;

-(void)submitBug:(NSString*)title desc:(NSString*)description to:(NSString*)to;
-(void)snapshotSuccess;

@end
