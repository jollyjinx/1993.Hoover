# perl -ne 'if(/^SEN:/){s/:/ /g;s/^SEN//;tr A-Z a-z ;print $_;}' <de |~/Binaries/osf4.0/frequency |sort >../frequenzliste.d


require "FastRecognizer.pm";

$|=1;

$recognizer = Recognizer->new();

$recognizer->{'countryfileextension'}='clean.5000';
$recognizer->buildCache();

print STDERR "Input:";
while( $line = <STDIN> )
{
	chop;
	$line =~ tr/A-Z/a-z/;
	$line =~ s/[\r\n]*//g;
	@words = split(/ /,$line);
	
	%sorted = $recognizer->recognizeSentence(@words);
	
	foreach $key (sort {$sorted{$a} <=> $sorted{$b}} (keys %sorted))
	{
		printf "Sentence %s  %2.2f%%\n",$key,$sorted{$key};
	}
	print "Input:";
}


