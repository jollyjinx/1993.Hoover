
#import <Foundation/Foundation.h>

#import "SortedArray.h"
#import "HooverController.h"
#import "HTMLScanner.h"

int main (int argc, const char *argv[])
{
   NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
   NSDictionary *configurationDictionary;
   NSString *configurationFileName=@"HooverConfiguration";
   HooverController *hoover;
   
   if( 2 == argc )
   {
       configurationFileName = [NSString stringWithCString:argv[1]];
   }



   if( nil == ( configurationDictionary = [NSDictionary dictionaryWithContentsOfFile:configurationFileName] ))
   {
       NSLog(@"Can't read configuration file: %@",configurationFileName);
       NSLog(@"Usage: %s [Hoverconfiguration]\n\tIf no configuration is omitted 'HooverConfiguration' is used.\n",argv[0]);
   }
   else
   {
       [NSRunLoop currentRunLoop];
       hoover = [[HooverController alloc]  initWithConfiguration:configurationDictionary];
       [hoover runTheLoop];
       [hoover release];
   }

   [pool release];
   exit(0);       // insure the process exit status is 0
   return 0;      // ...and make main fit the ANSI spec.
}
