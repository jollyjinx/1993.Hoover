#import <Foundation/Foundation.h>
#import <HooverFramework/HTMLDocument.h>

#define URLBEGIN 	@"<!--URL:http://"
#define DATABEGIN	@"-->"

#define BUFFERSIZE	8192

int main (int argc, char** argv, char** env)
{
    NSAutoreleasePool		*pool;
    NSArray			*commandlineArguments;
    NSFileHandle 		*stdoutFilehandle;

#if LIB_FOUNDATION_LIBRARY
    [NSProcessInfo initializeWithArguments:argv count:argc environment:env];
#endif

    pool = [[NSAutoreleasePool alloc] init];
    stdoutFilehandle 	 = [NSFileHandle fileHandleWithStandardOutput];
    commandlineArguments = [[NSProcessInfo processInfo] arguments];


    if( 1 >= [commandlineArguments count] )
    {
        FILE *inputstream;

        inputstream=fdopen(0,"r");
        
        while( !feof(inputstream) )
        {
            char urlname[1024];
            char urldate[1024];
            int	urlsize;

            if( 2 == fscanf(inputstream,"Hoover-Url: %s Size: %d",urlname,&urlsize) )
            {
                void *urlcontent;
                int readsize;
                
                NSLog(@"Reading url %s %d",urlname,urlsize);
                
                if( ! (urlcontent = (void*)calloc(1,urlsize)) )
                {
                    NSLog(@"Couldn't malloc contentsize\n");
                    exit(1);
                }
                if( urlsize != (readsize = fread(urlcontent,1,urlsize,inputstream)) )
                {
                    NSLog(@"Url contents too short %d\n",readsize);
                    exit(1);
                }
                else
                {
                    NSAutoreleasePool   *innerPool = [[NSAutoreleasePool alloc] init];
                    HTMLDocument	*htmlDocument = [HTMLDocument documentWithData:[[NSString stringWithData:[NSData dataWithBytesNoCopy:urlcontent length: readsize]
                                                                    encoding:NSISOLatin1StringEncoding]
dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES] encoding: NSUnicodeStringEncoding];
                    //NSLog(@"Document looks like:%@",[[htmlDocument htmlArray] description]);
                    [stdoutFilehandle writeData:[[NSString stringWithFormat:@"\nHoover-Url: http://%s\n",urlname] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    [stdoutFilehandle writeData:[@"Hoover-TextualRepresentation:\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
          
                    [stdoutFilehandle writeData:[[htmlDocument textRepresentation] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    [innerPool release];

                }
            }
            else
            {
                fgetc(inputstream);
            }
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
            NSData	*fileData = [NSData dataWithContentsOfMappedFile:fileName];

            NSLog(@"File %@ read.",fileName);

            if( fileData )
            {
                NSAutoreleasePool	*outerPool = [[NSAutoreleasePool alloc] init];
                NSString		*fileAsString;
                NSScanner		*fileScanner;

                fileAsString = [NSString stringWithData:fileData encoding:NSISOLatin1StringEncoding];
                //fileAsString = [NSString stringWithData:fileData encoding:[NSString defaultCStringEncoding]];c
                fileScanner = [NSScanner scannerWithString:fileAsString];
                NSLog(@"Converted to UNICODE.",fileName);

                while( ! [fileScanner isAtEnd] )
                {
                    NSAutoreleasePool	*innerPool = [[NSAutoreleasePool alloc] init];
                    NSString		*urlName;

                    [fileScanner scanUpToString:URLBEGIN intoString:NULL];
                    if( [fileScanner scanString:URLBEGIN intoString:NULL] )
                    {
                        if( [fileScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:&urlName] )
                        {
                            NSLog(@"Reading url:%@",urlName);
                            [fileScanner scanUpToString:DATABEGIN intoString:NULL];
                            if( [fileScanner scanString:DATABEGIN intoString:NULL] )
                            {
                                NSString *documentString;

                                if( [fileScanner scanUpToString:URLBEGIN intoString:&documentString] )
                                {
                                    HTMLDocument *htmlDocument;

                                    if( htmlDocument = [HTMLDocument documentWithData:[documentString dataUsingEncoding:NSUnicodeStringEncoding allowLossyConversion:YES] encoding: NSUnicodeStringEncoding] )
                                    {
                                        NSString *urlAsString  = [htmlDocument textRepresentation];

                                        //NSLog(@"Document looks like:%@",[[htmlDocument htmlArray] description]);
                                        [stdoutFilehandle writeData:[[NSString stringWithFormat:@"Hoover-Url: http://%@\n",urlName] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                                        //write(1,[urlAsString cString],[urlAsString cStringLength]);
                                        
                                        [stdoutFilehandle writeData:[urlAsString dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
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
