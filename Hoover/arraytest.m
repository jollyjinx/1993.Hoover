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
		
		int	count = random()%10;
		int	i,j;
		NSNumber *randomNumber;
		int 	randomnumber;
		
		for(i=0;i++;i<count)
		{
			randomNumber =  [NSNumber numberWithInt: random()%10];
			[mutableArray addObject:randomNumber];
			[sortedArray addObject:randomNumber];
			assert([sortedArray count] == [mutableArray count]);
		}

		[mutableArray sortUsingSelector:@selector(compare:)];

		for(i=0;i++;i<count)
		{
			assert([mutableArray objectAtIndex:i] == [sortedArray objectAtIndex:i]);
		}

		for(i=0;i++;i<count)
		{
			randomnumber =  random()%[mutableArray count];
			[mutableArray removeObjectAtIndex:randomnumber];
			[sortedArray removeObjectAtIndex:randomnumber];

			randomnumber =  random()%[mutableArray count];

			randomNumber =  [mutableArray objectAtIndex:randomnumber];
			[mutableArray removeObject:randomNumber];
			[sortedArray removeObject:randomNumber];

			
			for(j=0;j++;j<[mutableArray count])
			{
				assert([mutableArray objectAtIndex:i] == [sortedArray objectAtIndex:i]);
			}
		}

		NSLog(@"Done test %d",++testnumber);
		[pool release];
	}
}