
#import <Foundation/Foundation.h>
#import "OutputFileScanner.h"


int main (int argc, const char *argv[])
{
    NSString			*commandlineArgument;
    NSString			*configurationFileName=nil;
    OutputFileScanner	*outputFileScanner;
    NSEnumerator		*enumerator;
    
    NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
  	NSMutableArray		*filesToRead = [NSMutableArray array];

#if LIB_FOUNDATION_LIBRARY
    [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

{
	NSLock *myLock = [[NSLock alloc] init];
	
	[myLock lock];
	NSLog(@"Lock now locked");
	[myLock unlock];
	NSLog(@"Lock now unlocked");
	[myLock release];
	NSLog(@"Lock now released");
}



	enumerator = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
    [enumerator nextObject]; // throw away first argument
	while( commandlineArgument = [enumerator nextObject])
    {
        if( [commandlineArgument isEqual:@"-database"] && (commandlineArgument = [enumerator nextObject]) )
        {
            configurationFileName = commandlineArgument;
        }
        else
        {
            [filesToRead addObject:commandlineArgument];
        }
    }

    outputFileScanner = [[OutputFileScanner alloc] initWithContentsOfDatabase:configurationFileName];
    [outputFileScanner readFiles:filesToRead];
    [outputFileScanner writeDatabase:@"outputdatabase"];
    [outputFileScanner release];
    [pool release];
    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
