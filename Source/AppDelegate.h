//
//  AppDelegate.h
//  Chicken of the VNC
//
//  Created by Jason Harris on 8/18/04.
//  Copyright 2004 Geekspiff. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "SaucePreconnect.h"

@class SessionController;
@class LoginController;

@interface AppDelegate : NSObject {
	IBOutlet NSMenuItem *mRendezvousMenuItem;
	IBOutlet NSTextField *mInfoVersionNumber;
    IBOutlet NSMenuItem *fullScreenMenuItem;
    SessionController *optionsCtrlr;
    LoginController *loginCtrlr;
}
- (IBAction)toggleToolbar:(id)sender;
- (IBAction)doTunnel:(id)sender;

@property (retain)SessionController *optionsCtrlr;
@property (retain)LoginController *loginCtrlr;

- (IBAction)showOptionsDlg:(id)sender;
- (IBAction)showLoginDlg:(id)sender;

- (IBAction)showPreferences: (id)sender;
- (IBAction)changeRendezvousUse:(id)sender;
- (IBAction)showNewConnectionDialog:(id)sender;
- (IBAction)showConnectionDialog: (id)sender;
- (IBAction)showListenerDialog: (id)sender;
- (IBAction)showProfileManager: (id)sender;
- (IBAction)showHelp: (id)sender;

-(void)connectionSucceeded;
- (void)cancelOptionsConnect:(id)sender;

- (NSMenuItem *)getFullScreenMenuItem;

@end
