#
#
#
#perl5 ~/Perl/www2/lookupLanguageDatabase.perl trigrams | perl5 -n -e 'if( /^(\d+)([a-z]+)(\d+)\s+(.*)$/ && $1 eq $3 && $1>5 ){print $2." ".$4."\n";}'


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
				$countrywords{$word}.=$servernumber;

#				if( !defined($countrywords{$word}) )
#				{
#					$countrywords{$word}=$servernumber;
#				}
#				else
#				{
#					@serverarray = split(':', $countrywords{$word});
#					push(@serverarray,$servernumber) if !grep(/^$servernumber$/, @serverarray);
#					$countrywords{$word}=join(':', @serverarray);
#				}
			}
		}
	}
	close(COUNTRY);
	print STDERR "done.\n";


	while( ($word,$value) = each %countrywords )
	{
		$countrycount;
		
		@sources=split(':',$value);
		$globalwords{$word} .= $#sources+1 . $filename;
	}
		
}


while( ($word,$value) = each %globalwords )
{
	print $value.'     '.$word."\n";
}
