/* HTMLScanner.m created by jolly on Mon 03-Mar-1997 */

#import "HTMLScanner.h"

#define DIGIT_CHARACTERS       	@"0123456789"
#define ALPPHA_CHARACTERS	@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
#define SCHEME_CHARACTERS	@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+-."
#define HOSTNUMBER_CHARACTERS	@"0123456789."
#define HOSTNAME_CHARACTERS	@"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-."


@implementation HTMLScanner


+ (NSMutableDictionary *)getDictionaryFromURL:(NSString*)urlString baseUrl:(NSMutableDictionary *)baseUrl;
{
    NSString *schemeString,*siteString,*portString,*sitenameString,*subpageString;
    NSString *pathString;
    NSScanner *urlScanner = [NSScanner scannerWithString:urlString];

    NSCharacterSet 	*schemeCharacterSet = [NSCharacterSet characterSetWithCharactersInString:SCHEME_CHARACTERS];


    
    [urlScanner setCaseSensitive:NO];
    if( [urlScanner scanCharactersFromSet:schemeCharacterSet intoString:&schemeString] )
    {
        if( [urlScanner scanString:@":" intoString:NULL] )					// scheme or relative url ?
        {
            if( NSOrderedSame != [schemeString compare:@"http" options:NSCaseInsensitiveSearch] )
            {
                NSLog(@"Scheme of URL not supported yet: %@",urlString);
                return nil;
            }
        }
        else
        {
            [urlScanner setScanLocation:0];
        }
    }


    if( [urlScanner scanString:@"//" intoString:NULL] )
    {
        NSScanner	*sitenameScanner;

        baseUrl = nil;
        [urlScanner scanUpToString:@"/" intoString:&sitenameString];
        sitenameString = [sitenameString lowercaseString];
        sitenameScanner = [NSScanner scannerWithString:sitenameString];

        if( ! [sitenameScanner scanUpToString:@":" intoString:&siteString] )
        {
            NSLog(@"improper formatted url: %@ - sitename not found",urlString);
            return nil;
        }
        
        if( [sitenameScanner isAtEnd] )
        {
            siteString = sitenameString;
            portString = @"80";
        }
        else
        {
            int portnumber;
            
            [sitenameScanner scanString:@":" intoString:NULL];
            if(![sitenameScanner scanInt:&portnumber] || ![sitenameScanner isAtEnd])
            {
                NSLog(@"improper formatted url: %@ - portnumber not detected using port 80",urlString);
                portString = @"80";
            }
            else
            {
                portString = [[NSNumber numberWithInt:portnumber] stringValue];
            }
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
            NSLog(@"Relative URL without baseUrl:%@",urlString);
            return nil;
        }
    }



    if( [urlScanner isAtEnd] )
    {
        NSLog(@"improper formatted url: %@ - missing '/' inserted",urlString);
        pathString = @"/";
        subpageString = nil;
    }
    else
    {
        if( baseUrl && (![urlScanner scanString:@"/" intoString:NULL]) )
        {
            if( [urlScanner scanUpToString:@"#" intoString:&pathString] )
            {
                pathString = [[[baseUrl objectForKey:@"path"] stringByDeletingLastPathComponent] stringByAppendingPathComponent:pathString];
                if( ! [pathString hasPrefix:@"/"] )
                {
                    pathString = [@"/" stringByAppendingString:pathString];
                }
                //NSLog(@"Relative URL on %@ encountered %@ expanded to %@",[baseUrl objectForKey:@"path"],urlString,pathString);
            }
            else
            {
                NSLog(@"Relative URL encountered with no path %@",urlString);
                return nil;
            }
        }
        else
        {
            if( ! [urlScanner scanUpToString:@"#" intoString:&pathString] )
            {
                //NSLog(@"Did not find a path in relative url %@",urlString);
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

        if( ! (pathString = [self decodeISOLatin1:pathString]) )
        {
            NSLog(@"Pathstring could not be converted:%@",pathString);
            return nil;
        }
        if( ! (pathString = [self normalizePath:pathString]) )
        {
            NSLog(@"Pathstring could not be normalized:%@",pathString);
            return nil;
        }
    }

    NSLog(@"url seems to be now:%@ : %@ : %@ %@",schemeString, siteString, portString, pathString );

    
        return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            schemeString,@"method",
            siteString,@"host",
            portString,@"port",
            pathString,@"path",
            subpageString,@"subpage",nil];


    return nil;
}




+ (NSString *)normalizePath:(NSString *)pathString;
{
    NSMutableArray *pathComponents = [[[pathString componentsSeparatedByString:@"/"] mutableCopy] autorelease] ;
    int index;
    id pathComponent;

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
    if( [[pathComponents lastObject] isEqualToString:@"index.html"] )
       [pathComponents removeLastObject];
    if( [[pathComponents lastObject] isEqualToString:@"index.htm"] )
       [pathComponents removeLastObject];

    return [@"/" stringByAppendingString:[pathComponents componentsJoinedByString:@"/"]];
}

+ (NSString *) decodeISOLatin1:(NSString *)html;
{
    NSScanner	*htmlScanner;
    NSMutableString *htmlString;

    if( nil == html ) return nil;
    
    htmlString = [NSMutableString stringWithString:html];
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
            return nil;
        }

        hexrange.location--;
        hexrange.length++;
        [htmlString replaceCharactersInRange:hexrange
                                  withString:[NSString stringWithData:[NSData dataWithBytes:&c length:1]
                                                             encoding:NSISOLatin1StringEncoding]];
        htmlScanner = [NSScanner scannerWithString:htmlString];
        [htmlScanner setCharactersToBeSkipped:[[NSCharacterSet characterSetWithCharactersInString:@"%"] invertedSet]];
    }
    return htmlString;
}

+ (NSString *) encodeISOLatin1:(NSString *)latin1String;
{
    NSMutableString *asciiString = [NSMutableString string];
    NSString *appendString;
    NSData *latin1charData;
    unsigned char latin1char;
    NSCharacterSet *asciiCharacterSet = [NSCharacterSet characterSetWithCharactersInString:
        @"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789/\\~.;&+-_#@!"];
    NSScanner *latin1Scanner = [NSScanner scannerWithString:latin1String];

    if( nil == latin1String ) return nil;
    
    while( [latin1Scanner scanCharactersFromSet:asciiCharacterSet intoString:&appendString] )
    {
        NSRange range = {[latin1Scanner scanLocation],1};
        
        [asciiString appendString:appendString];

        latin1charData = [[latin1String substringWithRange:range] dataUsingEncoding:NSISOLatin1StringEncoding];
        latin1char = *((unsigned char *)[latin1charData bytes]);
        [asciiString appendFormat:@"%x",latin1char];
    }
    return asciiString;
}


@end
