/* RobotScanner.m created by jolly on Tue 04-Mar-1997 */

#import "RobotScanner.h"

@implementation RobotScanner

static NSString *userAgentName;

+ (void)initialize;
{
    NSEnumerator	*enumerator;
    NSString		*commandlineArgument;
    NSString		*configurationFileName = @"HooverConfiguration";
    NSMutableDictionary *hooverConfigurationDictionary;

    enumerator = [[[NSProcessInfo processInfo] arguments] objectEnumerator];
    while( commandlineArgument =  [enumerator nextObject])
    {
        if( [commandlineArgument isEqual:@"-configuration"] && (commandlineArgument = [enumerator nextObject]) )
        {
            configurationFileName = commandlineArgument;
        }
    }


    hooverConfigurationDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:configurationFileName];
    if( ! ( userAgentName = [[[hooverConfigurationDictionary objectForKey:@"general"] objectForKey:@"useragentname"] retain] ) )
    {
        NSLog(@"Couldn't load RobotScannerClass - no userAgentName in Hooverconfiguration file");
        return;
    }
}

+ (RobotScanner *)robotScannerWithUrl:(NSMutableDictionary *)url;
{
    return [[[self alloc] initWithUrl:url] autorelease];
}

- (RobotScanner *)initWithUrl:(NSMutableDictionary *)url;
{
    NSMutableArray *allowedPath = [NSMutableArray array];
    NSMutableArray *disallowedPath = [NSMutableArray array];

    NSString 	*robotsFile = [[[NSString alloc] initWithData:[url objectForKey:@"httpdata"] encoding:NSISOLatin1StringEncoding] autorelease];
    NSScanner 	*lineScanner;			// scans Lines of robots file
    NSString	*lineString;			// a line in a robots file
    
    NSScanner 	*commandScanner;	       	// scans a line for commands
    NSString 	*argumentString;
    BOOL 	useragentflag = NO,commandflag =NO;

    [super init];
    
    includedPathArray = nil;
    excludedPathArray = nil;

    lineScanner = [NSScanner scannerWithString:robotsFile];
    while( ! [lineScanner isAtEnd] )
    {
        if( [lineScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"] intoString:&lineString] )
        {
            commandScanner = [NSScanner scannerWithString:lineString];
            [commandScanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];		// skip spaces
            [commandScanner setCaseSensitive:NO];
            
            if( [commandScanner scanString:@"User-agent:" intoString:NULL] )
            {
                    #if DEBUG
                    NSLog(@"RobotScanner: got UserAgent.");
                    #endif
                [commandScanner scanCharactersFromSet:[NSCharacterSet whitespaceCharacterSet] intoString:NULL];		// skip spaces
                if( [commandScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\t #"]
                                                   intoString:&argumentString] )
                {
                    #if DEBUG
                    NSLog(@"RobotScanner: got UserAgent:%@",argumentString);
                    #endif
                    if( [argumentString isEqual:@"*"] )
                        useragentflag=YES;
                    else if ([userAgentName hasPrefix:argumentString])
                        useragentflag=YES;
                    else if ( commandflag )
                    {
                        useragentflag=NO;
                        commandflag=NO;
                    }
                }
            }
            else if( useragentflag )
            {
                if( [commandScanner scanString:@"Disallow:" intoString:NULL] )
                {
                    commandflag = YES;
                    [commandScanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
                    if( [commandScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\t #*"]
                                                       intoString:&argumentString] )
                    {
                        [disallowedPath addObject:argumentString];
                    }
                }
                else if( [commandScanner scanString:@"Allow:" intoString:NULL] )
                {
                    commandflag = YES;
                    [commandScanner setCharactersToBeSkipped:[NSCharacterSet whitespaceCharacterSet]];
                    if( [commandScanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\t #*"]
                                                       intoString:&argumentString] )
                    {
                        [allowedPath addObject:argumentString];
                    }
                }
            }
        }
        [lineScanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\n\r"] intoString:NULL];
    }	
    
    if( [disallowedPath count] )
    {
        excludedPathArray = [disallowedPath retain];
    }
    if( [allowedPath count] )
    {
        includedPathArray = [allowedPath retain];
    }
    #if DEBUG
    NSLog(@"RobotScanner INIT:\nurl:%@\nallowed:\n%@\ndisallowed:\n%@",url ,allowedPath,disallowedPath);
    #endif
    return self;
}

- (void)dealloc
{
    if( includedPathArray ) [includedPathArray release];
    if( excludedPathArray ) [excludedPathArray release];
    [super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder
{
    [super init];
    
    includedPathArray = [[coder decodeObject] retain];
    excludedPathArray = [[coder decodeObject] retain];
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:includedPathArray];
    [coder encodeObject:excludedPathArray];
}

- (NSString *)description;
{
    return [NSString stringWithFormat:@"RobotScanner:\nincludedPathArray:%@\nexcludedPathArray:%@\n",[includedPathArray description],[excludedPathArray description]];
}

- (NSArray *)unwantedPaths:(NSMutableDictionary *)dictionaryOfUrls;
{
    NSEnumerator	*urlEnumerator = [dictionaryOfUrls objectEnumerator];
    NSMutableDictionary	*url;
    NSMutableArray	*unwantedArray = [NSMutableArray array];

    while( url = [urlEnumerator nextObject] )
    {
        if( ! [self urlIsWanted:url] )
        {
        #if DEBUG
            NSLog(@"Robotscanner rejects: %@",[url description]);
        #endif
            [unwantedArray addObject:[url objectForKey:@"path"]];
        }
    }
    return unwantedArray;
}

- (BOOL)urlIsWanted:(NSMutableDictionary *)urlToTest;
{
    BOOL	urlIsWanted = YES;
    
    if( [self excludedPath:[urlToTest objectForKey:@"path"]] )		// robots exclusion protocol first
    {									// disallow and later on allow
        urlIsWanted = NO;				
        if( (includedPathArray) && [self includedPath:[urlToTest objectForKey:@"path"]] )
        {
            urlIsWanted = YES;				
        }
    }
    return urlIsWanted;
}

- (BOOL)includedPath:(NSString *)path
{
    NSEnumerator *objectEnumerator;
    NSString *stringToTest;

    if( nil == includedPathArray )
        return YES;
    objectEnumerator = [includedPathArray objectEnumerator];
    while( stringToTest = [objectEnumerator nextObject] )
    {
        NSRange range = [path rangeOfString:stringToTest options:NSLiteralSearch];
        if( range.length )
        {
            return YES;
        }
    }
    return NO;
}


- (BOOL)excludedPath:(NSString *)path
{
    NSEnumerator *objectEnumerator;
    NSString *stringToTest;

    if( nil == excludedPathArray )
        return NO;
    objectEnumerator = [excludedPathArray objectEnumerator];
    while( stringToTest = [objectEnumerator nextObject] )
    {
        NSRange range = [path rangeOfString:stringToTest options:NSLiteralSearch];
        if( range.length )
        {
            return YES;
        }
    }
    return NO;
}

@end
