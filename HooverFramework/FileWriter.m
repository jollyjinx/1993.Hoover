
#import "FileWriter.h"
#import "HTMLScanner.h"
@implementation FileWriter

- (id)init;
{
    [super init];
    writeToFileQueue = [[MTQueue alloc] init];
    [NSThread detachNewThreadSelector:@selector(_runTheWriteToFileLoop)
                             toTarget:self
                           withObject:nil];
    return self;
}


- (void)dealloc
{
    [writeToFileQueue release];
    [super dealloc];
}

- (void) writeUrlDatatoFile:(NSDictionary *)urlDictionary;
{
    while( [writeToFileQueue count] > 10 )
    {
        NSLog(@"Filewriter writeUrlDatatoFile: busy - waiting\n");
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:10.0]];
    }
    [writeToFileQueue push:urlDictionary];
}


- (void) _runTheWriteToFileLoop;
{
    NSAutoreleasePool *outerPool = [[NSAutoreleasePool alloc] init];
    NSFileHandle *fileHandle = [NSFileHandle fileHandleWithStandardOutput];

    while(1)
    {
        NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
        NSMutableDictionary *url;
        
        url = [writeToFileQueue pop];

        if( [url objectForKey:@"httpheader"] )
        {
            BOOL	gotexception = NO;

            do
            {
            NS_DURING
                [fileHandle writeData:[@"\nHoover-PageStart\nHoover-Url:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[url objectForKey:@"host"] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[@":" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[[url objectForKey:@"port"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[HTMLScanner encodeISOLatin1:[url objectForKey:@"path"]] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];

                [fileHandle writeData:[@"\nHoover-ShopID:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[[url objectForKey:@"shopid"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[@"\nHoover-SiteID:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[[url objectForKey:@"siteid"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[@"\nHoover-PageID:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[[url objectForKey:@"pageid"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                
                [fileHandle writeData:[@"\nHoover-TransferDate:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[[url objectForKey:@"transferdate"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[@"\nHoover-TransferTime:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[[url objectForKey:@"transfertime"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[@"\nHoover-MD5Checksum:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[url objectForKey:@"md5sum"] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[@"\nHoover-LinkDepth:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[[url objectForKey:@"linkdepth"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];


                [fileHandle writeData:[@"\nHoover-ContentLength:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[NSString stringWithFormat:@"%d",[[url objectForKey:@"httpdata"] length]] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];

                [fileHandle writeData:[@"\nHoover-HTTPResponse:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[[url objectForKey:@"httpheader"] objectForKey:@"HTTP"] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                
                
                if( [url objectForKey:@"links"] && [[url objectForKey:@"links"] count]  )
                {
                    NSDictionary 	*aLink;
                    NSEnumerator	*enumerator;

                    enumerator = [[url objectForKey:@"links"] objectEnumerator];

                    [fileHandle writeData:[@"\nHoover-Links:\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    while(aLink = [enumerator nextObject])
                    {
                        [fileHandle writeData:[[aLink objectForKey:@"host"] dataUsingEncoding:NSISOLatin1StringEncoding
                                                                         allowLossyConversion:YES]];

                        if( 80 != [[aLink objectForKey:@"port"] intValue] )
                        {
                            [fileHandle writeData:[@":" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                            [fileHandle writeData:[[[url objectForKey:@"port"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        }
                        [fileHandle writeData:[[HTMLScanner encodeISOLatin1:[aLink objectForKey:@"path"]] dataUsingEncoding:NSISOLatin1StringEncoding
                                                                                                       allowLossyConversion:YES]];
                        [fileHandle writeData:[@"\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    }
                }

                if([url objectForKey:@"textRepresentation"])
                {	
                    [fileHandle writeData:[@"\nHoover-TextualRepresentation:\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    [fileHandle writeData:[[url objectForKey:@"textRepresentation"] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                }
                [fileHandle writeData:[@"\nHoover-PageEnd\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];

               // [fileHandle writeData:[@"\nHoover-Httpdata:\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
               // [fileHandle writeData:[url objectForKey:@"httpdata"]];
                NS_HANDLER
                    gotexception = YES;
                    NSLog(@"%@.Exception writing file:%@",[localException reason],[url description]);
                    if( ! [[localException name] isEqualToString:NSFileHandleOperationException] )
                        [localException raise];	/* Re-raise the exception. */
                    NSLog(@"Will be waiting on file to get ready");
                    [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:10.0]];
                NS_ENDHANDLER
            }
            while( gotexception );
        }
        [innerPool release];
    }
    [outerPool release];
    [NSThread exit];
}

@end