
#import "FileWriter.h"
#import "HTMLScanner.h"
#import "MD5Checksum.h"
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
        NSLog(@"Filewriter busy - waiting\n");
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

        if( [[[url objectForKey:@"httpheader"] objectForKey:@"content-type"] hasPrefix:@"text"] && [url objectForKey:@"httpdata"] )
        {
            [fileHandle writeData:[@"\nHoover-Url:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[[url objectForKey:@"sitename"] dataUsingEncoding:NSISOLatin1StringEncoding
                                                               allowLossyConversion:YES]];
            [fileHandle writeData:[[HTMLScanner encodeISOLatin1:[url objectForKey:@"path"]] dataUsingEncoding:NSISOLatin1StringEncoding
                                                           allowLossyConversion:YES]];

            [fileHandle writeData:[@"\nHoover-TransferDate:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[[[url objectForKey:@"transferdate"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[@"\nHoover-TransferTime:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[[[url objectForKey:@"transfertime"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[@"\nHoover-MD5Checksum:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[[MD5Checksum md5String:[url objectForKey:@"httpdata"]] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[@"\nHoover-ContentLength:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[[NSString stringWithFormat:@"%d",[[url objectForKey:@"httpdata"] length]] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
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
            if([url objectForKey:@"textRepresentation"])
            {	
                [fileHandle writeData:[@"\nHoover-TextualRepresentation:\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[url objectForKey:@"textRepresentation"] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            }
            
            [fileHandle writeData:[@"\nHoover-Httpdata:\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
            [fileHandle writeData:[url objectForKey:@"httpdata"]];


        }
        [innerPool release];
    }
    [outerPool release];
    [NSThread exit];
}

@end