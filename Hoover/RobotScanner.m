/* RobotScanner.m created by jolly on Tue 04-Mar-1997 */

#import "RobotScanner.h"

@implementation RobotScanner
{
    NSArray	*includedSiteArray;
    NSArray	*excludedSiteArray;
    NSArray	*includedPathArray;
    NSArray	*excludedPathArray;
}

- (RobotScanner *)initWithUrl:(NSMutableDictionary *)url userAgentName:(NSString *)uaName;
{
    NSMutableArray *allowedPath = [NSMutableArray array];
    NSMutableArray *disallowedPath = [NSMutableArray array];

    NSString *robotsFile = [url objectForKey:@"contents"];
    
    NSString *stringToTest;
    NSString *argumentString;
    NSArray *lineArray;
    NSEnumerator *lineEnumerator;
    NSScanner *lineScanner;
    BOOL useragentflag = NO;

    [super init];
    includedSiteArray = nil;
    excludedSiteArray = nil;
    includedPathArray = nil;
    excludedPathArray = nil;

    lineArray = [[[robotsFile componentsSeparatedByString:@"\r"] componentsJoinedByString:@"\n"] componentsSeparatedByString:@"\n"];
    lineEnumerator = [lineArray objectEnumerator];

    while( stringToTest = [lineEnumerator nextObject] )
    {
        lineScanner = [NSScanner scannerWithString:stringToTest];
        [lineScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\t ;-_"]];

        if( [lineScanner scanString:@"User-agent:" intoString:NULL] )
        {
            [lineScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\t "]];
            if( [lineScanner scanUpToString:@"#" intoString:&argumentString] )
            {
                if( [argumentString isEqual:@"*"] )
                    useragentflag=YES;
                else if ([argumentString hasPrefix:uaName])
                    useragentflag=YES;
                else
                    useragentflag=NO;
            }
        }
        else
        if( useragentflag )
        {
            if( [lineScanner scanString:@"Disallow:" intoString:NULL] )
            {
                [lineScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\t "]];
                if( [lineScanner scanUpToString:@"#" intoString:&argumentString] )
                {
                    [disallowedPath addObject:argumentString];
                }
            }
            else
            if( [lineScanner scanString:@"Allow:" intoString:NULL] )
            {
                [lineScanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@"\t "]];
                if( [lineScanner scanUpToString:@"#" intoString:&argumentString] )
                {
                    [allowedPath addObject:argumentString];
                }
            }
        }
    }
    if( [disallowedPath count] )
    {
        excludedPathArray = [disallowedPath retain];
    }
    if( [allowedPath count] )
    {
        includedPathArray = [allowedPath retain];
    }
    return self;
}

- (void)dealloc
{
    if( includedSiteArray ) [includedSiteArray release];
    if( excludedSiteArray ) [excludedSiteArray release];
    if( includedPathArray ) [includedPathArray release];
    if( excludedPathArray ) [excludedPathArray release];
    [super dealloc];
}

- (RobotScanner *)initWithContentsOfGeneralConfiguration:(NSDictionary *)generalDictionary;
{
    if( [[generalDictionary objectForKey:@"includehosts"] count] )
        includedSiteArray = [[generalDictionary objectForKey:@"includehosts"] retain];
    if( [[generalDictionary objectForKey:@"excludehosts"] count] )
        excludedSiteArray = [[generalDictionary objectForKey:@"excludehosts"] retain];
    if( [[generalDictionary objectForKey:@"includepaths"] count])
        includedPathArray = [[generalDictionary objectForKey:@"includepaths"] retain];
    if( [[generalDictionary objectForKey:@"excludepaths"] count] )
        excludedPathArray = [[generalDictionary objectForKey:@"excludepaths"] retain];
    return self;
}

- (BOOL)urlIsWanted:(NSMutableDictionary *)urlToTest;
{
    BOOL	urlIsWanted = YES;

    if( [self excludedSite:[urlToTest objectForKey:@"host"]] )		// robots exclusion protocol first
    {									// disallow and later on allow
        urlIsWanted = NO;				
    }
    if( [self excludedPath:[urlToTest objectForKey:@"path"]] )
    {
        urlIsWanted = NO;				
    }
    
    if( ![self includedSite:[urlToTest objectForKey:@"host"]] )
    {
        urlIsWanted = NO;				
    }
    if( ![self includedPath:[urlToTest objectForKey:@"path"]] )
    {
        urlIsWanted = NO;				
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
    while( stringToTest = [objectEnumerator nextObject])
    {
        NSRange range = [path rangeOfString:stringToTest options:NSLiteralSearch];
        if( range.length )
            return YES;
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
    while( stringToTest = [objectEnumerator nextObject])
    {
        NSRange range = [path rangeOfString:stringToTest options:NSLiteralSearch];
        if( range.length )
            return YES;
    }
    return NO;
}
- (BOOL)includedSite:(NSString *)site
{
    NSEnumerator *objectEnumerator;
    NSString *stringToTest;

    if( nil == includedSiteArray )
        return YES;
    objectEnumerator = [includedSiteArray objectEnumerator];
    while( stringToTest = [objectEnumerator nextObject])
    {
        if( [site hasSuffix:stringToTest] )
            return YES;
    }
    return NO;
}
- (BOOL)excludedSite:(NSString *)site
{
    NSEnumerator *objectEnumerator;
    NSString *stringToTest;
    
    if( nil == excludedSiteArray )
        return NO;
    objectEnumerator = [excludedSiteArray objectEnumerator];
    while( stringToTest = [objectEnumerator nextObject])
    {
        if( [site hasSuffix:stringToTest] )
            return YES;
    }
    return NO;
}

@end
