
#import "OutputFileScanner.h"

#import <Foundation/Foundation.h>


int main (int argc, const char *argv[])
{
    NSString			*commandlineArgument;
    NSString			*configurationFileName=nil;
    OutputFileScanner	*outputFileScanner;
    
    NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
  	NSMutableArray		*filesToRead = [NSMutableArray array];
    NSEnumerator		*enumerator = [[[NSProcessInfo processInfo] arguments] objectEnumerator];

    
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
