#
#
#
# perl5 -n -e 'if( /^(\d+)([a-z]+)\s+(.*)$/ ){print $2.$1." ".$3."\n";}' <blafasel |sort -n >languages

$|=1;

@languagefilenames = @ARGV;

while( $filename = shift(@ARGV) )
{
	undef %server;
	
	open(COUNTRY,"<$filename") || die "Can't open $filename [$!]\n";
	print STDERR "Reading file: $filename\n";
	while( $_ = <COUNTRY>)
	{
		print STDERR '#' if 0==$.%2000;
		if( /^URL:(.*)$/ )
		{
			$servername = $1;
			$servername =~ s/^http:\/\/([^\/:]+).*$/\1/;
		}
		
		if( /^SEN:(.*)$/ )
		{			
			@words = split(':',$1);
			while( $word = pop(@words) )
			{
				$server{$servername}{$word}++;
			}
		}
	}
	close(COUNTRY);
	print STDERR "done.\n";


	open(COUNTRYOUT,">$filename.out") || die "Can't write $filename.out [$!] \n";
	while( ($word,$value) = each %countrywords )
	{
		undef %localservers;
		
		@sources=split(':',$value);
		while( $servernumber = pop(@sources) )
		{
			$localservers{$servernumber} = 1;
		}
		@localkeys = keys(%localservers);
		print COUNTRYOUT ($#localkeys +1 ).' '.$word."\n";
	}
	close(COUNTRYOUT);
}

undef %countrywords;
undef %countryservers;
undef %globalwords;


while( $filename = shift(@languagefilenames) )
{
	open(COUNTRYIN,"<$filename.out") || die "Can't read $filename.out [$!] \n";
	while( $_ = <COUNTRYIN>)
	{
		chop;
		($count,$word) = split(/ /,$_); 
		$globalwords{$word} .=$count.$filename;
	}
	close(COUNTRYIN);
}

while( ($word,$value) = each %globalwords )
{
	print $value."\t\t".$word."\n";
}




