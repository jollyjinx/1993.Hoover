
#import "GeneralScanner.h"

@implementation GeneralScanner



- (id)initWithConfiguration:(NSDictionary *)generalDictionary;
{
    if( [[generalDictionary objectForKey:@"includehosts"] count] )
        includedSiteArray = [[generalDictionary objectForKey:@"includehosts"] retain];
    if( [[generalDictionary objectForKey:@"excludehosts"] count] )
        excludedSiteArray = [[generalDictionary objectForKey:@"excludehosts"] retain];
    if( [[generalDictionary objectForKey:@"includepaths"] count])
        includedPathArray = [[generalDictionary objectForKey:@"includepaths"] retain];
    if( [[generalDictionary objectForKey:@"excludepaths"] count] )
        excludedPathArray = [[generalDictionary objectForKey:@"excludepaths"] retain];
    if( [[generalDictionary objectForKey:@"excludeextensions"] count] )
    {
        NSEnumerator 	*objectEnumerator = [[generalDictionary objectForKey:@"excludeextensions"] objectEnumerator];
        NSString	*extensionString;

        excludedExtensionsDictionary = [[NSMutableDictionary alloc] init];
        while(extensionString = [objectEnumerator nextObject])
            [excludedExtensionsDictionary setObject:@"excluded" forKey:extensionString];
    }
        
    return self;
}

- (void)dealloc
{
    if( includedSiteArray ) [includedSiteArray release];
    if( excludedSiteArray ) [excludedSiteArray release];
    if( includedPathArray ) [includedPathArray release];
    if( excludedPathArray ) [excludedPathArray release];
    if( excludedExtensionsDictionary ) [excludedExtensionsDictionary release];
    [super dealloc];

}


- (BOOL)urlIsWanted:(NSMutableDictionary *)urlToTest;
{
    if( [self excludedExtension:[urlToTest objectForKey:@"path"]] )
        return NO;
    
    if( [self excludedSite:[urlToTest objectForKey:@"host"]] )		// this is for the general scanner
        return NO;				

    if( ![self includedSite:[urlToTest objectForKey:@"host"]] )
        return NO;
    
    if( [self excludedPath:[urlToTest objectForKey:@"path"]] )
        return NO;
    
    if( ![self includedPath:[urlToTest objectForKey:@"path"]] )
        return NO;
    return YES;
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



- (BOOL)excludedExtension:(NSString *)path
{
    NSString		*lowercaseExtension;
    
    if( nil == excludedExtensionsDictionary )
        return NO;
    if( nil == ( lowercaseExtension = [[path lowercaseString] pathExtension] ) )
        return NO;
    if( [excludedExtensionsDictionary objectForKey:lowercaseExtension] )
            return YES;
    return NO;
}


@end