#
#
#
# perl5 -n -e 'if( /^(\d+)([a-z]+)\s+(.*)$/ ){print $2.$1." ".$3."\n";}' <blafasel |sort -n >languages


%globalwords = ();
$|=1;

while( $filename = shift(@ARGV) )
{
	%countrywords = ();
	%countryservers = ();
	
	open(COUNTRY,"<$filename") || die "Can't open $filename [$!]\n";
	print STDERR "Reading file: $filename\n";
	while( $_ = <COUNTRY>)
	{
		print STDERR '#' if 0==$.%1000;
		if( /^URL:(.*)$/ )
		{
			$server = $1;
			$server =~ s/^http:\/\/([^\/:]+).*$/\1/;
			if( $countryservers{$server} )
			{
				$servernumber = $countryservers{$server};
			}
			else
			{
				$servernumber = ++$servercount;
				$countryservers{$server} = $servernumber;
			}
		}
		
		if( /^SEN:(.*)$/ )
		{			
			@words = split(':',$1);
			while( $word = pop(@words) )
			{
				$countrywords{$word}.= $servernumber .':';
			}
		}
	}
	close(COUNTRY);
	print STDERR "done.\n";

	while( ($word,$value) = each %countrywords )
	{
		%localservers = ();
		
		@sources=split(':',$value);
		while( $servernumber = pop(@sources) )
		{
			$localservers{$servernumber} = 1;
		}
		@localkeys = keys(%localservers);
		$globalwords{$word} .= $#localkeys+1 . $filename;
	}
}


while( ($word,$value) = each %globalwords )
{
	print $value.'     '.$word."\n";
}
