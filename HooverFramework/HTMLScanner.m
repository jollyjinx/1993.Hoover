/* HTMLScanner.m created by jolly on Mon 03-Mar-1997 */

#import <HooverFramework/HTMLScanner.h>
#import <HooverFramework/HTMLDocument.h>

#define DIGIT_CHARACTERS       	@"0123456789"
#define ALPPHA_CHARACTERS		@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
#define SCHEME_CHARACTERS		@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-."
#define HOSTNUMBER_CHARACTERS	@"0123456789."
#define HOSTNAME_CHARACTERS		@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._"

// Be aware that hostname characters contain an underscore '_' which is not included in the RFC 1808 !

#define ESCAPE_CHARACTERS		@"%"
#define SAFE_CHARACTERS			@"$-_.+"
#define EXTRA_CHARACTERS		@"!*'(),"
#define NATIONAL_CHARACTERS		@"{}|\\^~[]Á"
#define	RESERVED_CHARACTERS		@";/?:@&="
#define	PUNCTUATION_CHARACTERS	@"<>#%'\""



static NSCharacterSet 			*schemeCharacterSet;
static NSCharacterSet 			*hostnameCharacterSet;
static NSCharacterSet 			*hostnumberCharacterSet;
static NSCharacterSet 			*digitCharacterSet;
static NSMutableCharacterSet 	*pathCharacterSet;
static NSMutableCharacterSet 	*convertISOLatin1CharacterSet;
static NSDictionary				*toplevelDomainDictionary;


@implementation HTMLScanner

+ (void)initialize
{
    [super initialize];

    schemeCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:SCHEME_CHARACTERS] retain];
    hostnameCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:HOSTNAME_CHARACTERS] retain];
    hostnumberCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:HOSTNUMBER_CHARACTERS] retain];
    digitCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:HOSTNAME_CHARACTERS] retain];
    pathCharacterSet = [[NSMutableCharacterSet characterSetWithCharactersInString:ALPPHA_CHARACTERS] retain];
    [pathCharacterSet addCharactersInString:DIGIT_CHARACTERS];
    [pathCharacterSet addCharactersInString:ESCAPE_CHARACTERS];
    [pathCharacterSet addCharactersInString:SAFE_CHARACTERS];
    [pathCharacterSet addCharactersInString:EXTRA_CHARACTERS];
    [pathCharacterSet addCharactersInString:RESERVED_CHARACTERS];
    [pathCharacterSet addCharactersInString:NATIONAL_CHARACTERS];

    convertISOLatin1CharacterSet = [pathCharacterSet mutableCopy];
    [convertISOLatin1CharacterSet removeCharactersInString:@"%"];

    toplevelDomainDictionary = [[NSDictionary alloc] initWithObjectsAndKeys: @"com",@"com",
        @"edu",@"edu",
        @"gov",@"gov",
        @"mil",@"mil",
        @"int",@"int",
        @"org",@"org",
        @"net",@"net"
        ,nil];

}

+ (NSMutableDictionary *)getDictionaryFromURL:(NSString*)urlString baseUrl:(NSMutableDictionary *)baseUrl;
{
    NSString *schemeString,*siteString,*portString,*subpageString;
    NSString *pathString;
    NSScanner *urlScanner = [NSScanner scannerWithString:urlString];

    
    [urlScanner setCaseSensitive:NO];
    if( [urlScanner scanCharactersFromSet:schemeCharacterSet intoString:&schemeString] )
    {
        if( [urlScanner scanString:@":" intoString:NULL] )					// scheme or relative url ?
        {
            if( NSOrderedSame != [schemeString compare:@"http" options:NSCaseInsensitiveSearch] )
            {
                NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: Scheme of URL not supported yet: %@",urlString);
                return nil;
            }
        }
        else
        {
            [urlScanner setScanLocation:0];
        }
    }
    else
    {
        schemeString=@"http";
    }


    if( [urlScanner scanString:@"//" intoString:NULL] )
    {
        NSScanner	*sitenameScanner;
        NSEnumerator   	*domainArrayEnumerator;
        NSString	*hostnamePart;
        
        baseUrl = nil;
        
        if( ![urlScanner scanCharactersFromSet:hostnameCharacterSet intoString:&siteString] )
        {
            NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: improper formatted hostname: %@",urlString);
            return nil;
        }

        if( nil == (domainArrayEnumerator = [[[siteString lowercaseString] componentsSeparatedByString:@"."] objectEnumerator]) )
        {
            NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: improper formatted hostname: %@",urlString);
            return nil;
        }
        siteString = [domainArrayEnumerator nextObject];
        while( hostnamePart = [domainArrayEnumerator nextObject] )
        {
            if( [hostnamePart length] )
            {
                siteString = [siteString stringByAppendingFormat:@".%@",hostnamePart];
            }
        }
        
        if( [siteString length] < 5 )
        {
            NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: hostname too short. %@",urlString);
            return nil;
        }
       
        sitenameScanner = [NSScanner scannerWithString:siteString];
        if( [sitenameScanner scanCharactersFromSet:hostnumberCharacterSet intoString:NULL] && [sitenameScanner isAtEnd] )
        {
            //NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: just ipaddress. %@",urlString);
        }
        else
        {
            NSString	*domainName = [siteString pathExtension];
            
            if( (nil==domainName) || ( (nil==[toplevelDomainDictionary objectForKey:domainName]) && (2!=[domainName length])) )
            {
                NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: wrong internet domain: %@",urlString);
                return nil;
            }
        }

        
        if( [urlScanner scanString:@":" intoString:NULL] )
        {
            int	portnumber;
            
            if( ![urlScanner scanInt:&portnumber] || [urlScanner isAtEnd])
            {
                NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: improper formatted url: %@ - portnumber not detected using port 80",urlString);
                portString = @"80";
            }
            else
            {
                portString = [[NSNumber numberWithInt:portnumber] stringValue];
            }
        }
        else
        {
            portString = @"80";
        }

    }
    else
    {
        if( baseUrl )
        {
            schemeString = [baseUrl objectForKey:@"method"];
            siteString = [baseUrl objectForKey:@"host"];
            portString = [baseUrl objectForKey:@"port"];
        }
        else
        {
            NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: Relative URL without baseUrl:%@",urlString);
            return nil;
        }
    }



    if( [urlScanner isAtEnd] )
    {
        NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: improper formatted url: %@ - missing '/' inserted",urlString);
        pathString = @"/";
        subpageString = nil;
    }
    else
    {
        if( baseUrl && (![urlScanner scanString:@"/" intoString:NULL]) )
        {
            if( [urlScanner scanCharactersFromSet:pathCharacterSet intoString:&pathString] )
            {
                if( [[baseUrl objectForKey:@"path"] hasSuffix:@"/"] )
                    pathString = [[baseUrl objectForKey:@"path"] stringByAppendingPathComponent:pathString];
                else
                    pathString = [[[baseUrl objectForKey:@"path"] stringByDeletingLastPathComponent] stringByAppendingPathComponent:pathString];
                
                if( ! [pathString hasPrefix:@"/"] )
                {
                    pathString = [@"/" stringByAppendingString:pathString];
                }
                //NSLog(@"Relative URL on %@ encountered %@ expanded to %@",[baseUrl objectForKey:@"path"],urlString,pathString);
            }
            else
            {
                NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: Relative URL encountered with no path %@",urlString);
                return nil;
            }
        }
        else
        {
            if( ! [urlScanner scanCharactersFromSet:pathCharacterSet intoString:&pathString] )
            {
                //NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: Did not find a path in relative url %@",urlString);
                pathString = @"/";
            }
        }

        if( ![urlScanner isAtEnd] )
        {
            [urlScanner scanString:@"#" intoString:NULL];
            subpageString = [urlString substringFromIndex:[urlScanner scanLocation]];
        }
        else
        {
            subpageString = @"";
        }
		
		if(! (pathString = [HTMLDocument decodeHTMLTags:pathString]) )									// be Netscape and IE compatible ( http://www.wowowo.de/test?bla&amp;test )
		{
            NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: Pathstring could not be decoded from HTML ( NetscapeCompatibility ) :%@",urlString);
            return nil;
        }
		
		if( ! (pathString = [self recodeISOLatin1:pathString]) )
        {
            NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: Pathstring could not be converted to ISOLatin1:%@",urlString);
            return nil;
        }
        if( ! (pathString = [self normalizePath:pathString]) )
        {
            NSLog(@"HTMLScanner getDictionaryFromURL:baseURL: Pathstring could not be normalized:%@",urlString);
            return nil;
        }
    }

    //NSLog(@"url seems to be now:%@ : %@ : %@ %@",schemeString, siteString, portString, pathString );

    
        return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            schemeString,@"method",
            siteString,@"host",
            portString,@"port",
            pathString,@"path",
            // subpageString,@"subpage",
            nil];


    return nil;
}




+ (NSString *)normalizePath:(NSString *)pathString;
{
    NSMutableArray *pathComponents = [[[pathString componentsSeparatedByString:@"/"] mutableCopy] autorelease] ;
    int index;
    id pathComponent;
    NSString *finalPath;

    if( [@"/" isEqualToString:pathString] )
        return pathString;
    index = 0;
    while( index < [pathComponents count] )
    {
        pathComponent = [pathComponents objectAtIndex:index];
        if( [pathComponent isEqualToString:@""] )
        {
            [pathComponents removeObjectAtIndex:index];
        }
        else if( [pathComponent isEqualToString:@"/"] )
        {
            [pathComponents removeObjectAtIndex:index];
        }
        else if( [pathComponent isEqualToString:@"."] )
        {
            [pathComponents removeObjectAtIndex:index];
        }
        else if( [pathComponent isEqualToString:@".."] )
        {
            index--;
            if( index < 0 )
                return nil;
            [pathComponents removeObjectAtIndex:index];
            [pathComponents removeObjectAtIndex:index];
        }
        else
        {
            index++;
        }
    }
/*
    if( [[pathComponents lastObject] isEqualToString:@"index.html"] )
       [pathComponents removeLastObject];
    if( [[pathComponents lastObject] isEqualToString:@"index.htm"] )
       [pathComponents removeLastObject];
*/
    finalPath = [@"/" stringByAppendingString:[pathComponents componentsJoinedByString:@"/"]];
    if( [pathString hasSuffix:@"/"] )
        finalPath= [finalPath stringByAppendingString:@"/"];
    return finalPath;
}




+ (NSString *)recodeISOLatin1:(NSString *)pathString;
{
    NSScanner			*pathScanner;
    NSMutableString 	*convertedString = [NSMutableString string];
    NSMutableString		*appendString;
    
    if( nil == pathString ) return nil;
    
    pathScanner = [NSScanner scannerWithString:pathString];


    while( ![pathScanner isAtEnd] )
    {
        if( [pathScanner scanCharactersFromSet:convertISOLatin1CharacterSet intoString:&appendString] )
        {
            [convertedString appendString:appendString];
        }

        if( [pathScanner isAtEnd] )
        {
            return convertedString;
        }
        
        if( [pathScanner scanString:@"%" intoString:NULL] )
        {
            int		i;
            unichar 	aunichar;
            NSRange 	hexrange = {[pathScanner scanLocation],2};
            NSString 	*hexString;
            NSScanner 	*hexScanner;

            if( 2 > [pathString length]-hexrange.location )
            {
                NSLog(@"HTMLScanner recodeISOLatin1: %% encoding without hex in: %@ - ",pathString);
                return nil;
            }
            [pathScanner setScanLocation:[pathScanner scanLocation]+2];

            hexString = [pathString substringWithRange:hexrange];
            hexScanner = [NSScanner scannerWithString:hexString];
            if( ! [hexScanner scanHexInt:&i] )
            {
                NSLog(@"HTMLScanner recodeISOLatin1: %% hex encoding wrong in: %@",pathString);
                return nil;
            }
            aunichar=i;
            
            if( [convertISOLatin1CharacterSet characterIsMember:aunichar] )
            {
                [convertedString appendString:[NSString stringWithCharacters:&aunichar length:1]];
            }
            else
            {
                [convertedString appendFormat:@"%%%@",hexString];
            }

        }
        else
        {
            unichar	aunichar;

            aunichar = [pathString characterAtIndex:[pathScanner scanLocation]];
            [pathScanner setScanLocation:[pathScanner scanLocation]+1];

            if(aunichar < 255 )
            {
                [convertedString appendFormat:@"%%%x%x",aunichar/16,aunichar%16];
            }
            else
            {
                NSLog(@"HTMLScanner recodeISOLatin1: character above 255 in path: %@",pathString);
                return nil;
            }
        }
    }
    return convertedString;
}


+ (NSString *) decodeISOLatin1:(NSString *)html;
{
    NSScanner	*htmlScanner;
    NSMutableString *htmlString;

    if( nil == html ) return nil;
    
    htmlString = [html mutableCopy];
    htmlScanner = [NSScanner scannerWithString:htmlString];
    [htmlScanner setCharactersToBeSkipped:[[NSCharacterSet characterSetWithCharactersInString:@"%"] invertedSet]];

    while( [htmlScanner scanString:@"%" intoString:NULL] )
    {
        int i;
        unsigned char c;
        NSRange hexrange = {[htmlScanner scanLocation],2};
        NSString *hexString;
        NSScanner *hexScanner;

        if( 2 > [htmlString length]-hexrange.location )
        {
            NSLog(@"improper formatted html in: %@ - %% encoding without hex.",htmlString);
            return nil;
        }
        hexString = [htmlString substringWithRange:hexrange];
        hexScanner = [NSScanner scannerWithString:hexString];
        if( ! [hexScanner scanHexInt:&i] )
        {
            NSLog(@"improper formatted html in: %@ - %% hex encoding wrong.",htmlString);
            return nil;
        }
        c=i;
        if(c<0x20)
        {
            NSLog(@"improper formatted html in: %@ - %% hex encoding encodes control character.",htmlString);
            //return nil;
        }

        hexrange.location--;
        hexrange.length++;
        [htmlString replaceCharactersInRange:hexrange withString:[NSString stringWithData:[NSData dataWithBytes:&c length:1]
																				 encoding:[NSString defaultCStringEncoding]]];
//																				 encoding:NSISOLatin1StringEncoding]];
        htmlScanner = [NSScanner scannerWithString:htmlString];
        [htmlScanner setCharactersToBeSkipped:[[NSCharacterSet characterSetWithCharactersInString:@"%"] invertedSet]];
    }
    return htmlString;
}



+ (NSString *) encodeISOLatin1:(NSString *)latin1String;
{
    NSScanner 		*latin1Scanner = [NSScanner scannerWithString:latin1String];
    NSMutableString 	*asciiString = [NSMutableString string];
    NSString 		*appendString;

    if( nil == latin1String ) return nil;

    while( NO == [latin1Scanner isAtEnd] )
    {
        if( [latin1Scanner scanCharactersFromSet:pathCharacterSet intoString:&appendString] )
        {
            [asciiString appendString:appendString];
        }

        if( NO == [latin1Scanner isAtEnd] )
        {
            unichar	aunichar;

            aunichar = [latin1String characterAtIndex:[latin1Scanner scanLocation]];
            [latin1Scanner setScanLocation:[latin1Scanner scanLocation]+1];
            if(aunichar < 255 )
                [asciiString appendFormat:@"%%%x%x",aunichar/16,aunichar%16];
        }
    }
    return asciiString;
}


@end
