

while(<>)
{
	chop;
	@words = split(/ /);
	while( $word = shift(@words) )
	{
		if(length($word))
		{
			@trigrams = &trigramsfromword($word);
			
			$positionfromfront= 1;
			$positionfromtail = -($#trigrams+1);
	
			while( $trigram = shift(@trigrams) )
			{
				 $trigramcount{$trigram} ++;
				# $trigramcache{$trigram}{$positionfromfront} ++;
				# $trigramcache{$trigram}{$positionfromtail} ++;
				# $positionfromfront ++;
				# $positionfromtail ++
			}
		}
	}
}


while( ($trigram,$count)=each(%trigramcount) )
{
	print STDOUT $count.' '.$trigram."\n";
}
exit;
while( ($trigram,$pos)=each(%trigramcache) )
{
	@positions = keys(%{$pos});
	$count = 0;
	while( $position = shift(@positions) )
	{
		print STDOUT $trigramcache{$trigram}{$position}.' '.$position.' '.$trigram."\n";
		$count += $trigramcache{$trigram}{$position};
	}
}
exit;


sub trigramsfromword
{
	my ($word) = @_;
	my @letters = split(//,$word);
	my @trigrams;
	
	while( $#letters > 1 )
	{
		push(@trigrams,$letters[0].$letters[1].$letters[2]);
		shift @letters;
	}
	return @trigrams;
}	
