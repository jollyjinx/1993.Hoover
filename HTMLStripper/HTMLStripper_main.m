
#import <Foundation/Foundation.h>
#import <HooverFramework/HTMLDocument.h>


int main (int argc, char** argv, char** env)
{
	NSAutoreleasePool		*pool;
    NSArray					*commandlineArguments;
    NSFileHandle 			*stdoutFilehandle;

#if LIB_FOUNDATION_LIBRARY
    [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

    pool = [[NSAutoreleasePool alloc] init];
    stdoutFilehandle = [NSFileHandle fileHandleWithStandardOutput];
    commandlineArguments = [[NSProcessInfo processInfo] arguments];

    if( 1 >= [commandlineArguments count] )
    {
        HTMLDocument *htmlDocument;

        if( htmlDocument = [HTMLDocument documentWithData:[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile]] )
        {
            [stdoutFilehandle writeData:[[htmlDocument textRepresentation] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
        }
    }
    else
    {
        NSEnumerator	*commandlineEnumerator;
        NSString       	*commandlineArgument;

        commandlineEnumerator = [commandlineArguments objectEnumerator];
        while( commandlineArgument =  [commandlineEnumerator nextObject])
        {
            if( [commandlineArgument isEqual:@"--help"] )
            {
                NSLog(@"\n\nUsage:\n\t%@ [file1 file2 ...]\nor\t%@ <file\n\nThe file HTMLDocument.configuration gets read in for the %@. The syntax of this file is that of a propertyList ( see NeXT manuals ). The configurationfile consists of a dictionary of HTML-tags with an dictionary attached to each tag with the following entries:\n\ttagtext:\tthe named tag is replaced by the value of this string.\n\toptiontext:\tthe named tag is scanned for an option of this kind and replaced by the value of that option.\n\tlink:\tthe named tag is scanned for the option when looking for urls.( not used in HTMLScanner )\nThis is a simple HTMLDocument.configuration file:\n{\n\tp\t= { tagtext = \"\\n\" };\n\tbr\t= { tagtext = \"\\n\"; };\n\ttr\t= { tagtext = \"\\n\"; };\n\ttd\t= { tagtext = \"\\t\"; };\n\ta \t= { link = \"href\"; };\n\timg\t= { link = \"src\"; optiontext = \"alt\"; };\n\tframe\t= { link = \"src\"; optiontext = \"name\"; };\n}\n",[[commandlineArguments objectAtIndex:0] lastPathComponent],[[commandlineArguments objectAtIndex:0]lastPathComponent],[[commandlineArguments objectAtIndex:0]lastPathComponent]);

                exit(0);
            }
        }



        commandlineEnumerator = [commandlineArguments objectEnumerator];
        [commandlineEnumerator nextObject];
        while( commandlineArgument =  [commandlineEnumerator nextObject])
        {
            NSAutoreleasePool	*innerPool = [[NSAutoreleasePool alloc] init];
            NSData	*fileData;

            if( fileData = [NSData dataWithContentsOfFile:commandlineArgument] )
            {
                HTMLDocument *htmlDocument;

                if( htmlDocument = [HTMLDocument documentWithData:fileData] )
                {
                    [stdoutFilehandle writeData:[[htmlDocument textRepresentation] dataUsingEncoding:NSISOLatin1StringEncoding
                                                                                allowLossyConversion:YES]];
                }
            }
            else
            {
                NSLog(@"Can't get data from file: %@",commandlineArgument);
            }
            [innerPool release];
        }
    }
    [pool release];

    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
