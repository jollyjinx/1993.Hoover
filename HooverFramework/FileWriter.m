#import <libc.h>

#import "FileWriter.h"
#import "HTMLScanner.h"
#import "MD5Checksum.h"

#define QUEUE_MAXIMUM	20
#define QUEUE_WAIT	1.0

@implementation FileWriter

- (id)init;
{
    [super init];
    writeToFileQueue = [[MTQueue alloc] init];
    fileNamePrefix = nil;
    urlsperfile= 0;
    [NSThread detachNewThreadSelector:@selector(_runTheWriteToFileLoop)
                             toTarget:self
                           withObject:nil];
    return self;
}

- (id)initWithFilenamePrefix:(NSString *)filenamePrefix urlsPerFile:(int)number;
{
    [super init];
    writeToFileQueue = [[MTQueue alloc] init];
    fileNamePrefix = [filenamePrefix copy];
    urlsperfile = number;
    
    [NSThread detachNewThreadSelector:@selector(_runTheWriteToFileLoop)
                             toTarget:self
                           withObject:nil];
    return self;
}


- (void)dealloc
{
    [writeToFileQueue release];
    [fileNamePrefix release];
    [super dealloc];
}

- (void) writeUrlDatatoFile:(NSDictionary *)urlDictionary;
{
    while( [writeToFileQueue count] > QUEUE_MAXIMUM )
    {
        #if DEBUG
		NSLog(@"Filewriter writeUrlDatatoFile: busy - waiting\n");
	#endif
        [NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:QUEUE_WAIT]];
    }
    [writeToFileQueue push:urlDictionary];
}


- (void) _runTheWriteToFileLoop;
{
    unsigned int currentfilenumber = 0;
    
    while(1)
    {
        NSAutoreleasePool	*outerPool = [[NSAutoreleasePool alloc] init];
        NSString 		*intermediateFileName = [NSString stringWithFormat:@"%@.%@.intermediate",fileNamePrefix,[[NSProcessInfo processInfo] hostName]];
        NSString		*finalFilenName = [NSString stringWithFormat:@"%@.%@.%06d.%05d",fileNamePrefix,[[NSProcessInfo processInfo] hostName],getpid(),currentfilenumber];
        NSFileHandle		*fileHandle;
        unsigned int 		urlswritten = 0;

        currentfilenumber++;
        if( fileNamePrefix )
        {
            int filehandle;
            
            if( -1 == (filehandle = open([intermediateFileName cString],O_CREAT|O_EXCL|O_WRONLY)) )
            {
                NSLog(@"FileWriter _runTheWriteToFileLoop: can't open file:%@ - fatal",intermediateFileName);
                exit(1);
            }
            fileHandle = [[[NSFileHandle alloc] initWithFileDescriptor:filehandle closeOnDealloc:YES] autorelease];

        }
        else
        {
            fileHandle = [NSFileHandle fileHandleWithStandardOutput];
        }

        while(!fileNamePrefix || urlswritten++<urlsperfile)
        {
            NSAutoreleasePool *innerPool = [[NSAutoreleasePool alloc] init];
            NSMutableDictionary *url;
            BOOL	gotexception = NO;

            url = [writeToFileQueue pop];

            do
            {
            NS_DURING
                [fileHandle writeData:[@"\nHoover-PageStart\nHoover-Url:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[url objectForKey:@"host"] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[@":" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[[url objectForKey:@"port"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[HTMLScanner encodeISOLatin1:[url objectForKey:@"path"]] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[@"\nHoover-SiteID:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                [fileHandle writeData:[[[url objectForKey:@"siteid"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];

                if( [[url objectForKey:@"status"] isEqual:@"invalid"] )
                {
                    [fileHandle writeData:[@"\nHoover-HTTPResponse:600\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    [fileHandle writeData:[@"\nHoover-ErrorReason:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    [fileHandle writeData:[[[url objectForKey:@"errorreason"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                }
                else
                {
                    if( [url objectForKey:@"shopid"])
                    {
                        [fileHandle writeData:[@"\nHoover-ShopID:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[[[url objectForKey:@"shopid"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    }
                    if([url objectForKey:@"pageid"])
                    {
                        [fileHandle writeData:[@"\nHoover-PageID:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[[[url objectForKey:@"pageid"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    }
                    if([url objectForKey:@"linkdepth"])
                    {
                        [fileHandle writeData:[@"\nHoover-LinkDepth:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[[[url objectForKey:@"linkdepth"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    }
                    if( [url objectForKey:@"transferdate"] && [url objectForKey:@"transfertime"] )
                    {
                        [fileHandle writeData:[@"\nHoover-TransferDate:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[[[url objectForKey:@"transferdate"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[@"\nHoover-TransferTime:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[[[url objectForKey:@"transfertime"] description] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    }
                    if( [url objectForKey:@"httpdata"] )
                    {
                        [fileHandle writeData:[@"\nHoover-ContentLength:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[[NSString stringWithFormat:@"%d",[[url objectForKey:@"httpdata"] length]] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[@"\nHoover-MD5Checksum:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[[url objectForKey:@"md5sum"] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    }
                    


                    if( [url objectForKey:@"httpheader"] && [[url objectForKey:@"httpheader"] objectForKey:@"HTTP"] )
                    {
                        [fileHandle writeData:[@"\nHoover-HTTPResponse:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[[[url objectForKey:@"httpheader"] objectForKey:@"HTTP"] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    }


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
                        [fileHandle writeData:[@"\nHoover-TextMD5Checksum:" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[[MD5Checksum md5String:[[url objectForKey:@"textRepresentation"] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[@"\nHoover-TextualRepresentation:\n" dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                        [fileHandle writeData:[[url objectForKey:@"textRepresentation"] dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES]];
                    }
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
            [innerPool release];
        }

        if( 0 != rename([intermediateFileName cString],[finalFilenName cString]) )
        {
            NSLog(@"FileWriter _runTheWriteToFileLoop: can't rename file:%@ to @ - fatal",intermediateFileName, finalFilenName);
            exit(1);
        }
        [outerPool release];
    }
    [NSThread exit];
}

@end