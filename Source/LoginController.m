//
//  ServerFromPrefs.h
//  Chicken of the VNC
//
//  Created by Jared McIntyre on Sun May 1 2004.
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
//


#import "AppDelegate.h"
#import "LoginController.h"
#import "SaucePreconnect.h"
#import "RFBConnectionManager.h"
#import "SessionController.h"


@implementation LoginController
@synthesize user;
@synthesize accountKey;
@synthesize aNewUsername;
@synthesize aNewPassword;
@synthesize aNewEmail;


-(void)awakeFromNib
{
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    NSString *uname = [defs stringForKey:kUsername];
    NSString *akey = [defs stringForKey:kAccountkey];
    [self.user setStringValue:uname];
    [self.accountKey setStringValue:akey];   
}

- (IBAction)login:(id)sender
{
    NSString *uname = [self.user stringValue];
    NSString *aaccountkey = [self.accountKey stringValue];
    if([uname length] && [aaccountkey length])
    {
        if([[SaucePreconnect sharedPreconnect] checkUserLogin:uname  key:aaccountkey])
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:uname  forKey:kUsername];
            [defaults setObject:aaccountkey  forKey:kAccountkey];
            SessionController *odlg = [[SessionController alloc] initWithWindowNibName:@"SessionController"];
            [odlg window];
            [self dealloc];     // get rid of the login dialog
        }
        else 
        {
            // TODO: alert for bad login
        }
    }
    else {
        // TODO: alert for missing username or accountkey
    }
}

- (IBAction)forgotKey:(id)sender
{
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.saucelabs.com"]];    
}

- (IBAction)signUp:(id)sender
{
    NSString *nameNew = [self.aNewUsername stringValue];
    NSString *passNew = [self.aNewPassword stringValue];
    NSString *emailNew = [self.aNewEmail stringValue];

    NSString *akey = [[SaucePreconnect sharedPreconnect] signupNew:nameNew password:passNew email:emailNew];
    if([akey length])
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:nameNew  forKey:kUsername];
        [defaults setObject:akey  forKey:kAccountkey];
        SaucePreconnect *precon = [SaucePreconnect sharedPreconnect];
        [precon setUser:nameNew];
        [precon setUkey:akey];
        SessionController *odlg = [[SessionController alloc] initWithWindowNibName:@"SessionController"];
        [odlg window];
        [self dealloc];     // get rid of the login dialog
    }    
}


@end