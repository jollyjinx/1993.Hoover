
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
		NSString		*fileName;
		
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
    	while( fileName = [commandlineEnumerator nextObject] )
    	{
        	NSData				*fileData = [NSData dataWithContentsOfMappedFile:fileName];
           	NSLog(@"Reading file %@:",fileName);

       		if( fileData )
        	{
            	NSAutoreleasePool	*outerPool = [[NSAutoreleasePool alloc] init];
            	NSString			*fileAsString;
            	NSScanner			*fileScanner;

            	//fileAsString = [NSString stringWithData:fileData encoding:NSISOLatin1StringEncoding];
            	fileAsString = [NSString stringWithData:fileData encoding:[NSString defaultCStringEncoding]];
            	fileScanner = [NSScanner scannerWithString:fileAsString];

            	while( ! [fileScanner isAtEnd] )
            	{
                	NSAutoreleasePool	*innerPool = [[NSAutoreleasePool alloc] init];
                	NSString			*urlName;

                	[fileScanner scanUpToString:@"Hoover-Url:" intoString:NULL];
                	if( [fileScanner scanString:@"Hoover-Url:" intoString:NULL] )
                	{
                    	if( [fileScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&urlName] )
                    	{
                        	NSLog(@"reading url:%@",urlName);
                        	[fileScanner scanUpToString:@"Hoover-Httpdata:\n" intoString:NULL];
                        	if( [fileScanner scanString:@"Hoover-Httpdata:\n" intoString:NULL] )
                        	{
                            	NSString *documentString;

                            	if( [fileScanner scanUpToString:@"Hoover-Url:" intoString:&documentString] )
                            	{
                                	HTMLDocument *htmlDocument;
                					
									if( htmlDocument = [HTMLDocument documentWithData:[documentString dataUsingEncoding:NSISOLatin1StringEncoding]] )
                					{
										NSString *urlAsString  = [htmlDocument textRepresentation];
										
										//NSLog(@"Document looks like:%@",[[htmlDocument htmlArray] description]);
										[stdoutFilehandle writeData:[[NSString stringWithFormat:@"Hoover-Url:%@\n",urlName] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:NO]];
                    					write(1,[urlAsString cString],[urlAsString cStringLength]);
										[stdoutFilehandle writeData:[urlAsString dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:NO]];
                					}
									else
									{
										NSLog(@"Couldn't create document Object.");
									}

                            	}
                            	else
                            	{
                                	NSLog(@"Url did not contain anything %@",urlName);
                            	}
                        	}
                    	}
						else
                    	{
                        	NSLog(@"Did not get urlname at : %d",[fileScanner scanLocation]);
                    	}
                	}
                	[innerPool release];
            	}
            	[outerPool release];
        	}
    	} 
    }
    [pool release];

    exit(0);       // insure the process exit status is 0
    return 0;      // ...and make main fit the ANSI spec.
}
