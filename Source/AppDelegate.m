//
//  AppDelegate.m
//  Chicken of the VNC
//
//  Created by Jason Harris on 8/18/04.
//  Copyright 2004 Geekspiff. All rights reserved.
//

#import "AppDelegate.h"
#import "KeyEquivalentManager.h"
#import "PrefController.h"
#import "ProfileManager.h"
#import "RFBConnectionManager.h"
#import "ListenerController.h"
#import "LoginController.h"
#import "SaucePreconnect.h"
#import "SessionController.h"
#import "TunnelController.h"
#import "ScoutWindowController.h"


@implementation AppDelegate
@synthesize tunnelDspMenuItem;
@synthesize tunnelMenuItem;

@synthesize optionsCtrlr;
@synthesize loginCtrlr;
@synthesize tunnelCtrlr;

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	// make sure our singleton key equivalent manager is initialized, otherwise, it won't watch the frontmost window
	[KeyEquivalentManager defaultManager];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[ScoutWindowController sharedScout] showWindow:nil];
    
    
    // check for username/key in prefs
    NSUserDefaults* user = [NSUserDefaults standardUserDefaults];
    NSString *uname = [user stringForKey:kUsername];
    NSString *akey = [user stringForKey:kAccountkey];
    BOOL bLoginDlg = YES;
    
    if([uname length] && [akey length])
    {
        if([[SaucePreconnect sharedPreconnect] checkUserLogin:uname  key:akey])
        {
            // good name/key, so go on to options dialog
            [self showOptionsDlg:self];
            bLoginDlg = NO;
        }
    }
    if(bLoginDlg)
    {
        [self showLoginDlg:self];
    }

    [mInfoVersionNumber setStringValue: [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"]];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSNotification *)aNotification
{
    if(tunnelCtrlr)
        [tunnelCtrlr terminate];
    return YES;
        
}

- (IBAction)showOptionsDlg:(id)sender 
{
    if(loginCtrlr)
        [loginCtrlr doCancelLogin:self];
    loginCtrlr = nil;
    if(!optionsCtrlr)
    {
        self.optionsCtrlr = [[SessionController alloc] init];
        [optionsCtrlr runSheet];
    }
}

-(void)showOptionsIfNoTabs
{
    if(![[ScoutWindowController sharedScout] tabCount])
        [self showOptionsDlg:self];
}

-(void)connectionSucceeded
{
    [optionsCtrlr connectionSucceeded];
    self.optionsCtrlr = nil;    
}

- (void)newUserAuthorized:(id)param
{
    [loginCtrlr login:nil];
    [self showOptionsDlg:nil];
}

- (void)preAuthorizeErr
{
    NSString *err = [[SaucePreconnect sharedPreconnect] errStr];
    [optionsCtrlr showError:err];
}

- (void)cancelOptionsConnect:(id)sender
{
    [[RFBConnectionManager sharedManager] cancelConnection];
    if(sender != [ScoutWindowController sharedScout])
        [optionsCtrlr cancelConnect:nil];
    self.optionsCtrlr = nil;    
}

- (IBAction)showLoginDlg:(id)sender 
{
    if(optionsCtrlr)
    {
        [NSApp endSheet:[optionsCtrlr panel]];
        [[optionsCtrlr panel] orderOut:nil]; 
        self.optionsCtrlr = nil;
    }
    self.loginCtrlr = [[LoginController alloc] init];
}

- (IBAction)showPreferences: (id)sender
{
	[[PrefController sharedController] showWindow];
}

- (BOOL) applicationShouldHandleReopen: (NSApplication *) app hasVisibleWindows: (BOOL) visibleWindows
{
	if(!visibleWindows)
	{
		[self showConnectionDialog:nil];
		return NO;
	}
	
	return YES;
}

- (IBAction)changeRendezvousUse:(id)sender
{
	PrefController *prefs = [PrefController sharedController];
	[prefs toggleUseRendezvous: sender];
	
	[mRendezvousMenuItem setState: [prefs usesRendezvous] ? NSOnState : NSOffState];
}


- (IBAction)showConnectionDialog: (id)sender
{  [[RFBConnectionManager sharedManager] showConnectionDialog: nil];  }

- (IBAction)showNewConnectionDialog:(id)sender
{  [[RFBConnectionManager sharedManager] showNewConnectionDialog: nil];  }

- (IBAction)showListenerDialog: (id)sender
{  [[ListenerController sharedController] showWindow: nil];  }


- (IBAction)showProfileManager: (id)sender
{  [[ProfileManager sharedManager] showWindow: nil];  }


- (IBAction)showHelp: (id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://saucelabs.com/scoutdesktop"]]; 
}

- (NSMenuItem *)getFullScreenMenuItem
{
    return fullScreenMenuItem;
}

- (IBAction)toggleToolbar:(id)sender
{
    [[ScoutWindowController sharedScout] toggleToolbar];
}

- (IBAction)doTunnel:(id)sender
{
    if(tunnelCtrlr)
        [self doTunnelDisplay:self];
    else
    {
        [self doTunnelDisplay:self];        
        if(tunnelCtrlr)
            [tunnelCtrlr doTunnel];
    }
}

- (IBAction)doTunnelDisplay:(id)sender
{
    if(self.optionsCtrlr)
    {
        [NSApp endSheet:[optionsCtrlr panel]];
        [[optionsCtrlr panel] orderOut:nil];
    }
    self.optionsCtrlr = nil;    
        
    NSWindow *win = [[ScoutWindowController sharedScout] window];
    if(!tunnelCtrlr)
        self.tunnelCtrlr = [[TunnelController alloc] init];
    [tunnelCtrlr runSheetOnWindow:win];

    [tunnelMenuItem setTitle:@"Disconnect"];
    [tunnelDspMenuItem setEnabled:YES];
    [tunnelDspMenuItem setTitle:@"Hide display"];
}

- (void)toggleTunnelDisplay:(BOOL)connected
{
    if(!tunnelCtrlr)
    {
        [[ScoutWindowController sharedScout] tunnelConnected:NO];            
        [tunnelMenuItem setTitle:@"Connect"];
        [tunnelDspMenuItem setEnabled:NO];
        [tunnelDspMenuItem setTitle:@"Hide display"];        
        [self showOptionsIfNoTabs];
        return;
    }
    if(connected)
    {
        [tunnelMenuItem setTitle:@"Disconnect"];
        [tunnelDspMenuItem setEnabled:YES];
        if([tunnelCtrlr hiddenDisplay])
            [tunnelDspMenuItem setTitle:@"Show display"];
        else 
            [tunnelDspMenuItem setTitle:@"Hide display"];
    }
    else    // tunnel is not connected
    {
        [tunnelMenuItem setTitle:@"Connect"];
        [tunnelDspMenuItem setEnabled:NO];
        [tunnelDspMenuItem setTitle:@"Show display"];        
    }
}
@end
