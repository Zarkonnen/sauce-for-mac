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
#import "LoginController.h"
#import "SaucePreconnect.h"
#import "SessionController.h"
#import "TunnelController.h"
#import "BugInfoController.h"
#import "ScoutWindowController.h"
#import "Subscriber.h"
#import "sessionConnect.h"
#import "RegexKitLite.h"

@implementation AppDelegate
@synthesize infoPanel;
@synthesize versionTxt;
@synthesize subscribeMenuItem;
@synthesize tunnelMenuItem;
@synthesize viewConnectMenuItem;
@synthesize noTunnel;

@synthesize optionsCtrlr;
@synthesize loginCtrlr;
@synthesize tunnelCtrlr;
@synthesize bugCtrlr;
@synthesize subscriberCtrl;

@synthesize noShowCloseSession;
@synthesize noShowCloseConnect;

@synthesize configWindows;          // os/browsers for windows
@synthesize configLinux;            // os/browsers for linux
@synthesize configOSX;              // os/browsers for osx

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification
{
	// make sure our singleton key equivalent manager is initialized, otherwise, it won't watch the frontmost window
	[KeyEquivalentManager defaultManager];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    
    if(INAPPSTORE)
        [subscribeMenuItem setHidden:YES];
    [viewConnectMenuItem setAction:nil];
    [[ScoutWindowController sharedScout] showWindow:nil];
    
    [mInfoVersionNumber setStringValue: [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleVersion"]];

    if([self checkUserOk])
    {
        // good name/key, got browsers, so go on to options dialog
        if([[PrefController sharedController] alwaysUseTunnel])
            [self doTunnel:self];
        else
            [self showOptionsDlg:self];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSNotification *)aNotification
{
    if(tunnelCtrlr)
        [tunnelCtrlr terminate];
    return YES;
        
}

// if internet had been down, check if it is back up; returns 0=no user, 1=ok
- (BOOL)checkUserOk
{    
    // check for username/key in prefs
    NSUserDefaults* user = [NSUserDefaults standardUserDefaults];
    NSString *uname = [user stringForKey:kUsername];
    NSString *akey = [user stringForKey:kAccountkey];
   
    if([uname length] && [akey length])
    {
        NSString *userOk = [[SaucePreconnect sharedPreconnect] checkUserLogin:uname  key:akey];
        if([userOk characterAtIndex:0] == 'F')
        {
            [self internetNotOkDlg];
            return NO;      // still no connection
        }
        if(userOk)      // TODO: display error message
            [self showLoginDlg:self];
        return userOk == nil;      // connection ok, but maybe no valid user
    }
    [self showLoginDlg:self];
    return NO;              // no valid user

}

- (void)internetNotOkDlg
{
    NSString *header = NSLocalizedString( @"Connection Status", nil );
    NSString *okayButton = NSLocalizedString( @"Ok", nil );
    NSBeginAlertSheet(header, okayButton, nil, nil, [[ScoutWindowController sharedScout] window], self, nil, nil, nil, @"Check your internet connection - or Sauce Labs server may be down");
    
}
 
- (IBAction)showOptionsDlg:(id)sender 
{
    if(![self checkUserOk])
        return;
    if(![configWindows count] && [self prefetchBrowsers] != 1)
        return;
    
    if(loginCtrlr)
        [loginCtrlr doCancelLogin:self];
    loginCtrlr = nil;
    if(!optionsCtrlr)
    {
        
        NSString *subscribed = [[SaucePreconnect sharedPreconnect] checkAccountOk];  // ask if user is subscribed or has enough minutes
        if([subscribed characterAtIndex:0] == 'F')      // failed internet
        {
            [self internetNotOkDlg];
            return;
        }
        if([subscribed characterAtIndex:0] == 'N')      // not subscribed
        {
             if([subscribed characterAtIndex:1] == '-') // not enough minutes
             {
                 [self promptForSubscribing:NO];   // prompt for subscribing to get more minutes
                 return;
             }
            if([[ScoutWindowController sharedScout] tabCount] > 2)      // user has to be subscribed
            {
                [self promptForSubscribing:YES];   // prompt for subscribing to get more tabs
                return;
            }
        }
        
        self.optionsCtrlr = [[SessionController alloc] init];
        [optionsCtrlr runSheet];
    }
}

- (void)startConnecting:(NSMutableDictionary*)sdict
{
    self.optionsCtrlr = nil;
    sessionConnect *sc = [[sessionConnect alloc] initWithDict:sdict];
    // link rfbview being created to this sessionconnect obj
    [sdict setObject:sc forKey:@"sessionConnect"];
    [sdict setObject:[sc view] forKey:@"scview"];
    // add view as new tab
    NSTabViewItem *newItem = [[[NSTabViewItem alloc] initWithIdentifier:nil] autorelease];
    [newItem setView:[sc view]];
	[newItem setLabel:@"Connecting"];       // TODO: make actual label
	[[[ScoutWindowController sharedScout] tabView] addTabViewItem:newItem];
	[[[ScoutWindowController sharedScout] tabView] selectTabViewItem:newItem];
    
    [NSThread detachNewThreadSelector:@selector(preAuthorize:) toTarget:[SaucePreconnect sharedPreconnect] withObject:sdict];
}

-(void)connectionSucceeded:(NSMutableDictionary*)sdict
{
    [[SaucePreconnect sharedPreconnect] cancelPreAuthorize:sdict];
}

- (void)newUserAuthorized:(id)param
{
    [loginCtrlr login:nil];
    [self showOptionsDlg:nil];
}

- (void)cancelOptionsConnect:(id)sdict
{
    NSMutableDictionary *theDict = sdict;
    
    [[ScoutWindowController sharedScout] closeTab:sdict];
    
    NSString *errMsg = [theDict objectForKey:@"errorString"];
    if(errMsg)
    {
        NSString *header = NSLocalizedString( @"Connection Status", nil );
        NSString *okayButton = NSLocalizedString( @"Ok", nil );
        NSBeginAlertSheet(header, okayButton, nil, nil, [[ScoutWindowController sharedScout] window], self, nil, nil, nil, errMsg);
    }
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

- (IBAction)showSubscribeDlg:(id)sender
{
    if(self.optionsCtrlr)       // close the options sheet
    {
        [NSApp endSheet:[optionsCtrlr panel]];
        [[optionsCtrlr panel] orderOut:nil];
        self.optionsCtrlr = nil;    
    }
        
    [self promptForSubscribing:2];
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


- (IBAction)showConnectionDialog: (id)sender
{  [[RFBConnectionManager sharedManager] showConnectionDialog: nil];  }

- (IBAction)showNewConnectionDialog:(id)sender
{  [[RFBConnectionManager sharedManager] showNewConnectionDialog: nil];  }


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

- (IBAction)doStopSession:(id)sender
{
    [[ScoutWindowController sharedScout] doPlayStop:sender];
}

- (IBAction)doStopConnect:(id)sender
{
    if(tunnelCtrlr)
    {
        [tunnelCtrlr doClose:self];
    }
}

- (void)closeStopConnect
{
    if(tunnelCtrlr)
    {
        [tunnelCtrlr setStopCtlr:nil];
    }
}

- (IBAction)viewConnect:(id)sender
{
    if(tunnelCtrlr)    // need to display the tunnel object
    {
        NSWindow *win = [[ScoutWindowController sharedScout] window];
        [tunnelCtrlr runSheetOnWindow:win]; 
    }
}

- (IBAction)toggleToolbar:(id)sender
{
    [[ScoutWindowController sharedScout] toggleToolbar];
}

- (IBAction)doTunnel:(id)sender
{
    if(self.optionsCtrlr)       // close the options sheet
    {
        [NSApp endSheet:[optionsCtrlr panel]];
        [[optionsCtrlr panel] orderOut:nil];
        self.optionsCtrlr = nil;    
    }
        
    NSWindow *win = [[ScoutWindowController sharedScout] window];
    
    if(!tunnelCtrlr)    // need to create the tunnel object
    {
        self.tunnelCtrlr = [[TunnelController alloc] init];
        [tunnelCtrlr runSheetOnWindow:win];
    }
    else  // asking to stop tunnel
    {
        [self doStopConnect:self];
    }
}

- (void)escapeDialog
{
    if(optionsCtrlr)
    {
        [optionsCtrlr quitSheet];
        self.optionsCtrlr = nil;
    }
    else if(subscriberCtrl)
    {
        [subscriberCtrl quitSheet];
        self.subscriberCtrl = nil;
    }
}

- (void)toggleTunnelDisplay
{
    if(tunnelCtrlr)
    {
        [tunnelMenuItem setTitle:@"Stop Sauce Connect"];
        [viewConnectMenuItem setAction:@selector(viewConnect:)];
        [[[ScoutWindowController sharedScout] tunnelButton] setTitle:@"Stop Sauce Connect"];
    }
    else    // no tunnel
    {
        [[ScoutWindowController sharedScout] tunnelConnected:NO];
        [tunnelMenuItem setTitle:@"Start Sauce Connect"];
        [viewConnectMenuItem setAction:nil];
        [[[ScoutWindowController sharedScout] tunnelButton] setTitle:@"Start Sauce Connect"];
    }
}

- (IBAction)myAccount:(id)sender 
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.saucelabs.com/account"]];
}

- (IBAction)doAbout:(id)sender
{
    NSString *vstr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *bstr = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"Build"];
    NSString *vtxt = [NSString stringWithFormat:@"Version: %@    Build: %@",vstr, bstr];
    [versionTxt setStringValue:vtxt];
    [infoPanel makeKeyAndOrderFront:self];    
}

- (IBAction)bugsAccount:(id)sender 
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.saucelabs.com/bugs"]];
}

- (void)promptForSubscribing:(BOOL)bCause        // 0=needs more minutes; 1=to get more tabs
{
    if([self checkUserOk])
        subscriberCtrl = [[[Subscriber alloc] init:bCause] retain];
    
}

- (void)subscribeDidDismiss:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    if(returnCode == NSAlertDefaultReturn)      // go to subscribe page
        [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.saucelabs.com/pricing"]];

}

// get json data for browsers from server
- (NSInteger)prefetchBrowsers
{
    NSInteger bres = -1;

    NSString *farg = [NSString stringWithFormat:@"curl 'https://%@/rest/v1/info/scout' -H 'Content-Type: application/json'", kSauceLabsDomain];
    
    NSTask *ftask = [[[NSTask alloc] init] autorelease];
    NSPipe *fpipe = [NSPipe pipe];
    [ftask setStandardOutput:fpipe];
    [ftask setLaunchPath:@"/bin/bash"];
    [ftask setArguments:[NSArray arrayWithObjects:@"-c", farg, nil]];
    [ftask launch];		// fetch live id
    [ftask waitUntilExit];
    if([ftask terminationStatus])
    {
        NSLog(@"failed NSTask");
        bres = -1;
    }
    else
    {
        NSFileHandle *fhand = [fpipe fileHandleForReading];        
        NSData *data = [fhand readDataToEndOfFile];	
        NSString *jsonString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
        if([jsonString hasPrefix:@"[{"])
        {
            [self parseBrowsers:jsonString];
            return 1;       // get valid data
        }
        else 
            bres = 0;   // didn't get valid data
    }    
    NSString *msg;
    if(bres==-1)
        msg = @"Failed connection to server";
    else
        msg = @"Can't retrieve browser data";
    NSBeginAlertSheet(@"Browser Data", @"Ok", nil, nil, [[ScoutWindowController sharedScout] window], self, nil, nil, nil, msg);
    return bres;
}

// read data ifrom server into dictionaries
- (void)parseBrowsers:(NSString*)jsonStr
{
    configOSX     = [[[NSMutableArray alloc] init] retain];     // os/browsers for osx
    configWindows = [[[NSMutableArray alloc] init] retain];     // os/browsers for windows
    configLinux   = [[[NSMutableArray alloc] init] retain];     // os/browsers for linux
    
    // pull out the lines into an array
    // a sample line: {"name": "android", "os_display": "Linux", "short_version": "4", "long_name": "Android", "long_version": "4.0.3.", "os": "Linux", "backend": "selenium"}
    NSArray *linesArr = [jsonStr arrayOfCaptureComponentsMatchedByRegex:@"\\{(.*?)\\}"];
    [jsonStr release];
    NSString *osStr, *ll;
    NSString *browser;
    NSString *version;
    NSString *active;
    for(NSArray *arr in linesArr)
    {
        ll = [arr objectAtIndex:0];
        osStr   = [[SaucePreconnect sharedPreconnect] jsonVal:ll key:@"os"];
        browser = [[SaucePreconnect sharedPreconnect] jsonVal:ll key:@"name"];
        version = [[SaucePreconnect sharedPreconnect] jsonVal:ll key:@"short_version"];
        if(![version length])
            version=@"*";
        active  = @"YES";
        
        NSMutableArray *obarr = [NSMutableArray arrayWithCapacity:4];
        [obarr  addObject:osStr];
        [obarr  addObject:browser];
        [obarr  addObject:version];
        [obarr  addObject:active];
        if([osStr hasPrefix:@"Windows"])
            [configWindows addObject:obarr];
        else if([osStr hasPrefix:@"Linux"])
            [configLinux addObject:obarr];            
        else if([osStr hasPrefix:@"Mac"])
            [configOSX addObject:obarr];
    }    
}

@end
