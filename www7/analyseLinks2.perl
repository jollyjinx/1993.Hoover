#analyseLinks.perl

require "entityConverter.perl";

$|=1;


if( open(FILE,"<$ARGV[0]") )
{
	while( $_ = <FILE>)
	{
		print STDERR '#' if 0==$.%1000;
		if( /^URL:http:\/\/(.*)$/ )
		{
			$actualpage = $1;
		}
		if( /^LIN:(.*?)NAME(.*)$/ )
		{
			$link=$1;
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
			
			$linkspointto{$link}{$actualpage}=''; #join(':',@words);
			while( $word=pop(@words))
			{
				$wordpointsto{$word}{$link}++;
			}
		}
	}
	close(FILE);
}

print STDERR "done.\n";
while($_ = <STDIN>)
{
	undef %global;
	undef %globalwords;
	undef @globallinks;
	chop;
	tr/A-Z/a-z/;
	$input = $_;
	print "WORD:$_\n";
	@pagesfound = keys( %{$wordpointsto{$input}} );
	foreach $page (@pagesfound)
	{
		print "\t".$wordpointsto{$input}{$page}.' '.$page."\n";
	}
	foreach $page (@pagesfound)
	{
		@links = keys( %{$linkspointto{$page}} );

		foreach $link (@links)
		{
				$global{$link}='';
		}
	}
	
	
	open(LANGUAGE,"<$ARGV[1]");
	while( $_=<LANGUAGE> )
	{
		if( /^URL:http:\/\/(.*)$/ )
		{
			$url=$1;
			$reading=0;
			$reading=$url if defined( $global{$url} );
		}
		if( $reading && /^SEN:(.*)$/ )
		{
			foreach $word (split(/:/,$1))
			{
				$globalwords{$word}++;
			}
		}		
	}
	close(LANGUAGE);
	
		
	print "Woerter die mit $input zu tun haben:\n";
	foreach $word ( keys( %globalwords ) )
	{
		print $globalwords{$word}.' '.$word."\n";
	}
	
	print "\n";
}

