# perl -ne 'if(/^SEN:/){s/:/ /g;s/^SEN//;tr A-Z a-z ;print $_;}' <de |~/Binaries/osf4.0/frequency |sort >../frequenzliste.d

@countryfiles = @ARGV;

$|=1;
print STDERR "Input:";

while( $line = <STDIN> )
{
	undef %foundwords;
	undef %sorted;

	$line =~ tr/A-Z/a-z/;
	chop($line);
	@words = split(/ /,$line);
	while( $word = shift(@words) )
	{
		undef %wordfactor;
		$wordsum = 0;
		
		foreach $country (@countryfiles)
		{
			if( open(COUNTRYFILE,"look \'$word:\' $country |") )
			{
				while( $_ = <COUNTRYFILE> )
				{
					if( /^$word:(\d+)\/(\d+)$/)
					{
						$factor = ($1/$2);
						$wordsum += $factor;
						$wordfactor{$country} = $factor;
						
#						printf "$country SUM:%5.4e FAC:%5.4e\n",$wordsum,$factor;
					}
				}
				close(COUNTRYFILE);
			}
		}
		
		$percent=0;
		foreach $country (keys %wordfactor)
		{
			$percentthistime = $wordfactor{$country}/$wordsum;
			$foundwords{$country} += $percentthistime ;
#			printf "COUNTRY:%s %5.4f %5.4f   %5.4f\n",$country,$wordsum,$percentthistime, $foundwords{$country} ;
			$percent+=$percentthistime;
		}
		
	}
		
	$allpercent = 0;
	foreach $country (keys %foundwords )
	{
		$allpercent += $foundwords{$country};
	}

	while( ($country,$count)=each(%foundwords) )
	{
		$sorted{($count*100)/$allpercent}.=$country.':';
	}
	$percent=0;
	foreach $key (sort {$a <=> $b} (keys %sorted))
	{
		printf "%2.2f%% $sorted{$key}\n",$key;
		$percent +=  $key;
	}
	printf "Percent = %4.2f\n",$percent;
	print "Input:";
}


