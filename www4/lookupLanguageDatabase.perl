#
#
#
#perl5 ~/Perl/www2/lookupLanguageDatabase.perl trigrams | perl5 -n -e 'if( /^(\d+)([a-z]+)(\d+)\s+(.*)$/ && $1 eq $3 && $1>5 ){print $2." ".$4."\n";}'


%country = ();
%servers = ();
$servercount = 0;
$|=1;

while( $filename = shift(@ARGV) )
{
	open(COUNTRY,"<$filename") || die "Can't open $filename [$!]\n";
	print STDERR "Reading file: $filename\n";
	while( $_ = <COUNTRY>)
	{
		print STDERR '#' if 0==$.%1000;
		if( /^URL:(.*)$/ )
		{
			$server = $1;
			$server =~ s/^http:\/\/([^\/:]+).*$/\1/;
			if( $servers{$server} )
			{
				$servernumber = $servers{$server};
			}
			else
			{
				$servernumber = ++$servercount;
				$servers{$server} = $servernumber;
				$servernumber{$servernumber} = $server;
			}
		}
		
		if( /^SEN:(.*)$/ )
		{			
			@words = split(':',$1);
			while( $word = pop(@words) )
			{
				if( !defined($country{$word}) )
				{
					$country{$word}=$servernumber;
				}
				else
				{
					@serverarray = split(':', $country{$word});
					push(@serverarray,$servernumber) if !grep(/^$servernumber$/, @serverarray);
					$country{$word}=join(':', @serverarray);
				}
			}
		}
	}
	close(COUNTRY);
	print STDERR "done.\n";
}


while( ($word,$value) = each %country )
{
	$wordcount = 0;
	%countries = ();
	
	@sources=split(':',$value);
	while( $servernumber=pop(@sources) )
	{
		$wordcount++;
		@attributes = split(/\./, $servernumber{$servernumber});
		$countries{pop(@attributes)}++;
	}
	print $wordcount,%countries,"     ", $word."\n";
}
