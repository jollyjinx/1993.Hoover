/* HTMLDocument.m created by jolly on Tue 18-Nov-1997 */

#import <HooverFramework/HTMLDocument.h>

static NSDictionary 	*htmlDocumentConfiguration = nil;
static NSLock			*singleParseLock = nil;
static NSDictionary		*escapedCharactersDictionary = nil;
static NSCharacterSet	*tagCommandCharacterSet = nil;
static NSCharacterSet	*htmlCommandStopSet = nil;
static NSCharacterSet 	*optionCharacterSet = nil;

@implementation HTMLDocument

+ (void) initialize;
{
    htmlDocumentConfiguration 	= [[NSDictionary dictionaryWithContentsOfFile:@"HTMLDocument.configuration"] retain];
    escapedCharactersDictionary	= [[htmlDocumentConfiguration objectForKey:@"escapedCharacters"] retain];
    tagCommandCharacterSet		= [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"] retain];
    htmlCommandStopSet			= [[NSCharacterSet characterSetWithCharactersInString:@"<>"] retain];
    optionCharacterSet  		= [[NSCharacterSet characterSetWithCharactersInString:@" ="] retain];
	singleParseLock 			= [[NSLock alloc] init];
	
    NSLog(@"HTMLDocumentconfiguration looks like:\n%@",[htmlDocumentConfiguration description]);
}

+ (HTMLDocument *)documentWithData:(NSData *)htmlData;
{
    return [[[self alloc] initWithData:htmlData] autorelease];
}

+ (HTMLDocument *)documentWithData:(NSData *)htmlData encoding:(NSStringEncoding)encoding;
{
    return [[[self alloc] initWithData:htmlData encoding:encoding] autorelease];
}




+ (NSMutableString *)decodeHTMLTags:(NSString *)stringToDecode;
{
    NSScanner 		*htmlScanner = [NSScanner scannerWithString:stringToDecode];
    NSMutableString	*convertedString = [NSMutableString string];
		
    [htmlScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
	
    if(nil == escapedCharactersDictionary)
    {
        NSLog(@"HTMLDocument decodeHTMLTags: Can't read escapedCharactersDictionary, skipping conversion of &namedtags; .");
        return [stringToDecode mutableCopy];
    }

    while( NO == [htmlScanner isAtEnd] )
    {
        NSString	*notTaggedString;
        
		//NSLog(@"ScanPosition:%d",[htmlScanner scanLocation]);
        if( [htmlScanner scanUpToString:@"&" intoString:&notTaggedString] )
        {
            [convertedString appendString:notTaggedString];
        }
        if( [htmlScanner scanString:@"&" intoString:NULL] )
        {
            if( [htmlScanner scanString:@"#" intoString:NULL] )
            {
                int	integer;
                unichar	unicodechar;

                [htmlScanner setCaseSensitive:NO];
                if( [htmlScanner scanString:@"x" intoString:NULL] )
                {
                    if( [htmlScanner scanHexInt:&integer] )
                        [convertedString appendString:[NSString stringWithCharacters:&unicodechar length:1]];
                    else
                        NSLog(@"HTMLDocument decodeHTMLTags:couldn't scan hexInt in String: %@",stringToDecode);
                }
                else
                {
                    if( [htmlScanner scanInt:&integer] )
                        [convertedString appendString:[NSString stringWithCharacters:&unicodechar length:1]];
                    else
                        NSLog(@"HTMLDocument decodeHTMLTags:couldn't scan hexInt in String: %@",stringToDecode);
                }
                [htmlScanner setCaseSensitive:YES];
            	if( ! [htmlScanner scanString:@";" intoString:NULL] )
            	{
                	//NSLog(@"HTMLDocument decodeHTMLTags: TagCharacters not delimited, inserting missing ';'.",stringToDecode);
            	}
            }
            else
            {
                NSString *tagValue;

                if( ! [htmlScanner scanCharactersFromSet:tagCommandCharacterSet intoString:&tagValue] )
                {
                    NSLog(@"HTMLDocument decodeHTMLTags:couldn't scan any valid TagCharacters  in String. ( won't change )");
					[convertedString appendString:@"&"];
                }
                else
                {
					NSString *tagConversion;
					
                    if( ! (tagConversion = [escapedCharactersDictionary objectForKey:tagValue] ) )
                    {
                        NSLog(@"HTMLDocument decodeHTMLTags: Tag %@ not known ( won't change ).",tagValue);
						[convertedString appendString:@"&"];
						[convertedString appendString:tagValue];
                    }
                    else
                    {
                        [convertedString appendString:tagConversion];
            			 if( ! [htmlScanner scanString:@";" intoString:NULL] )
         				 {
							//NSLog(@"HTMLDocument decodeHTMLTags: TagCharacters not delimited, inserting missing ';'.",stringToDecode);
          				 }
                    }
                }
            }
        }
    }
    return convertedString;
}

- (id)initWithData:(NSData *)data encoding:(NSStringEncoding)encoding;
{
    [super init];

    if( ! (documentContent = [[NSString stringWithData:data encoding:encoding] retain]) )
        return nil;
    htmlArray = [[NSMutableArray alloc] init];
    return self;
}


- (id)initWithData:(NSData *)htmlData;
{
    return [self initWithData:htmlData encoding:[NSString defaultCStringEncoding]];
    return [self initWithData:htmlData encoding:NSISOLatin1StringEncoding];
}


- (void)dealloc;
{    
    [documentContent release];
    [htmlArray release];
    [super dealloc];
}


- (NSMutableArray *)htmlArray;
{
    NSScanner		*htmlScanner = [NSScanner scannerWithString:documentContent];

    if( [htmlArray count] )
        return htmlArray;
    //NSLog(@"DocumentSize:%d",[documentContent length]);
	
    [htmlScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];

	[singleParseLock lock];
    while( NO == [htmlScanner isAtEnd] )
    {
        NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
        NSString		*notTaggedString;
        NSString		*tagName;
        NSString		*tagValue;
        NSMutableArray		*htmlTagArray;
        
        if( [htmlScanner scanUpToString:@"<" intoString:&notTaggedString] )				// Scan up to '<' , that's a remark
        {
            [htmlArray addObject:notTaggedString];
        }
        else
        {												// Now we got a tagbegin '<'
            [htmlScanner scanString:@"<" intoString:NULL];

            if( [htmlScanner scanString:@"!-" intoString:NULL] )						//  Scan Remarks '<!-'
            {
                if( ! [htmlScanner scanUpToString:@"->" intoString:&tagValue] )
                {
                    NSLog(@"Found HTML remark without end %@",tagValue);
                }
                else
                {
                    htmlTagArray = [NSMutableArray arrayWithObjects:@"!-",tagValue,nil];
                    [htmlArray addObject:htmlTagArray];
                }
            }
            else
            {												// tagbegin is not a remark scan whole
                if( [htmlScanner scanUpToCharactersFromSet:htmlCommandStopSet intoString:&tagValue] )	// tag till next '<' or '>'
                {
                    NSScanner	*tagScanner = [NSScanner scannerWithString:tagValue];
                    NSString	*optionKey,*optionValue;

                    [tagScanner setCharactersToBeSkipped:nil];
                    if( [tagScanner scanUpToString:@" " intoString:&tagName] )
                    {
                        NSMutableDictionary *optionDictionary = [NSMutableDictionary dictionary];
                        htmlTagArray = [NSMutableArray arrayWithObjects:[tagName lowercaseString],optionDictionary,nil];
                        [htmlArray addObject:htmlTagArray];

                        while( NO == [tagScanner isAtEnd] )
                        {
                            [tagScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];	// Skip blanks
                            
                            if([tagScanner scanUpToCharactersFromSet:optionCharacterSet intoString:&optionKey])
                            {
                                [tagScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];	// Skip blanks

                                if(	[tagScanner scanString:@"=" intoString:NULL] )
                                {
                                    [tagScanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:NULL];	// Skip blanks

                                    if( [tagScanner scanString:@"'" intoString:NULL] )
                                    {
                                        if( [tagScanner scanUpToString:@"'" intoString:&optionValue] )							// read in: option=' ""vue'
                                        {
                                            [optionDictionary setObject:optionValue  forKey:[optionKey lowercaseString]];
                                            [tagScanner scanString:@"'" intoString:NULL];										// eat up the last \"
                                        }
                                    }
                                    else
                                    {
                                        if( [tagScanner scanString:@"\"" intoString:NULL] )
                                        {
                                            if( [tagScanner scanUpToString:@"\"" intoString:&optionValue] )						// read in: option="value"
                                            {
                                                [optionDictionary setObject:optionValue  forKey:[optionKey lowercaseString]];
                                                [tagScanner scanString:@"\"" intoString:NULL];									// eat up the last \"
                                            }
                                            else
                                                [optionDictionary setObject:@"" forKey:[optionKey lowercaseString]];			// option="" 
                                        }
                                        else
                                        {
                                            if( [tagScanner scanUpToCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]
                                                                        intoString:&optionValue] )  							// read in: option=value
                                            {
                                                [optionDictionary setObject:optionValue forKey:[optionKey lowercaseString]];
                                            }
                                        }
                                    }
                                }
                                else
                                {																								// option without value
                                    [optionDictionary setObject:[optionKey lowercaseString] forKey:[optionKey lowercaseString]];// gets stored
                                                                                                                                // in Dictionary option=option
                                }
                            }
                            else
                            {
                                //NSLog(@"Got option without characters in string:%@",tagValue);
                                [tagScanner scanCharactersFromSet:optionCharacterSet intoString:NULL];
                            }
                        }
                    }
                }																	// now the tag is scanned let's scan
                [htmlScanner scanString:@">" intoString:NULL];						// the rest
            }
        }
        [pool release];
   }
   [singleParseLock unlock];
   //NSLog(@"HTMLScanning done after %d bytes",[htmlScanner scanLocation]);
   return htmlArray;
}


- (NSMutableArray *)urlArray
{
    NSMutableArray	*urlArray = [NSMutableArray array];
    NSEnumerator	*objectEnumerator = [[self htmlArray] objectEnumerator];
	NSDictionary	*tagDictionary;
    NSMutableArray	*tagArray;
    NSString		*linkTag;
    NSString		*linkContent;

    
    while( tagArray = [objectEnumerator nextObject] )
    {
        if( ( [tagArray isKindOfClass:[NSArray class]] ) &&
            ( tagDictionary = [htmlDocumentConfiguration objectForKey:[tagArray objectAtIndex:0]] ) &&
            ( linkTag = [tagDictionary objectForKey:@"link"] ) &&
            ( linkContent = [[tagArray objectAtIndex:1] objectForKey:linkTag] ) )
        {
            [urlArray addObject:linkContent];
        }
    }
    return urlArray;
}



- (NSMutableString *)textRepresentation;
{
    NSMutableString	*textRepresentation = [NSMutableString string];
    NSEnumerator	*objectEnumerator = [[self htmlArray] objectEnumerator];
    id				tagArray;

    while( tagArray = [objectEnumerator nextObject] )
    {
        NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
    	NSDictionary		*textDictionary;

        if( [tagArray isKindOfClass:[NSString class]] )							// all NSStrings are plain text - except for
        {																		// codings ( &uuml; )
            [textRepresentation appendString:tagArray];
        }
        else if( textDictionary = [htmlDocumentConfiguration objectForKey:[tagArray objectAtIndex:0]] )	
        {
    		NSString	*optionText;
    		NSString	*tagText;
    		NSString	*replacementString;
           
			if( (optionText = [textDictionary objectForKey:@"optiontext"] )
                && ( replacementString = [[tagArray objectAtIndex:1] objectForKey:optionText] ) )
                [textRepresentation appendString:replacementString];

            if( tagText = [textDictionary objectForKey:@"tagtext"] )
            	[textRepresentation appendString:tagText];
        }
        [pool release];
    }
    return [HTMLDocument decodeHTMLTags:textRepresentation];
}



@end

