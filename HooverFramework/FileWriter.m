
#import "FileWriter.h"
#import "HTMLScanner.h"

@implementation FileWriter

- (id)init;
{
    [super init];
    writeToFileQueue = [[Queue alloc] init];
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

        if( [[[url objectForKey:@"httpheader"] objectForKey:@"content-type"] hasPrefix:@"text"] && [url objectForKey:@"httpdata"] )
        {
            [fileHandle writeData:[@"\nHoover-Url:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[[url objectForKey:@"sitename"] dataUsingEncoding:NSISOLatin1StringEncoding
                                                               allowLossyConversion:YES]];
            [fileHandle writeData:[[HTMLScanner encodeISOLatin1:[url objectForKey:@"path"]] dataUsingEncoding:NSISOLatin1StringEncoding
                                                           allowLossyConversion:YES]];

            [fileHandle writeData:[@"\nHoover-TransferTime:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[[[url objectForKey:@"transfertime"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
/*
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

                    if( ![@"80" isEqual:[aLink objectForKey:@"port"]] )
                    {
                        [fileHandle writeData:[@":" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[[aLink objectForKey:@"port"] dataUsingEncoding:NSISOLatin1StringEncoding
                                                                         allowLossyConversion:YES]];
                    }
                    [fileHandle writeData:[[HTMLScanner encodeISOLatin1:[aLink objectForKey:@"path"]] dataUsingEncoding:NSISOLatin1StringEncoding
                                                                     allowLossyConversion:YES]];
                    [fileHandle writeData:[@"\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                }
            }
 */
            [fileHandle writeData:[@"\nHoover-Httpdata:\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[url objectForKey:@"httpdata"]];
/*            if([url objectForKey:@"textRepresentation"])
            {	
                [fileHandle writeData:[@"\nHoover-TextualRepresentation:\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[url objectForKey:@"textRepresentation"] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            }
*/
        }
        [innerPool release];
    }
    [outerPool release];
    [NSThread exit];
}

@end