#!/usr/bin/perl5

require "myEntityConverter.perl";
require "ZipfTrigramRecognizer.pm";

%isoToCountry = ( 	'be','Belgium',
					'br','Brazilia',
					'cz','Czeck',
					'de','German',
					'dk','Danish',
					'ee','Estonian',
					'en','English',
					'es','Spanish',
					'fi','Finnish',
					'fr','French',
					'gr','Greek',
					'hk','Bulgarian',
					'hu','Hungarian',
					'ie','Eire',
					'is','Icelandic',
					'it','Italian',
					'jp','Japanese',
					'kr','Korea',
					'lu','Luxembourg',
					'lt','Lithuanian',
					'mx','Mexican',
					'nl','Dutch',
					'no','Norwegean',
					'pl','Polish',
					'pt','Portugese',
					'ro','Romania',
					'ru','Russia',
					'ruiso','Russia iso5',
					'ruiso5','Russia iso5',
					'rukio8r','Russia kior8',
					'se','Swedish',
					'si','Slovenia',
					'sk','Sloviakia',
					'tr','Turkish',
					'th','Thailand',
					'tw','Taiwan',
					'za','China'
	 );


read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
@parameter = split(/&/,$buffer);
while( $param = shift(@parameter) )
{
	($attribute,$value) = split(/=/,$param);
	$attribute{$attribute} = $value;
}



$_ = &UrlEncode($attribute{'text'});
	&decode_entities($_);
	s/[!\?\.]+/ /g;								# exclamation and question marks now SPACE !!
	s/[\;\,]+/ /g;								# semicoli,kommata now spaces
	&encode_entities($_);
	s/&#?[0-9 ]*;/ /g;					 		# remove every special html character
	s/[^0-9a-zA-Z&;-]+/ /g;						# remove unneeded characters
	s/(-)+/-/g;									# '--- this ---' becomes '- this -'
	s/\d\./$1/;									# '1. Januar'  becomes '1 Januar'
	s/\s-/ /g;									# 'fasel -bla' becomes 'fasel bla'
	s/-\s/ /g;									# 'fasel - bla' becomes 'fasel- bla'  gets 'fasel bla'
	s/\s+/ /g;
	s/^\s+//;
	s/\s+$//;
	tr/A-Z/a-z/;
	&decode_entities($_);

@sentence = split(/ /,$_);

if( open(LOG,">>logfile") )
{
	print LOG `date`,'SEN:',join(' ',@sentence),"\n";
	print LOG $ENV{'LOGNAME'},"\n";
	print LOG $ENV{'REMOTE_HOST'},"\n";
	print LOG $ENV{'REMOTE_ADDR'},"\n";
	close(LOG);
}
	
print "Content-type: text/html\n\n";
print "<html>\n<head>\n<Title>Sprachenerkenner - Best&auml;tigung\n</title>\n</head>\n";
print "<body>Sentence to analyse: <b>",join(' ',@sentence),"</b><br>\n";
print "Thanx for your help <b>",$ENV{'LOGNAME'},"</b>. ";
print "You were logged in from :",$ENV{'REMOTE_HOST'},"(",$ENV{'REMOTE_ADDR'},")<br><br>\n";
print "Seems to be written in:<br>\n\n";


print "<table border=0 cellspacing=0 cellpadding=0><tr>\n";

if( opendir(DICTIONARYDIR, $ENV{'DICTIONARY_DIRECTORY'}.'/') )
{
	@dictionaries=sort(grep(/^[a-zA-Z0-9].*$/,readdir(DICTIONARYDIR)));
	closedir(DICTIONARYDIR);
}


while( $dictionary=shift(@dictionaries) )
{
	$recognizer = ZipfTrigramRecognizer->new();
	$recognizer->{'countrydirectory'}=$ENV{'DICTIONARY_DIRECTORY'}.'/'.$dictionary;
	if( $dictionaryinfo = $recognizer->dictionaryInfo() )
	{
		$recognizer->buildCache();
		%sorted = $recognizer->recognizeSentence(@sentence);
	
		print "<td><table border><tr><th>$dictionaryinfo<th>%\n";
		foreach $key (sort {$sorted{$a} <=> $sorted{$b}} (keys %sorted))
		{
			$isoToCountry{$key}=$key if !$isoToCountry{$key};
			printf "<tr><td>%s<td>%4.2f\n", $isoToCountry{$key}, $sorted{$key};
			if( open(LOG,">>logfile") )
			{
				printf LOG "%2.2f %s\n", $sorted{$key}, $isoToCountry{$key};
				close(LOG);
			}
		}
		print "</table>\n";
	}
}

print "</table>\n";


print '<br>Falls eine Sprache <b>falsch</b> erkannt wurde bitte <b><a href="mailto:jolly@cis.uni-muenchen.de">ich</a></b> um eine mail.'."\n";
print "<br>In case the analyser turned down the correct language, I\'d like to receive a".' <a href="mailto:jolly@cis.uni-muenchen.de">mail</a>.'."\n";
print "</body></html>\n";

exit 0;

sub UrlEncode
{
local ($_) = @_;
s/%([0-9A-F]{2})/pack('C',hex($1))/eig;
s/\+/ /g;
return $_;
}

sub UrlDecode
{
	local ($_) = @_;
	s|([\x00-\x1F"#%&+./:?\200-\377])|sprintf("%%%o2x",ord($1))|eg;
	s| |+|g;
	return $_;
}


