

require "ZipfTrigramRecognizer.pm";

$|=1;

$recognizer = ZipfTrigramRecognizer->new();

$recognizer->{'countrydirectory'}=$ENV{'DICTIONARY_DIRECTORY'}.'/bla';
# $recognizer->{'debug'}=1;
$recognizer->buildCache();

while(<>)
{
	print STDERR '#' if 0==$.%1000;
	if( /^SEN:(.*)$/i )
	{
		$line = $1;
		@words = split(/:/,$line);
		
		%sorted = $recognizer->recognizeSentence(@words);
		($first,$second) = (sort {$sorted{$b} <=> $sorted{$a} } (keys %sorted));
	
		printf STDOUT "%s:%2.2f:%s:%2.2f:%s\n",$first,$sorted{$first},$second,$sorted{$second}, $line;
	}
}
