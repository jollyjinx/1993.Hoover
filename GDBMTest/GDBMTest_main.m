
#import <Foundation/Foundation.h>
#import <HooverFramework/HooverFramework.h>
#import "RobotScanner.h"
#import <gdbm.h>

int main (int argc, const char *argv[])
{
    int			blocksize;
    datum		key,nextkey;
    GDBM_FILE 		oldgdbmfile,newgdbmfile;

    if( argc != 4 )
    {
        printf("usage: %s pagesize olddatabase newdatabase\n",argv[0]);
        exit(1);
    }

    blocksize = atoi(argv[1]);
    printf("Using blocksize: %d\n",blocksize);
	
    if( ! (oldgdbmfile = gdbm_open(argv[2], 1024, GDBM_FAST|GDBM_READER, 0644, 0 )) )
    {
        printf("Can't open gdbm %s\n",argv[2]);
        exit(1);
    }

    if( ! (newgdbmfile = gdbm_open(argv[3],blocksize, GDBM_FAST|GDBM_WRCREAT|GDBM_READER|GDBM_WRITER, 0644, 0 )) )
    {
        printf("Can't open gdbm %s\n",argv[3]);
        exit(1);
    }


    key = gdbm_firstkey(oldgdbmfile);
    while( key.dptr )
    {
        datum object;

        object = gdbm_fetch(oldgdbmfile, key);

        //newobject.dptr = realloc(object.dptr,((object.dsize/blocksize)+1)*blocksize);
        //newobject.dsize= ((object.dsize/blocksize)+1)*blocksize;
        if( object.dptr )
        {
            NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
            RobotScanner	*robotScanner;
            NSMutableDictionary	*siteDictionary;
            NSData		*dataObject = nil;
            siteDictionary = [NSUnarchiver unarchiveObjectWithData:[NSData dataWithBytes:object.dptr length:object.dsize]];

            NSLog(@"Loading site:%@",[siteDictionary objectForKey:@"sitename"]);
            if( robotScanner = [siteDictionary objectForKey:@"robotScanner"] )
            {
                NSArray	*unwantedArray;

                unwantedArray = [robotScanner unwantedPaths:[siteDictionary objectForKey:@"knownpaths"]];
                if( [unwantedArray count] )
                {
                    NSLog(@"Site has been fetched things from robots.txt");
                }
                
                unwantedArray = [robotScanner unwantedPaths:[siteDictionary objectForKey:@"unknownpaths"]];
                if( [unwantedArray count] )
                {
                    NSLog(@"RobotScanner rejects: %@ \n",[unwantedArray description]);
                    [[siteDictionary objectForKey:@"unknownpaths"] removeObjectsForKeys:unwantedArray];
                    //NSLog(@"New Sitecontents: %@\n",[siteDictionary description]);
                    
                    free(object.dptr);
                    dataObject = [NSArchiver archivedDataWithRootObject:siteDictionary];
                    object.dptr = (void *)[dataObject bytes];
                    object.dsize = [dataObject length];
                }
            }
            
            gdbm_store( newgdbmfile,key,object, GDBM_REPLACE );
            if( ! dataObject )
            {
                free(object.dptr);
            }
            [pool release];
        }
        nextkey = gdbm_nextkey(oldgdbmfile, key);
        free(key.dptr);
        key = nextkey;
    }
    gdbm_sync(newgdbmfile);
    gdbm_close(newgdbmfile);
    gdbm_close(oldgdbmfile);
}
