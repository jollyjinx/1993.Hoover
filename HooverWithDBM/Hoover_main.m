
#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>
#import "HooverController.h"
#import <sys/signal.h>


HooverController	*hoover;


void signalhandler(int signalnumber)
{
    NSLog(@"Received signal %i\n", signalnumber);
    [hoover save];
    exit(1);
}


void signalusr1(int signalnumber)
{
    NSLog(@"Received signal %i\n", signalnumber);
    [hoover showCurrentStatus];
}

int main(int argc, const char *argv[])
{
    NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    NSDictionary	*configurationDictionary;
    NSString		*configurationFileName = @"HooverConfiguration";
    NSString		*commandlineArgument;
    NSEnumerator	*enumerator = [[[NSProcessInfo processInfo] arguments] objectEnumerator];

    
    while( commandlineArgument = [enumerator nextObject])
    {
        if( [commandlineArgument isEqual:@"-configuration"] && (commandlineArgument = [enumerator nextObject]) )
        {
            configurationFileName = commandlineArgument;
        }
    }

   if( nil == ( configurationDictionary = [NSDictionary dictionaryWithContentsOfFile:configurationFileName] ))
   {
       NSLog(@"Can't read configuration file: %@",configurationFileName);
       NSLog(@"Usage: %s [-configuration filename]\n\tIf no configuration is omitted 'HooverConfiguration' is used.\n",argv[0]);
   }
   else
   {
        
       hoover = [[HooverController alloc] initWithConfiguration:configurationDictionary];
       NSLog(@"Enableing Signals now.");
#ifdef GNUSTEP
       [NSThread detachNewThreadSelector:@selector(putWorkInSendingUrlsQueue)
                                toTarget:hoover
                              withObject:nil];
         signal(SIGPIPE, SIG_IGN);
         signal(SIGTERM, SIG_IGN);
         signal(SIGINT, SIG_IGN);
         signal(SIGUSR1, SIG_IGN);
	
        signal(SIGUSR1, *signalusr1 );
        {
                sigset_t	aset;

                sigemptyset(&aset);
                sigaddset(&aset, SIGHUP);
                pthread_sigmask(SIG_UNBLOCK, &aset, NULL);
        }
       while(1)
           [NSThread sleepUntilDate:[NSDate distantFuture]];
#else
        signal(SIGTERM, signalhandler);
        signal(SIGINT, signalhandler);
        signal(SIGUSR1, signalusr1);
        [hoover putWorkInSendingUrlsQueue];
#endif
        [hoover release];
   }

   [pool release];
   exit(0);       // insure the process exit status is 0
   return 0;      // ...and make main fit the ANSI spec.
}
