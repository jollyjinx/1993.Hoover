/* HTMLDocument.m created by jolly on Tue 18-Nov-1997 */

#import "HTMLDocument.h"

static NSDictionary *htmlDocumentConfiguration = nil;

@implementation HTMLDocument

+ (void) initialize;
{
    htmlDocumentConfiguration = [[NSDictionary dictionaryWithContentsOfFile:@"HTMLDocument.configuration"] retain];
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
    NSDictionary	*tagDictionary = [htmlDocumentConfiguration objectForKey:@"tagDictionary"];
    NSScanner 		*htmlScanner = [NSScanner scannerWithString:stringToDecode];
    NSCharacterSet	*tagCommandCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"];
    NSMutableString	*convertedString = [NSMutableString string];
    
    if(nil == tagDictionary)
    {
        NSLog(@"HTMLDocument decodeHTMLTags: Can't read TagDictionary, skipping conversion of &namedtags; .");
        return [NSMutableString stringWithString:stringToDecode];
    }

    while( NO == [htmlScanner isAtEnd] )
    {
        NSString	*notTaggedString;
        
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
            }
            else
            {
                NSString *tagValue;
                NSString *tagConversion;

                if( ! [htmlScanner scanCharactersFromSet:tagCommandCharacterSet intoString:&tagValue] )
                {
                    NSLog(@"HTMLDocument decodeHTMLTags:couldn't scan any valid TagCharacters  in String.");
                }
                else
                {
                    if( ! (tagConversion = [tagDictionary objectForKey:tagValue] ) )
                    {
                        NSLog(@"HTMLDocument decodeHTMLTags: Tag %@ not known ( thrown away ).",tagValue);
                    }
                    else
                    {
                        [convertedString appendString:tagConversion];
                    }
                }
            }

            if( ! [htmlScanner scanString:@";" intoString:NULL] )
            {
                NSLog(@"HTMLDocument decodeHTMLTags: TagCharacters not delimited, inserting missing ';'.",stringToDecode);
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
    NSCharacterSet	*htmlCommandStopSet = [NSCharacterSet characterSetWithCharactersInString:@"<>"];
    NSCharacterSet 	*optionCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@" ="];

    if( [htmlArray count] )
        return htmlArray;
    
    [htmlScanner setCharactersToBeSkipped:nil];
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
                                                NSLog(@"option without ending \"");
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
                                NSLog(@"Got option without characters in string:%@",tagValue);
                                [tagScanner scanCharactersFromSet:optionCharacterSet intoString:NULL];
                            }
                        }
                    }
                }											// now the tag is scanned let's scan
                [htmlScanner scanString:@">" intoString:NULL];						// the rest
            }
        }
        [pool release];
   }
    return htmlArray;
}


- (NSMutableArray *)urlArray
{
    NSMutableArray	*urlArray = [NSMutableArray array];
    NSEnumerator	*objectEnumerator = [[self htmlArray] objectEnumerator];
    NSMutableArray	*tagArray;
    NSString		*linkTag;
    NSDictionary	*tagDictionary;
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
    id			tagArray;
    NSString		*replacementString;
    NSDictionary	*textDictionary;
    NSString		*optionText;
    NSString		*tagText;

    
    while( tagArray = [objectEnumerator nextObject] )
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        if( [tagArray isKindOfClass:[NSString class]] )							// all NSStrings are plain text - except for
        {												// codings ( &uuml; )
            [textRepresentation appendString:tagArray];
        }
        else if( textDictionary = [htmlDocumentConfiguration objectForKey:[tagArray objectAtIndex:0]] )	
        {
            if( (optionText = [textDictionary objectForKey:@"optiontext"] )
                && ( replacementString = [[tagArray objectAtIndex:1] objectForKey:optionText] ) )
                [textRepresentation appendString:replacementString];

            if( ( tagText = [textDictionary objectForKey:@"tagtext"] )
                && ( replacementString = [[tagArray objectAtIndex:1] objectForKey:tagText] ) )
                [textRepresentation appendString:replacementString];
        }
        [pool release];
    }
    return [HTMLDocument decodeHTMLTags:textRepresentation];
}



@end

