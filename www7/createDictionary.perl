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
	undef %servernametonumber;
	undef %servernumbertoname;
	
	open(COUNTRY,"<$filename") || die "Can't open $filename [$!]\n";
	print STDERR "Reading file: $filename\n";
	while( $_ = <COUNTRY>)
	{
		print STDERR '#' if 0==$.%1000;
		if( /^URL:(.*)$/ )
		{
			$servername = $1;
			$servername =~ s/^http:\/\/([^\/:]+).*$/\1/;
			if( $servernametonumber{$servername} )
			{
				$servernumber = $servernametonumber{$servername};
			}
			else
			{
				$servernumber = ++$servercount;
				$servernametonumber{$servername} = $servernumber;
				$servernumbertoname{$servernumber} =$servername;
			}
		}
		
		if( /^SEN:(.*)$/ )
		{			
			@words = split(':',$1);
			while( $word = pop(@words) )
			{
				$countrywords{$word}{$servernumber}=1;
				$countryservers{$servernumber}{$word}=1;
			}
		}
	}
	close(COUNTRY);
	print STDERR "done.\n";


	open(COUNTRYOUT,">$filename.allwords") || die "Can't write $filename.allwords [$!] \n";
	while( ($word,$servernumbers) = each %countrywords )
	{
		
		@servernumbers = keys( %{$servernumbers} );
		print COUNTRYOUT ($#servernumbers+1).' '.$word."\n";
	}
	close(COUNTRYOUT);
	
	open(COUNTRYOUT,">$filename.allservers") || die "Can't write $filename.allservers [$!] \n";
	while( ($servernumber,$value) = each %countryservers )
	{
		@localkeys = keys(%{$value});

		print COUNTRYOUT 'SERV:'.$servernumbertoname{$servernumber}."\n";
		print COUNTRYOUT 'WORD:'.join(':',keys(%{$value}))."\n";
	}
	close(COUNTRYOUT);
}

	undef %countrywords;
	undef %countryservers;
	undef %servernametonumber;
	undef %servernumbertoname;

while( $filename = shift(@languagefilenames) )
{
	open(COUNTRYIN,"<$filename.allwords") || die "Can't read $filename.allwords [$!] \n";
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




