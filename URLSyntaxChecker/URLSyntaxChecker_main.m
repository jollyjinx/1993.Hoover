
#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>

#define MAXURLLENGTH 10000

int main (int argc, const char *argv[])
{
    NSAutoreleasePool		*pool;
    NSArray			*commandlineArguments;
    NSFileHandle 		*stdoutFilehandle;
    FILE	 		*stdinstream = fdopen(0,"r");
    static char			linebuffer[MAXURLLENGTH];


    pool = [[NSAutoreleasePool alloc] init];
    stdoutFilehandle = [NSFileHandle fileHandleWithStandardOutput];
    commandlineArguments = [[NSProcessInfo processInfo] arguments];

    if( [commandlineArguments count] > 1 )
    {
        NSLog(@"\n\nUsage:\n\t%@ <stdin >stdout \nEvery line in the inputfile will be treated as if it were an URL. If the URL is correct ( at least to some extend ) the URL will be printed out in normalized form to stdout.",[[commandlineArguments objectAtIndex:0] lastPathComponent]);
        exit(0);
    }

    while( !feof(stdinstream) )
    {
        NSAutoreleasePool	*innerPool = [[NSAutoreleasePool alloc] init];


        if( NULL != fgets(linebuffer, MAXURLLENGTH-1, stdinstream) )
        {
            NSMutableDictionary	*aLink=nil;

            linebuffer[strlen(linebuffer)-1]=0;
            //NSLog(@"String read: %@",[NSString stringWithCString:linebuffer]);
            if( aLink = [HTMLScanner getDictionaryFromURL:[NSString stringWithCString:linebuffer] baseUrl:nil] )
            {
                //NSLog(@"Host : %@ has Address : %@ ",[aLink objectForKey:@"host"],[[NSHost hostWithName:[NSString stringWithFormat:@"%@.",[aLink objectForKey:@"host"]]] address]);
                //NSLog(@"URLObject contains: %@",[aLink description]);
                [stdoutFilehandle writeData:[@"http://" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];

                [stdoutFilehandle writeData:[[aLink objectForKey:@"host"] dataUsingEncoding:NSISOLatin1StringEncoding
                                                                       allowLossyConversion:YES]];
                if( ![@"80" isEqual:[aLink objectForKey:@"port"]] )
                {
                    [stdoutFilehandle writeData:[@":" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    [stdoutFilehandle writeData:[[aLink objectForKey:@"port"] dataUsingEncoding:NSISOLatin1StringEncoding
                                                                                  allowLossyConversion:YES]];
                }
                [stdoutFilehandle writeData:[[aLink objectForKey:@"path"] dataUsingEncoding:NSISOLatin1StringEncoding
                                                                       allowLossyConversion:YES]];
                [stdoutFilehandle writeData:[@"\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            }
        }
        [innerPool release];
    }
    [pool release];

    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
