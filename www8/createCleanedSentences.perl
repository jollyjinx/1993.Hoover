

while(<>)
{
	if( /^([a-z]+):(\d+\.\d+):([a-z]+):(\d+\.\d+):(.*)$/ )
	{
		if( $2 > 80 && ($2-$4 >30) )
		{
			if( open(LANGUAGEFILE,">>$1.clean") )
			{
				print LANGUAGEFILE 'SEN:'.$5."\n";
				close(LANGUAGEFILE);
			}
			else
			{
				print STDERR "Can't open $1.clean\n";
			}
		}
	}
}

