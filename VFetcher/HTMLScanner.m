/* HTMLScanner.m created by jolly on Mon 03-Mar-1997 */

#import "HTMLScanner.h"

@implementation HTMLScanner


+ (NSMutableDictionary *)getDictionaryFromURL:(NSString*)urlString;
{
    NSString *methodString,*siteString,*portString,*sitenameString,*subpageString;
    NSString *pathString;
    NSScanner *urlScanner = [NSScanner scannerWithString:urlString];
    
    [urlScanner setCaseSensitive:NO];
    if( [urlScanner scanString:@"http:" intoString:NULL] )
    {
        NSScanner *sitenameScanner;
        
        methodString = @"http";									

        if( ! [urlScanner scanString:@"//" intoString:NULL] )
        {
            NSLog(@"improper formatted url: %@",urlString);
            return nil;
        }
        if( ! [urlScanner scanUpToString:@"/" intoString:&sitenameString] )			// remove http://user:passwd@
        {
            NSLog(@"improper formatted url: %@ - no site found",urlString);
            return nil;
        }

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

        if( [urlScanner isAtEnd] )
        {
            NSLog(@"improper formatted url: %@ - missing '/' inserted",urlString);
            pathString = @"/";
            subpageString = nil;
        }
        else
        {
            [urlScanner scanUpToString:@"#" intoString:&pathString];
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
                return nil;
            }
            if( ! (pathString = [self normalizePath:pathString]) )
            {
                return nil;
            }
        }

        return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            methodString,@"method",
            siteString,@"host",
            portString,@"port",
            pathString,@"path",
            subpageString,@"subpage",nil];
    }
    else
    {
        //NSLog(@"url protocol not supported");
        return nil;
    }
    return nil;
}


+ (NSMutableArray *)getURLArrayFromHTML:(NSString *)htmlString;
{
    NSScanner		*htmlScanner = [NSScanner scannerWithString:htmlString];
    NSString		*momString;
    NSString		*htmlTag;
    NSScanner		*tagScanner;
    NSMutableDictionary	*momUrl;
    NSMutableArray	*urlArray = [NSMutableArray array];

    [htmlScanner setCaseSensitive:NO];

    while( ! [htmlScanner isAtEnd] )
    {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        [htmlScanner scanUpToString:@"<a" intoString:NULL];
        if( [htmlScanner scanUpToString:@">" intoString:&htmlTag] )
        {
            tagScanner= [NSScanner scannerWithString:htmlTag];
            [tagScanner scanUpToString:@"href=\"" intoString:NULL];
            if( [tagScanner scanString:@"href=\"" intoString:NULL] && [tagScanner scanUpToString:@"\"" intoString:&momString] )
            {
                //NSLog(@"Got Url:%@",momString);
                if( momUrl = [self getDictionaryFromURL:momString] )
                {
                    [urlArray addObject:momUrl];
                }
            }
        }
        [pool release];
    }
    return urlArray;
}

+ (NSString *)normalizePath:(NSString *)pathString;
{
    NSMutableArray *pathComponents = [[pathString componentsSeparatedByString:@"/"] mutableCopy] ;
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
                                  withString:[[[NSString alloc] initWithData:[NSData dataWithBytes:&c length:1]
                                                                    encoding:NSISOLatin1StringEncoding] autorelease]];
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
