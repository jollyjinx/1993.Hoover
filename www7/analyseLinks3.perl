#analyseLinks.perl

require "entityConverter.perl";
require "wwwurl.pl";

$|=1;

@filenames= @ARGV;

while( $linkfile = shift(@filenames) )
{
	if( open(FILE,"<$linkfile") )
	{
		print "Reading $linkfile :";
		while( $_ = <FILE>)
		{
			print STDERR '#' if 0==$.%1000;
			if( /^URL:(.*)$/ )
			{
				$actualpage = $1;
				$pageisat{$actualpage}=tell(FILE);
			}
			if( /^LIN:(.*?)\s(.*)$/ )
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
				
				# $linkspointto{$link}{$actualpage}=''; #join(':',@words);
				while( $word=pop(@words))
				{
					$wordpointsto{$word}{$link}++;
				}
			}
		}
		close(FILE);
		print "done\n";
	}
}



print "Ready.\n";
while($_ = <STDIN>)
{
	undef %global;
	undef %globalwords;
	undef %words;
	undef @globallinks;
	chop;
	tr/A-Z/a-z/;
	$input = $_;
	
	print "WORD:$_\n";
	@pagesfound = keys( %{$wordpointsto{$input}} );
	$pagecount=1;
	foreach $url (@pagesfound)
	{
		$global{$url}=$pagecount++;
		print "\t".$wordpointsto{$input}{$url}.' '.$url.' pc='.$global{$url}."\n";
	}
	
	foreach $url (@pagesfound)
	{
		if( $pageisat{$url} )
		{
			@mom = &wwwurl'parse($url);				
			$country = $mom[1];						
			$country =~ tr/A-Z/a-z/;			
			$country =~ s/.*\.([^\.]+)$/$1/;
			
			if( open(LANGUAGE,"<$country") )
			{
				print "Reading $url from file filename $country at position $pageisat{$url}";
				seek(LANGUAGE,$pageisat{$url},0);
				$reading=1;
				while( ($_=<LANGUAGE>) && $reading )
				{
					if( /^URL:http:\/\/(.*)$/ )
					{
						$reading=0;
					}
					if( $reading && /^SEN:(.*)$/ )
					{
						foreach $word (split(/:/,$1))
						{
							$globalwords{$word}{$global{$url}}='';
						}
					}		
				}
				close(LANGUAGE);
				print " done.\n";
			}
		}
	}
	

	print "Woerter die mit $input zu tun haben:\n";
	foreach $word ( keys( %globalwords ) )
	{
		@count= keys( %{$globalwords{$word}} );
		print 1+$#count.' '.$word.' found on:'.join(':',@count)."\n";
	}
	
	print "done.\n";
	print "Ready.\n";
}

