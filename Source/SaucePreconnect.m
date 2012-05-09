//
//  SaucePreconnect.m
//  scout-desktop
//
//  Created by Sauce Labs on 3/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SaucePreconnect.h"
#import "SBJson.h"
#import "RFBConnectionManager.h"
#import "ScoutWindowController.h"
#import "Session.h"

@implementation SaucePreconnect

@synthesize user;
@synthesize ukey;
@synthesize os;
@synthesize browser;
@synthesize browserVersion;
@synthesize urlStr;
@synthesize secret;
@synthesize jobId;
@synthesize liveId;
@synthesize userNew;
@synthesize passNew;
@synthesize emailNew;

@synthesize timer;
@synthesize errStr;
@synthesize cancelled;

static SaucePreconnect* _sharedPreconnect = nil;

+(SaucePreconnect*)sharedPreconnect
{
	@synchronized([SaucePreconnect class])
	{
		if (!_sharedPreconnect)
			[[self alloc] init];
                
		return _sharedPreconnect;
	}
    
	return nil;
}

+(id)alloc
{
	@synchronized([SaucePreconnect class])
	{
		NSAssert(_sharedPreconnect == nil, @"Attempted to allocate a second instance of a singleton.");
		_sharedPreconnect = [super alloc];
		return _sharedPreconnect;
	}
    
	return nil;
}

- (void)setOptions:(NSString*)uos browser:(NSString*)ubrowser 
    browserVersion:(NSString*)ubrowserVersion url:(NSString*)uurlStr
{
    os = uos;       
    browser = ubrowser;
    browserVersion = ubrowserVersion;
    urlStr = uurlStr;
}

// use user/password and users selections to get live_id from server
- (void)preAuthorize:(id)param
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *farg = [NSString stringWithFormat:@"curl -X POST 'https://%@:%@@saucelabs.com/rest/v1/users/%@/scout' -H 'Content-Type: application/json' -d '{\"os\":\"%@\", \"browser\":\"%@\", \"browser-version\":\"%@\", \"url\":\"%@\"}'", self.user, self.ukey, self.user, self.os, self.browser, self.browserVersion, self.urlStr];
    cancelled = NO;
    self.errStr = @"";

    while(1)
    {
        if(cancelled)
        {
            self.errStr = @"Connecting was cancelled";
            break;
        }

        NSTask *ftask = [[NSTask alloc] init];
        NSPipe *fpipe = [NSPipe pipe];
        [ftask setStandardOutput:fpipe];
        [ftask setLaunchPath:@"/bin/bash"];
        [ftask setArguments:[NSArray arrayWithObjects:@"-c", farg, nil]];
        [ftask launch];		// fetch live id
        [ftask waitUntilExit];
        if([ftask terminationStatus])
        {
            [ftask release];
            NSLog(@"failed NSTask");
            self.errStr = @"Failed to send user options to server";
            return;
        }
        else
        {
            NSFileHandle *fhand = [fpipe fileHandleForReading];
            
            NSData *data = [fhand readDataToEndOfFile];	
            [ftask release];
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            self.liveId = [self jsonVal:jsonString key:@"live-id"];
            if(self.liveId.length)
                break;
            else 
            {
                self.errStr =@"Failed to retrieve live-id";
                return;
            }
        }
    }
    if(!cancelled)
        [self curlGetauth];
    // call error method of app which calls error method of sessionController
    if(self.errStr.length)
    {
        NSString *errMsg = [errStr copy];
        self.errStr = nil;
        [[ScoutWindowController sharedScout] 
         performSelectorOnMainThread:@selector(errOnConnect:)   
         withObject:errMsg  waitUntilDone:NO];
    }
    [pool release];
}

-(NSString *)jsonVal:(NSString *)json key:(NSString *)key
{
    const char *str = [json UTF8String];
    const char *kk = [key UTF8String];
    const char *kstr = strstr(str,kk);
    if(!kstr)
        return @"";
    
    kstr += [key length] + 2;   // skip over the key, end quote and colon
    if(*kstr == ' ')
        kstr++;
    char *cstr = malloc(100);
    int indx=0;
    if(*kstr == '"')
    {
        // gather chars up to end quote
        kstr++;
        while(*kstr != '"')
        {
            cstr[indx] = *kstr;
            indx++; kstr++;
        }
    }
    else    // value is an int 
    {
        // gather chars up to end comma or right brace
        while(*kstr != ',' && *kstr != '}')
        {
            cstr[indx] = *kstr;
            indx++; kstr++;
        }
    }
    cstr[indx] = 0;
    NSString *ret = [NSString stringWithCString:cstr encoding:NSUTF8StringEncoding];
    free(cstr);
    return ret;
}

-(void)cancelPreAuthorize
{
    self.cancelled = YES;
    self.errStr = @"Connection attempt was cancelled";
}

// return json object for vnc connection
- (NSString *)credStr
{
    NSString *js = [[NSString stringWithFormat:@"{\"job-id\":\"%@\",\"secret\":\"%@\"}\n",self.jobId,self.secret]retain];
    return js;
}


// poll til we get secret/jobid
-(void)curlGetauth
{    
	NSString *farg = [NSString stringWithFormat:@"curl 'https://%@:%@@saucelabs.com/scout/live/%@/status?secret&'", self.user, self.ukey, self.liveId ];

    while(1)    // use live-id to get job-id
    {
        if(cancelled)
        {
            self.errStr = @"Connecting was cancelled";
            break;
        }
        NSTask *ftask = [[NSTask alloc] init];
        NSPipe *fpipe = [NSPipe pipe];
        [ftask setStandardOutput:fpipe];
        [ftask setLaunchPath:@"/bin/bash"];
        [ftask setArguments:[NSArray arrayWithObjects:@"-c", farg, nil]];
        [ftask launch];		// fetch job-id and secret server
        [ftask waitUntilExit];
        if([ftask terminationStatus])
        {
            NSLog(@"failed NSTask");
            self.errStr =  @"Failed to request job-id";
            break;
        }
        else
        {
            NSFileHandle *fhand = [fpipe fileHandleForReading];
            
            NSData *data = [fhand readDataToEndOfFile];		 
            [ftask release];
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            self.secret = [self jsonVal:jsonString key:@"video-secret"];
            self.jobId  = [self jsonVal:jsonString key:@"job-id"];
            if(secret.length)
            {
                self.errStr = @"";     //  got job-id ok
                [[RFBConnectionManager sharedManager] performSelectorOnMainThread:@selector(connectToServer)   withObject:nil  waitUntilDone:NO];
                break;
            }
            
        }
    }
}

// remove session being close from heartbeat array
-(void)sessionClosed:(id)connection
{
	int len = [credArr count];
    NSDictionary *sdict;
    
    for(int i=0;i<len;i++)
    {
        sdict = [credArr objectAtIndex:i];
        if([sdict objectForKey:@"connection"] == connection)
        {
            [credArr removeObjectAtIndex:i];
            return;
        }
    }
}

// return get info for a view; also used to determine if tab has an active session
-(NSDictionary *)sessionInfo:(id)view
{
	int len = [credArr count];
    NSDictionary *sdict;
    
    for(int i=0;i<len;i++)
    {
        sdict = [credArr objectAtIndex:i];
        if([sdict objectForKey:@"view"] == view)
        {
            return sdict;
        }
    }
    return nil;
}

-(void)setvmsize:(NSSize)size
{
    NSMutableDictionary *sdict = [credArr lastObject];
    NSString *str = [NSString stringWithFormat:@"%.0fx%.0f",size.width,size.height];
    [sdict setValue:str forKey:@"size"];
    [[[ScoutWindowController sharedScout] vmsize] setStringValue:str];
}

// array for each session/tab - 
//  session for closing session 
//  liveId for heartbeat
//  osbrowserversion string for setting status when switching tabs
//  view to know which tab is becoming active
//  user, authkey, job-id, os, browser, and browserversion taken from most recent preauthorization
-(void)setSessionInfo:(id)connection view:(id)view
{
    NSString *osbvStr = [NSString stringWithFormat:@"%@/%@ %@",os,browser,browserVersion];
    [[[ScoutWindowController sharedScout] osbrowser] setStringValue:osbvStr];
    
    NSMutableDictionary *sdict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
                    connection,@"connection", view, @"view", liveId, @"liveId",
                    user, @"user", ukey, @"ukey", jobId, @"jobId",
                    osbvStr, @"osbv", urlStr, @"url", 
                    os, @"os", browser, @"browser", browserVersion, @"browserVersion", 
                    @"2:00:00", @"remainingTime", nil];
    
    if(!credArr)
    {
        credArr = [[[NSMutableArray alloc] init] retain];
    }
    [credArr addObject:sdict];
    [sdict release];
}

-(NSString *)remainingTimeStr:(int)remaining
{
    if(!remaining)
        return @"";
    
    int hr = remaining / 3600;
    int min = (remaining % 3600)/60;
    int sec = remaining % 60;

    NSString *hrstr, *minstr, *secstr;

    if(hr)
        hrstr = [NSString stringWithFormat:@"%d",hr];
    else
        hrstr = @"";        
    if(min<10)
        minstr = [NSString stringWithFormat:@"0%d",min];
    else
        minstr = [NSString stringWithFormat:@"%d",min];
    if(sec<10)
        secstr = [NSString stringWithFormat:@"0%d",sec];
    else
        secstr = [NSString stringWithFormat:@"%d",sec];
    NSString *str = [NSString stringWithFormat:@"%@:%@:%@",hrstr,minstr,secstr];
    return str;
}

-(void)startHeartbeat       // 1 minute is ok; at 2 minutes, server times out
{    
    if(!self.timer)    
        self.timer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(heartbeat:) userInfo:nil repeats:YES];
}

-(void)cancelHeartbeat
{
    if(![credArr count])    // only stop heartbeat if no sessions are active
    {
        cancelled = YES;
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)heartbeat:(NSTimer*)tm
{    
	NSEnumerator *credEnumerator = [credArr objectEnumerator];
    NSMutableDictionary *sdict;
    
    if(![credArr count])
    {
        [self cancelHeartbeat];
        return;        
    }
    
	while ( sdict = (NSMutableDictionary*)[credEnumerator nextObject] )
    {
        NSString *aliveid = [sdict objectForKey:@"liveId"];
                             
        NSString *farg = [NSString stringWithFormat:@"curl 'https://saucelabs.com/scout/live/%@/status?auth_username=%@&auth_access_key=%@'", aliveid, self.user, self.ukey];
        
        while(1)    
        {
            if(cancelled)
                return;

            NSTask *ftask = [[NSTask alloc] init];
            NSPipe *fpipe = [NSPipe pipe];
            [ftask setStandardOutput:fpipe];
            [ftask setLaunchPath:@"/bin/bash"];
            [ftask setArguments:[NSArray arrayWithObjects:@"-c", farg, nil]];
            [ftask launch];		// fetch job-id and secret server
            [ftask waitUntilExit];
            if([ftask terminationStatus])
            {
                self.errStr = @"failed NSTask in heartbeat";
                [self cancelHeartbeat];
                [ftask release];
                break;
            }
            else
            {
                NSFileHandle *fhand = [fpipe fileHandleForReading];
                
                NSData *data = [fhand readDataToEndOfFile];		 
                [ftask release];
                NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSString *status = [self jsonVal:jsonString key:@"status"];
                if([status isEqualToString:@"in progress"])
                {
                    id ssn = [sdict objectForKey:@"connection"];
                    Session *session = [[ScoutWindowController sharedScout] curSession];
                    NSString *remaining = [self jsonVal:jsonString key:@"remaining-time"];
                    // show in status
                    if([remaining length])
                    {
                        NSString *str = [self remainingTimeStr:[remaining intValue]];
                        [sdict setObject:str forKey:@"remainingTime"];
                        if(ssn == [session connection])
                        {
                            NSTextField *tf = [[ScoutWindowController sharedScout] timeRemainingStat];
                            [tf setStringValue:str];
                            tf = [[ScoutWindowController sharedScout] timeRemainingMsg];
                            str = [NSString stringWithFormat:@"%@ rem.",str];
                            [tf setStringValue:str];                        
                        }
                    }
                    break;                
                }
                else
                {
                    self.errStr = @"Heartbeat doesn't say 'in progress'";
                    [self cancelHeartbeat];
                    break;
                }
            }
        }
    }
}

- (BOOL)checkUserLogin:(NSString *)uuser  key:(NSString*)kkey
{
    NSString *farg = [NSString stringWithFormat:@"curl 'https://%@:%@@saucelabs.com/rest/v1/%@/jobs'", uuser, kkey, uuser];
    
    NSTask *ftask = [[NSTask alloc] init];
    NSPipe *fpipe = [NSPipe pipe];
    [ftask setStandardOutput:fpipe];
    [ftask setLaunchPath:@"/bin/bash"];
    [ftask setArguments:[NSArray arrayWithObjects:@"-c", farg, nil]];
    [ftask launch];		// fetch live id
    [ftask waitUntilExit];
    if([ftask terminationStatus])
    {
        self.errStr = @"Failed NSTask in checkUserLogin";
    }
    else
    {
        NSFileHandle *fhand = [fpipe fileHandleForReading];
        
        NSData *data = [fhand readDataToEndOfFile];		 
        [ftask release];
        NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSRange range = [jsonString rangeOfString:@"error"];
        if(!range.length)
        {
            self.user = uuser;
            self.ukey = kkey;
            return YES;
        }
        else 
        {
            self.errStr = @"Failed server authentication";
        }
    }
    return NO;
}

- (void)signupNew:(NSString*)uuserNew passNew:(NSString*)upassNew 
         emailNew:(NSString*)uemailNew
{    
    self.userNew = uuserNew;
    self.passNew = upassNew;
    self.emailNew = uemailNew;
    
    NSString *farg = [NSString stringWithFormat:@"curl -X POST http://saucelabs.com/rest/v1/users -H 'Content-Type: application/json' -d '{\"username\":\"%@\", \"password\":\"%@\",\"name\":\"\",\"email\":\"%@\",\"token\":\"0E44EF6E-B170-4CA0-8264-78FD9E49E5CD\"}'",self.userNew, self.passNew, self.emailNew];
     
    self.errStr = @"";
    while(1)
    {
        if(cancelled)
        {
            self.errStr = @"Connecting was Cancelled";
            break;
        }

        NSTask *ftask = [[NSTask alloc] init];
        NSPipe *fpipe = [NSPipe pipe];
        [ftask setStandardOutput:fpipe];
        [ftask setLaunchPath:@"/bin/bash"];
        [ftask setArguments:[NSArray arrayWithObjects:@"-c", farg, nil]];
        [ftask launch];		// fetch live id
        [ftask waitUntilExit];
        if([ftask terminationStatus])
        {
            self.errStr = @"Failed NSTask in signupNew";
            [ftask release];
            break;
        }
        else
        {
            NSFileHandle *fhand = [fpipe fileHandleForReading];
            
            NSData *data = [fhand readDataToEndOfFile];		 
            [ftask release];
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *akey = [self jsonVal:jsonString key:@"access_key"];
            if(akey.length)
            {
                self.user = self.userNew;
                self.ukey = akey;
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:self.user  forKey:kUsername];
                [defaults setObject:self.ukey  forKey:kAccountkey];
                [[NSApp delegate] performSelectorOnMainThread:@selector(newUserAuthorized:)   
                                        withObject:nil  waitUntilDone:NO];
                break;
            }
        }
    }    
}

- (void)postSnapshotBug:(id)view snapName:(NSString *)snapName  
               title:(NSString *)title desc:(NSString *)desc
{    
    NSDictionary *sdict = [self sessionInfo:view];
    NSString *aliveid = [sdict objectForKey:@"liveId"];
    NSString *auser = [sdict objectForKey:@"user"];
    NSString *akey = [sdict objectForKey:@"ukey"];


    NSString *farg = [NSString stringWithFormat:@"curl 'https://%@:%@@saucelabs.com/scout/live/%@/reportbug?&ssname=%@&title=%@&description=%@'", auser, akey, aliveid, snapName, title, desc];
    
    self.errStr = @"";
    while(1)
    {
        if(cancelled)
        {
            self.errStr = @"Post snapshotbug was cancelled";
            break;
        }
        
        NSTask *ftask = [[NSTask alloc] init];
        NSPipe *fpipe = [NSPipe pipe];
        [ftask setStandardOutput:fpipe];
        [ftask setLaunchPath:@"/bin/bash"];
        [ftask setArguments:[NSArray arrayWithObjects:@"-c", farg, nil]];
        [ftask launch];		// fetch live id
        [ftask waitUntilExit];
        if([ftask terminationStatus])
        {
            self.errStr = @"Failed NSTask in postSnapshotBug";
            [ftask release];
            break;
        }
        else
        {
            NSFileHandle *fhand = [fpipe fileHandleForReading];
            
            NSData *data = [fhand readDataToEndOfFile];		 
            [ftask release];
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *snapId = [self jsonVal:jsonString key:@"c"];            
            if(snapId)
            {
                NSLog(@"got snap id:%@",snapId);
                [[ScoutWindowController sharedScout] snapshotSuccess];
            }
            else {
                self.errStr = @"Failed to get snapshot id";
            }
            break;
        }
    }        
}

- (void)snapshotBug:(id)view  title:(NSString *)title desc:(NSString *)desc
{
    NSDictionary *sdict = [self sessionInfo:view];
    NSString *aliveid = [sdict objectForKey:@"liveId"];
    NSString *auser = [sdict objectForKey:@"user"];
    NSString *akey = [sdict objectForKey:@"ukey"];
    NSString *ajobid = [sdict objectForKey:@"jobId"];
    
    NSString *farg = [NSString stringWithFormat:@"curl 'https://%@:%@@saucelabs.com/scout/live/%@/sendcommand?&1=getScreenshotName&sessionId=%@&cmd=captureScreenshot'", 
                      auser, akey, aliveid, ajobid];

    self.errStr = @"";
    while(1)
    {
        if(cancelled)
        {
            self.errStr = @"SnapshotBug was Cancelled";
            break;
        }
        
        NSTask *ftask = [[NSTask alloc] init];
        NSPipe *fpipe = [NSPipe pipe];
        [ftask setStandardOutput:fpipe];
        [ftask setLaunchPath:@"/bin/bash"];
        [ftask setArguments:[NSArray arrayWithObjects:@"-c", farg, nil]];
        [ftask launch];		// fetch live id
        [ftask waitUntilExit];
        if([ftask terminationStatus])
        {
            self.errStr = @"Failed NSTask in snapshotBug";
            break;
        }
        else
        {
            NSFileHandle *fhand = [fpipe fileHandleForReading];
            
            NSData *data = [fhand readDataToEndOfFile];		 
            [ftask release];
            NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            NSString *rstr = [self jsonVal:jsonString key:@"success"];            
            BOOL res = [rstr boolValue];
            if(res)
            {
                NSString *msg = [self jsonVal:jsonString key:@"message"];            
                [self postSnapshotBug:view snapName:msg title:title desc:desc];
                break;
            }
            else
            {
                self.errStr = @"Failed to get snapshot name";
                break;
            }                
        }
    }    
}


@end
