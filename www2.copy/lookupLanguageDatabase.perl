#
#
#
#perl5 ~/Perl/www2/lookupLanguageDatabase.perl words | perl5 -n -e 'if( /^(\d+)([a-z]+)(\d+)\s+(.*)$/ && $1 eq $3 && $1>5 ){print $2." ".$4."\n";}'

use GDBM_File;

dbmopen(%languageUrlDatabase,'language.url.gdbm',0666);
dbmopen(%languageWordDatabase,'language.word.gdbm',0666);
dbmopen(%languageBigramDatabase,'language.bigram.gdbm',0666);

# shift @ARGV;
if($ARGV[0] eq 'bigrams')
{
	while( ($bigram,$value) = each %languageBigramDatabase )
	{
		%country=();
		$wordcount=0;
		
		@sources=split(':',$value);
		while($urlnumber=pop(@sources))
		{
			$wordcount++;
			
			$urlname=$languageUrlDatabase{$urlnumber};
			$urlname =~ s/^http:\/\/([^\/:]+).*$/\1/;
			$urlname =~ s/.*\.([^\.]+)$/\1/;
			$country{$urlname}++;
		}
		print $wordcount,%country,"      ",$bigram."\n";
	}
	exit;
}

if($ARGV[0] eq 'words')
{
	while( ($word,$value) = each %languageWordDatabase )
	{
		%country=();
		$wordcount=0;
		
		@sources=split(':',$value);
		while($urlnumber=pop(@sources))
		{
			$wordcount++;
			
			$urlname=$languageUrlDatabase{$urlnumber};
			$urlname =~ s/^http:\/\/([^\/:]+).*$/\1/;
			$urlname =~ s/.*\.([^\.]+)$/\1/;
			$country{$urlname}++;
		}
		print $wordcount,%country,"      ", $word."\n";
	}
	exit;
}


while( $ask = shift(@ARGV) )
{
	print '['.$ask.'] ';
	if( $languageBigramDatabase{$ask} )
	{
		@urlnumbers=split(':', $languageBigramDatabase{$ask});
		print 'found on :'.$languageBigramDatabase{$ask}."\n";
		while( $number=pop(@urlnumbers) )
		{
			print $languageUrlDatabase{$number}."\n";
		}
	}
	if( $languageWordDatabase{$ask} )
	{
		@urlnumbers=split(':',$languageWordDatabase{$ask});
		print 'found on :'.$languageWordDatabase{$ask}."\n";
		while( $number=pop(@urlnumbers) )
		{
			print $languageUrlDatabase{$number}."\n";
		}
	}
	print "\n";
}

dbmclose(%languageUrlDatabase);
dbmclose(%languageWordDatabase);
dbmclose(%languageBigramDatabase);

exit;
