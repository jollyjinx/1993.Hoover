# perl -ne 'if(/^SEN:/){s/:/ /g;s/^SEN//;tr A-Z a-z ;print $_;}' <de |~/Binaries/osf4.0/frequency |sort >../frequenzliste.d


require "FastRecognizer3.pm";
require "BigramRecognizer.pm";
require "TrigramRecognizer3.pm";
require "QuadgramRecognizer.pm";

$|=1;

$fastrecognizer = Recognizer->new();
$bigramrecognizer = BigramRecognizer->new();
$trigramrecognizer = TrigramRecognizer->new();
$quadgramrecognizer = QuadgramRecognizer->new();

$fastrecognizer->{'countrydirectory'}=$ENV{'DICTIONARY_DIRECTORY'}.'/smallfive';
$bigramrecognizer->{'countrydirectory'}=$ENV{'DICTIONARY_DIRECTORY'}.'/smallfive';
$trigramrecognizer->{'countrydirectory'}=$ENV{'DICTIONARY_DIRECTORY'}.'/altavistaiso';
$quadgramrecognizer->{'countrydirectory'}=$ENV{'DICTIONARY_DIRECTORY'}.'/smallfive';

$trigramrecognizer->{'debug'}=1;
$fastrecognizer->buildCache();
$bigramrecognizer->buildCache();
$trigramrecognizer->buildCache();
$quadgramrecognizer->buildCache();

print STDERR "Input:";
while( $line = <STDIN> )
{
	chop;
	$line =~ tr/A-Z/a-z/;
	$line =~ s/[\r\n]*//g;
	@words = split(/ /,$line);
	
	%sorted = $fastrecognizer->recognizeSentence(@words);
	foreach $key (sort {$sorted{$a} <=> $sorted{$b}} (keys %sorted))
	{
		printf "Fastrecoginzer %s  %2.2f%%\n",$key,$sorted{$key};
	}
	
	%sorted = $bigramrecognizer->recognizeSentence(@words);
	foreach $key (sort {$sorted{$a} <=> $sorted{$b}} (keys %sorted))
	{
		printf "Bigramrecognizer %s  %2.2f%%\n",$key,$sorted{$key};
	}
	
	%sorted = $trigramrecognizer->recognizeSentence(@words);
	foreach $key (sort {$sorted{$a} <=> $sorted{$b}} (keys %sorted))
	{
		printf "Trigramrecognizer %s  %2.2f%%\n",$key,$sorted{$key};
	}
	
	%sorted = $quadgramrecognizer->recognizeSentence(@words);
	foreach $key (sort {$sorted{$a} <=> $sorted{$b}} (keys %sorted))
	{
		printf "Quadgramrecognizer %s  %2.2f%%\n",$key,$sorted{$key};
	}
	print "Input:";
}


