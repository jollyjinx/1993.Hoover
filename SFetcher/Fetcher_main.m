
#import <Foundation/Foundation.h>

#define CONNECTIONNAME @"Hoover"

@class FetcherController;

#import "Fetcher.h"
#import "FetcherController.h"

@protocol FetcherControllerProtocol
- (oneway void)retrievedUrl:(bycopy NSMutableDictionary *)url;
@end



int main (int argc, const char *argv[])
{
    NSAutoreleasePool		*pool;
    NSConnection		*connectionObject;
    FetcherController		*hooverObject;
    Fetcher			*localFetcher;
    
    NSEnumerator		*enumerator;
    NSString			*commandlineArgument;
    NSString			*hostName;
    int				maximumthreads;

    pool = [[NSAutoreleasePool alloc] init];

    hostName = nil;
    maximumthreads = 50;
    enumerator = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
    while( commandlineArgument =  [enumerator nextObject])
    {
        if( [commandlineArgument isEqual:@"-host"] && (commandlineArgument = [enumerator nextObject]) )
        {
            hostName = [[commandlineArgument retain] autorelease];
        }
        if( [commandlineArgument isEqual:@"-threads"] && (commandlineArgument = [enumerator nextObject]) )
        {
            maximumthreads = [commandlineArgument intValue];
        }
    }

    if( connectionObject = [NSConnection connectionWithRegisteredName:CONNECTIONNAME host:hostName])
    {
        NSLog(@"Got connection");

        [connectionObject setIndependentConversationQueueing:NO];

        hooverObject = (FetcherController *)[connectionObject rootProxy];

        if(! [hooverObject respondsToSelector:@selector(addFetcher:)])
        {
            NSLog(@"Remote FetcherController (hooverObject)does not respond to @selector(addFetcher:)");
            exit(1);
        }

        localFetcher = [[Fetcher alloc] initWithMaximumConnections:maximumthreads
                                                      hooverObject:hooverObject];
        [localFetcher detachWorkingThreads];

        [hooverObject addFetcher:localFetcher];
        [(NSDistantObject *)hooverObject setProtocolForProxy:@protocol(FetcherControllerProtocol)];
        while([connectionObject isValid])
              [[NSRunLoop currentRunLoop] runMode:NSConnectionReplyMode
                                 beforeDate:[[NSRunLoop currentRunLoop] limitDateForMode: NSConnectionReplyMode]];
        
        NSLog(@"Lost connection");
    }
    else
    {
        NSLog(@"Can't connect to server on host:%@", hostName);
    }
    [pool release];

    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
