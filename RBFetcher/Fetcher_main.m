
#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>
#import <signal.h>
#import <sys/time.h>
#import <unistd.h>
#import "Fetcher.h"
#import "HTTPClient.h"

#define HOOVER_PORT 20001	


@protocol FetcherControllerProtocol
- (void)retrievedUrl:(bycopy NSMutableDictionary *)url;
@end


int signalhandler(int signal)
{
    NSLog(@"Couldn't get a connection");
    exit(0);
}

int main (int argc, const char *argv[])
{
    NSAutoreleasePool		*pool;
    Fetcher			*localFetcher;
    
    NSEnumerator		*enumerator;
    NSString			*commandlineArgument;
    TCPConnection		*inPort;
    TCPConnection		*outPort;
    NSString		*hostName;
    int			maximumthreads;

    objc_setMultithreaded(YES);
    pool = [[NSAutoreleasePool alloc] init];

    [HTTPClient class];
    
    hostName = nil;
    
    maximumthreads = 1;
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

    if( nil == hostName )
        hostName = @"localhost";


    {
        HFUDPSocket		*hooverSocket;
        NSMutableDictionary	*informationDictionary = [NSMutableDictionary dictionary];

        [informationDictionary	setObject:[[NSHost currentHost] name] forKey:@"hostname"];

        inPort = [TCPConnection tcpConnection];
        outPort = [TCPConnection tcpConnection];
        [inPort startListeningOnLocalPort];
        [outPort startListeningOnLocalPort];


        [informationDictionary setObject:[NSNumber numberWithInt:[inPort localPortNumber]] forKey:@"inport"];
        [informationDictionary setObject:[NSNumber numberWithInt:[outPort localPortNumber]] forKey:@"outport"];
        [informationDictionary setObject:[NSNumber numberWithInt:maximumthreads] forKey:@"maximumworkload"];

        hooverSocket = [HFUDPSocket socket];
        [hooverSocket connectToHost:[NSHost hostWithName:hostName] port: HOOVER_PORT];
        [hooverSocket writeData:[NSArchiver archivedDataWithRootObject:informationDictionary]];



        {
            static struct	itimerval	alrm,oalrm;

            signal(SIGALRM	,(void *)signalhandler);

            //siginterrupt(SIGALRM,1);
            alrm.it_interval.tv_sec=0;
            alrm.it_interval.tv_usec=0;	
            alrm.it_value.tv_sec=5;
            alrm.it_value.tv_usec=0;
            if(setitimer(ITIMER_REAL,&alrm,&oalrm)==-1)
                    exit(1);

        }
        [inPort acceptConnection];
        [outPort acceptConnection];
        signal(SIGALRM,SIG_IGN);
        siginterrupt(SIGALRM,0);

        #if DEBUG
        NSLog(@"Fetcher_main: Got connection to HooverController.");
        #endif
        
        localFetcher = [[Fetcher alloc] initWithInPort:inPort outPort:outPort threads:maximumthreads];
    }
    [pool release];

    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}


