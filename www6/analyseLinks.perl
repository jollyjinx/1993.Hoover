#analyseLinks.perl

require "entityConverter.perl";

$|=1;


while( $filename = shift(@ARGV) )
{
	if( open(FILE,"<$filename") )
	{
		while( $_ = <FILE>)
		{
			print STDERR '#' if 0==$.%1000;
			if( /^URL:(.*)$/ )
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
				
				$linkspointto{$link}{$actualpage}=join(':',@words);
				while( $word=pop(@words))
				{
					$wordpointsto{$word}{$link}++;
				}
			}
		}
		close(FILE);
	}
}

print STDERR "done.\n";
while(<>)
{
	undef %globalwords;
	chop;
	tr/A-Z/a-z/;
	print "WORD:$_\n";
	@pagesfound = keys( %{$wordpointsto{$_}} );
	foreach $page (@pagesfound)
	{
		print "\t".$wordpointsto{$_}{$page}.' '.$page."\n";
	}
	foreach $page (@pagesfound)
	{
		@links = keys( %{$linkspointto{$page}} );
		# print "\nLINKS:\n\t".join("\n\t",@links);
		foreach $link (@links)
		{
			@words=split(/:/,$linkspointto{$page}{$link});
			foreach $word (@words)
			{
				$globalwords{$word}++;
			}
		}
	}
	print "Woerter die mit $_ zu tun haben:\n";
	foreach $word ( keys( %globalwords ) )
	{
		print $globalwords{$word}.' '.$word."\n";
	}

	print "\n";
}

