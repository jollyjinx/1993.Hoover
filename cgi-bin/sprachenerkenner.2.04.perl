#!/usr/local/bin/perl5.002

require "entityConverter.perl";
require "Recognizer.pm";

%isoToCountry = ( 	'cz','Czeck',
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
					'is','Icelandic',
					'it','Italian',
					'lu','Lithuanian',
					'nl','Dutch',
					'no','Norwegean',
					'pl','Polish',
					'pt','Portugese',
					'se','Swedish',
					'sk','Sloviakia',
					'tr','Turkish'
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
	s/[^0-9a-zA-Z&;!?.@-]+/ /g;					# remove unneeded characters
	s/(-)+/-/g;									# '--- this ---' becomes '- this -'
	s/\d\./$1/;									# '1. Januar'  becomes '1 Januar'
	s/\s-/ /g;									# 'fasel -bla' becomes 'fasel bla'
	s/-\s/ /g;									# 'fasel - bla' becomes 'fasel- bla'  gets 'fasel bla'
	s/\s+/ /g;
	s/^\s+//;
	s/\s+$//;
	tr/A-Z/a-z/;
@sentence = split(/ /,$_);

if( open(LOG,">>logfile") )
{
	print LOG `date`,join(' ',@sentence),"\n";
	close(LOG);
}


$recognizer = Recognizer->new();
$recognizer->{'cache'} = 1;
$recognizer->{'countrydirectory'}='/usr/import/watzmann_data/Watzmann_data/jolly/altavista';
$recognizer->{'countryfileextension'}='10000';
%sortedAll10000 = $recognizer->recognizeSentence(@sentence);

$recognizer->{'countryfileextension'}='noenglish';
%sortedAll 	= $recognizer->recognizeSentence(@sentence);



print "Content-type: text/html\n\n";
print "<html>\n<head>\n<Title>Sprachenerkenner - Best&auml;tigung\n</title>\n</head>\n";
print "<body>Sentence to analyse: <b>",join(' ',@sentence),"</b><br><br>\n";
print "Seems to be written in:<br>\n\n";


print "<table border=0 cellspacing=0 cellpadding=0><tr>\n";

print "<td><table border><tr><th>Method Top10000<th>Country\n";
foreach $key (sort {$sortedAll10000{$a} <=> $sortedAll10000{$b}} (keys %sortedAll10000))
{
	printf "<tr><td>%s<td>%2.2f%\n",$isoToCountry{$key},$sortedAll10000{$key};
}
print "</table>\n";

print "<td><table border><tr><th>Method All<th>Country\n";
foreach $key (sort {$sortedAll{$a} <=> $sortedAll{$b}} (keys %sortedAll))
{
	printf "<tr><td>%s<td>%2.2f%\n",$isoToCountry{$key},$sortedAll{$key};
}
print "</table>\n";

print "</table>\n";


print '<br>Falls eine Sprache <b>falsch</b> erkannt wurde bitte <b><a href="mailto:jolly@cis.uni-muenchen.de">ich</a></b> um eine mail.'."\n";
print "<br>In case the analyser turned down the correct language, I\'d like to receive a".' <a href="mailto:jolly@cis.uni-muenchen.de">mail</a>.'."\n";
print "</body></html>\n";

exit;

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


