#import <Foundation/Foundation.h>

#import "SortedArray.h"

int main (int argc, const char *argv[])
{
	int testnumber=0;
	
	while(1)
	{
		NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
		NSMutableArray	*mutableArray = [NSMutableArray array];
		NSMutableArray	*testArray;
		SortedArray	*sortedArray = [SortedArray array];
		
		int	count = random()%200+1;
		int	i,j;
		NSNumber *randomNumber;
		int 	randomnumber;

		for(i=0;i<count;i++)
		{
			randomNumber =  [NSNumber numberWithInt:random()%20];
			[mutableArray addObject:randomNumber];
			[sortedArray addObject:randomNumber];
			assert([sortedArray count] == [mutableArray count]);
		}
		[mutableArray sortUsingSelector:@selector(compare:)];

		for(i=0;i<count;i++)
		{
			assert([[mutableArray objectAtIndex:i] isEqual:[sortedArray objectAtIndex:i]]);
		}
		NSLog(@"done testing first insertion");

		while([mutableArray count])
		{
			randomnumber =  random()%[mutableArray count];
	//		NSLog(@"%d",randomnumber);
	//		NSLog(@"removing object  ( =%@ )\n%@\n%@",[mutableArray objectAtIndex:randomnumber],mutableArray,sortedArray);
			randomNumber = [mutableArray objectAtIndex:randomnumber];
			[mutableArray removeObject:randomNumber];
			[sortedArray removeObject:randomNumber];			
			assert([mutableArray count] == [sortedArray count]);

			for(j=0;j<[mutableArray count];j++)
			{
				assert([[mutableArray objectAtIndex:j] isEqual:[sortedArray objectAtIndex:j]]);
			}
	//		NSLog(@"ok");
		}

		NSLog(@"done 2");

		NSLog(@"Done test %d",++testnumber);
		[pool release];
	}
}