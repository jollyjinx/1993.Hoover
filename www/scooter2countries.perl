

while(<>)
{
	if( /^@\s*\+\s*http:\/\/(\S*)/ )
	{
		$flag=0;
		$newurl = $1;
		
		$_ = $url;
		if( /^([^:\/]*)/ )
		{
			print STDERR "Got urlsite:$1\n";
			(@domains) = split(/\./,$1);
			$_ = pop(@domains);
			tr/A-Z/a-z/;
			if( /^[a-z]{2,3}$/ )
			{
				$countrycode = $_;
				open(COUNTRY ,">>$countrycode") || die "Can't open $countrycode $!";
				print COUNTRY	'URL: http://'.$url."\n\n";
				print COUNTRY $contents;
				close(COUNTRY);
			}
		}
		$url = $newurl;
		undef $contents;
		undef @sentences;
	}
	else
	{	
		$contents.=$_ if $flag;
		
		if( /^\s*$/ )
		{
			$flag=1;
		}
	}
}