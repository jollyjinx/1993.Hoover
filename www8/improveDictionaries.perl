
require "FastRecognizer.pm";

$recognizer = Recognizer->new();
$recognizer->{'countryfileextension'}='10000';
$recognizer->buildCache();
$|=1;
# $recognizer->{'debug'}=1;

while( $filename = shift(@ARGV) )
{
	if( open(FILE,"<$filename") )
	{
		while( $_ = <FILE>)
		{
			print STDERR '#' if 0==$.%1000;
			if( /^SEN:(.*)$/ )
			{
				$line = $1;
				$line =~ tr/A-Z/a-z/;
				@words = split(/:/,$line);
				
				%sorted = $recognizer->recognizeSentence(@words);
				($first,$second) = (sort {$sorted{$b} <=> $sorted{$a} } (keys %sorted));
				
				printf STDOUT "%s:%2.2f:%s:%2.2f:%s\n",$first,$sorted{$first},$second,$sorted{$second},join(':',(@words));
			}
		}
		close(FILE);
	}
}

close(RECOGNIZED);
