
#import "GeneralScanner.h"

@implementation GeneralScanner



- (id)initWithConfiguration:(NSDictionary *)generalDictionary;
{
    [super init];
    if( nil == generalDictionary )
    {
        NSLog(@"GeneralScanner has no valid dictionary !");
        return self;
    }
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


    switch( (nil==includedSiteArray?0x00:0x10)|(nil==excludedSiteArray?0x00:0x01) )
    {
        case 0x00:	break;
        case 0x10:	if( ![self includedSite:[urlToTest objectForKey:@"host"]] )
            return NO;break;
        case 0x01:	if( [self excludedSite:[urlToTest objectForKey:@"host"]] )
            return NO;break;
        case 0x11:	if( [self excludedSite:[urlToTest objectForKey:@"host"]] && ![self includedSite:[urlToTest objectForKey:@"host"]] )
            return NO;break;
        default:	NSLog(@"GeneralScanner: includedHost|excludedHost created unknown state.");
    }

    switch( (nil==includedPathArray?0x00:0x10)|(nil==excludedPathArray?0x00:0x01) )
    {
        case 0x00:	break;
        case 0x10:	if( ![self includedPath:[urlToTest objectForKey:@"path"]] )
            return NO;break;
        case 0x01:	if( [self excludedPath:[urlToTest objectForKey:@"path"]] )
            return NO;break;
        case 0x11:	if( [self excludedPath:[urlToTest objectForKey:@"path"]] && ![self includedPath:[urlToTest objectForKey:@"path"]] )
            return NO;break;
        default:	NSLog(@"GeneralScanner: includedPath|excludedPath created unknown state.");
    }
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