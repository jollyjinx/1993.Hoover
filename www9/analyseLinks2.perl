#analyseLinks.perl

require "entityConverter.perl";

$|=1;

@filenames= @ARGV;
$stopwordfile=shift(@filenames);
if( open( STOPWORDS , $stopwordfile) )
{
	print STDERR "Reading frequency list\n";
	while( $_ = <STOPWORDS> )
	{
		if( /^(.*):(\d+)\/(\d+)$/ && ( ($2/$3) > (1/2000) ))
		{
			$stopword{$1}=1;
			$stopwordcount +=$2;
			$total = $3;
			# print STDERR $1."\n";
		}
	}
	close(STOPWORDS);
	printf STDERR "Stopwords are %4.2f %% of $stopwordfile\n",( 100*($stopwordcount/$total) );
}


while( $linkfile = shift(@filenames) )
{
	if( open(FILE,$linkfile) )
	{
		print "Reading $linkfile :";
		while( $_ = <FILE>)
		{
			print STDERR '#' if 0==$.%1000;
			if( /^URL:http:\/\/(.*)$/ )
			{
				$source=tell(FILE)-length($_);
			}
			if( /^LIN:(.*?)\s(.*)$/ )
			{
				$destination=tell(FILE)-length($_);
				$_=$2;
				tr/A-Z/a-z/;
				
				s{ < [^>]* > }{ }gx;
				&decode_entities($_);
				s/[!\?;&]+/ . /g;							# semicoli,exclamation and question marks now fullstops
				&encode_entities($_);
				s/&#?[0-9 ]*;/ /g;					 		# remove every special html character
				s/(-)+/-/g;
				s/\s-/ /g;									# 'fasel -bla' gets 'fasel bla'
				s/-\s/ /g;									# 'fasel - bla' and 'fasel- bla'  gets 'fasel bla'
				s/[^0-9a-zA-Z&;!?.@-]+/ /g;					# remove unneeded characters
				@words=grep(/^([A-Za-z0-9\-]|&[A-Za-z]+;){2,}$/,(split(/ /,$_)) );
				
				@store=();
				while( $word=pop(@words))
				{
					if( ! $stopword{$word} )
					{
						$wordpointsto{$word}{$destination}=''; 	
						push(@store,$word);
					}
				}
				$linkspointto{$destination}{$source}=join(':',@store);
			}
		}
		close(FILE);
	}
}	

print "done.\n";
print "Ready.\n";

$filename=$ARGV[1];
open(FILE,$filename) || die "Can't open $filename because: $!\n";

while($_ = <STDIN>)
{
	undef %global;
	undef %globalwords;
	undef @globallinks;
	chop;
	tr/A-Z/a-z/;
	$input = $_;
	print "WORD:$_\n";
	@destinations = keys( %{$wordpointsto{$input}} );
	foreach $destination (@destinations)
	{
		seek(FILE,$destination,0);
		chop($nameof{$destination}= <FILE>);
		$nameof{$destination}=~ s/\s.*$//;
		$nameof{$destination}=~ s/\/$/\/index.html/;
		print $nameof{$destination}."\n";
	}
	foreach $destination (@destinations)
	{
		@sources = keys( %{$linkspointto{$destination}} );

		foreach $source (@sources)
		{
			foreach $word ( split(/:/, $linkspointto{$destination}{$source}) )
			{
				$global{$word}{$nameof{$destination}}='';
			}
		}
	}
	undef %nameof;
	
	print "Woerter die mit $input zu tun haben:\n";
	foreach $word ( keys( %global ) )
	{
		foreach $destination ( keys( %{$global{$word}} ) )
		{
			print ' '.$word.' '.$destination."\n";
		}
	}
	
	print "\n";
	print "done.\n";
	print "Ready.\n";
}

