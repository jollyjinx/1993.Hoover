#!/bin/perl

while(<>)
{
	if( /^([a-zA-Z\.]+):(\d+\.\d+):([a-zA-Z\.]+):(\d+\.\d+):(.*)$/ )
	{
		$languagename1 = $1;
		$languagepercent1 = $2;
		$languagename2 = $3;
		$languagepercent2 = $4;
		if( ($languagepercent1 > 20) && ($languagepercent1 > 3*$languagepercent2) )
		{
			@words = split(/:/,$5);
			if( ($#words > 4) && open(LANGUAGEFILE,">>$languagename1.clean") )
			{
				print LANGUAGEFILE 'SEN:'.$5."\n";
				close(LANGUAGEFILE);
			}
			else
			{
				print STDERR "Can't open $languagename1.clean\n";
			}
		}
		else
		{
			print STDERR $_;	
		}
	}
}

