
select(STDERR);$|=1;
select(STDOUT);

while( $filename = shift(@ARGV) )
{
	if( open(COUNTRYIN,"<$filename.head") )
	{
		print STDERR "reading: $filename.head";
		while( $_ = <COUNTRYIN>)
		{
			chop;
			($count,$word) = split(/ /,$_);
			$_ = $word;
			s/[\?!\.-]+$//g;
			tr/A-Z/a-z/;
			if( !/^\-/ && /(([A-Za-z0-9-]|&[A-Za-z]+;){2,})/ && !/^[0-9\.;&\- ]*$/)
			{
				$globalwords{$1}{$filename}+=$count;
			}
		}
		close(COUNTRYIN);
		print STDERR " done.\n";
	}
}


while( ($word,$value) = each %globalwords )
{
	@countries = keys(%{$value});
	
	while( $country = pop(@countries) )
	{
		print $country.$globalwords{$word}{$country};
	}
	print "\t\t".$word."\n";
}

