#
#	title	:	wwwCreateDictionarys.perl
#	author	:	Patrick Stein <jolly@joker.de>
#	version	:	1.00
#	date	:	Sun Jun 30 09:28:07 MET DST 1996

use GDBM_File;

dbmopen(%languageUrlDatabase,'languageUrlDatabase',0666);
dbmopen(%languageWordDatabase,'languageWordsDatabase',0666);

while( ($key,$value) = each %languageWordDatabase )
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
	print $wordcount,%country,"      ",$key."\n";
}

