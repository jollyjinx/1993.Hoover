#
#	title	:	wwwShowLanguageDatabase.perl		WWW proxycache fill
#	author	:	Patrick Stein <jolly@joker.de>
#	version	:	1.00
#	date	:	Sat Jun 29 21:39:02 MET DST 1996

use GDBM_File;

dbmopen(%languageUrlDatabase,'languageUrlDatabase',0666);
dbmopen(%languageSentenceDatabase,'languageSentenceDatabase',0666);
dbmopen(%languageWordDatabase,'languageWordsDatabase',0666);

while($_=pop(@ARGV))
{
	print '%languageUrlDatabase['.$_.']='.$languageUrlDatabase{$_}."\n";
	print '%languageSentenceDatabase['.$_.']='.$languageSentenceDatabase{$_}."\n";
	print '%languageWordDatabase['.$_.']='.$languageWordDatabase{$_}."\n";
}

