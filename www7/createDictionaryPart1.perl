#
#
#
# perl5 -n -e 'if( /^(\d+)([a-z]+)\s+(.*)$/ ){print $2.$1." ".$3."\n";}' <blafasel |sort -n >languages

$|=1;

@languagefilenames = @ARGV;

while( $filename = shift(@ARGV) )
{
	undef %countrywords;
	undef %countryservers;
	
	$wordsinthecountry=0;
	
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
				$wordsinthecountry++;
				$countrywords{$word}.= $servernumber .':';
			}
		}
	}
	close(COUNTRY);
	print STDERR "done.\n";


	open(COUNTRYOUT,"|sort -rn |head -20000 >$filename.head") || die "Can't write $filename.out [$!] \n";
	while( ($word,$value) = each %countrywords )
	{
		undef %localservers;
		
		@sources=split(':',$value);
		while( $servernumber = pop(@sources) )
		{
			$localservers{$servernumber} = 1;
		}
		@localkeys = keys(%localservers);
		print COUNTRYOUT $word.' '.($#localkeys +1 ).'/'.$wordsinthecountry."\n";
	}
	close(COUNTRYOUT);
}

