#analyseLinks.perl

require "entityConverter.perl";

$|=1;

$linkfile = shift( @ARGV );
@filenames= @ARGV;

if( open(FILE,"<$linkfile") )
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
			
			# $linkspointto{$link}{$actualpage}=''; #join(':',@words);
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
	undef %words;
	undef @globallinks;
	chop;
	tr/A-Z/a-z/;
	$input = $_;
	
	print "WORD:$_\n";
	@pagesfound = keys( %{$wordpointsto{$input}} );
	$pagecount=1;
	foreach $page (@pagesfound)
	{
		$global{$page}=$pagecount++;
		print "\t".$wordpointsto{$input}{$page}.' '.$page.' pc='.$global{$page}."\n";
	}
	
	foreach $filename (@filenames)
	{
		if( open(LANGUAGE,"<$filename") )
		{
			print "Reading $filename";
			while( $_=<LANGUAGE> )
			{
				if( /^URL:http:\/\/(.*)$/ )
				{
					$reading=0;
					$reading=$1 if defined( $global{$1} );
				}
				if( $reading && /^SEN:(.*)$/ )
				{
					foreach $word (split(/:/,$1))
					{
						$globalwords{$word}{$global{$reading}}='';
					}
				}		
			}
			close(LANGUAGE);
			print " done.\n";
		}
	}
	

	print "Woerter die mit $input zu tun haben:\n";
	foreach $word ( keys( %globalwords ) )
	{
		@count= keys( %{$globalwords{$word}} );
		print 1+$#count.' '.$word.' found on:'.join(':',@count)."\n";
	}
	
	print "done.\n";
}

