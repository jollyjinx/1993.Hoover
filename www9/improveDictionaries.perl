

require "TrigramRecognizer3.pm";

$|=1;

$recognizer = TrigramRecognizer->new();

$recognizer->{'countrydirectory'}=$ENV{'DICTIONARY_DIRECTORY'}.'/altavistaiso';
# $recognizer->{'debug'}=1;
$recognizer->buildCache();

while(<>)
{
	print STDERR '#' if 0==$.%1000;
	if( /^SEN:(.*)$/ )
	{
		$originalline = $1;
		$line = $originalline;
		$line =~ tr/A-Z/a-z/;
		@words = split(/:/,$line);
		
		%sorted = $recognizer->recognizeSentence(@words);
		($first,$second) = (sort {$sorted{$b} <=> $sorted{$a} } (keys %sorted));
	
		printf STDOUT "%s:%2.2f:%s:%2.2f:%s\n",$first,$sorted{$first},$second,$sorted{$second}, $originalline;
	}
}
