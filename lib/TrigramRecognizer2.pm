
package TrigramRecognizer;

sub version		{return '1';}
sub revision	{return '01';}
sub author		{return 'Patrick Stein <jolly@cis.uni-muenchen.de>'};
sub date		{return 'Tue Apr  1 13:37:50 MET DST 1997'};

sub new
{
	my $self = bless {};
	$self->{'countrydirectory'} = $ENV{'DICTIONARY_DIRECTORY'}.'/bigfive';
	return $self;
}

sub dictionaryInfo
{
	my ($self) = @_;
	my $info;
	
	if( open(INFOFILE, $self->{'countrydirectory'}.'/.dictionaryinfo') )
	{
		while(<INFOFILE>)
		{
			$info .= $_.'<br>';
		}
		close(INFOFILE);
	}
	return $info;
}


sub buildCache
{
	my ($self) =@_;
	my %trigramcache;
	my @countryfiles;
	
	if( opendir(COUNTRYDIR, $self->{'countrydirectory'}) )
	{
		@countryfiles = grep(/^[a-zA-Z0-9].*$/,readdir(COUNTRYDIR));
		closedir(COUNTRYDIR);
	}
	else
	{
		print STDERR 'Error reading '.$self->{'countrydirectory'}."\n";
		return 0;
	}
	
	foreach $country ( @countryfiles )
	{
		$languagefilename = sprintf "%s/%s",$self->{'countrydirectory'},$country;
		if( open(COUNTRYFILE,$languagefilename) )
		{
			while( $_ = <COUNTRYFILE> )
			{
				if( /^(.*):(\d+)\/(\d+)$/)
				{
					$word = $1;
					$count = $2;
					$allcount = $3;
					$factor = $count / $allcount;
					@trigrams = $self -> trigramsFromWord($word);
					printf STDERR "WORD $word TRIGRAMS @trigrams\n" if $self->{'debug'} > 1;

					$positionfromfront= 1;
					$positionfromtail = -($#trigrams+1);

					while( $trigram = shift(@trigrams) )
					{
						$trigramcache{$country}{$trigram}{$positionfromfront} += $factor;
						$trigramcache{$country}{$trigram}{$positionfromtail} += $factor;
						# print STDERR "TRIGRAM from word $word from front:$positionfromfront = $trigram\n";
						# print STDERR "TRIGRAM from word $word from tail:$positionfromtail = $trigram\n";
						$positionfromfront ++;
						$positionfromtail ++
					}
				}
			}
			close(COUNTRYFILE);
		}
		else
		{
				print STDERR "Can't open $languagefilename\n";
		}
	}

	$self->{'internaltrigramcache'}=\%trigramcache;
	$self->{'countryfiles'}=\@countryfiles;
	return $self;
}


sub recognizeSentence
{
	my ($self,@words) = @_;
	my %foundtrigrams = ();
	my %sorted = ();
	my @countryfiles = @{$self->{'countryfiles'}};
	my %trigramcache = %{$self->{'internaltrigramcache'}};
	my $allpercenttrigrams = 0;
	my $word;
	
	my %trigramcountrycount = ();
	my $trigramcountrymaxcount = 0;
	
	while( $word = shift(@words) )
	{
		@trigrams = $self -> trigramsFromWord($word);
		$positionfromfront = 1;
		$positionfromtail = -( $#trigrams+1);
		
		while( $trigram = shift(@trigrams) )
		{
			my %trigramfactor = ();
			my $trigramsum = 0;
			
			$trigramcountrymaxcount++;
			$trigramcountrymaxcount++;		# von vorne und von hinten
			
			foreach $country ( @countryfiles )
			{
				if( $factor = $trigramcache{$country}{$trigram}{$positionfromfront} )
				{
					$trigramsum += $factor;
					$trigramfactor{$country} = $factor;
					$trigramcountrycount{$country}++;
					printf STDERR "Trigram $country $trigram from front:$positionfromfront\n" if $self->{'debug'};
				}			
				if( $factor = $trigramcache{$country}{$trigram}{$positionfromtail} )
				{
					$trigramsum += $factor;
					$trigramfactor{$country} = $factor;
					$trigramcountrycount{$country}++;
					printf STDERR "Trigram $country $trigram from tail:$positionfromtail\n" if $self->{'debug'};
				}			
			}
			
			foreach $country (keys %trigramfactor)
			{
				$foundtrigrams{$country} += ($trigramfactor{$country}/$trigramsum) ;
				printf STDERR "COUNTRY:%s %5.4f %5.4f %5.4f\n",$country, $trigramsum,$percentthistime, $foundtrigrams{$country} if $self->{'debug'};
			}		
			$positionfromfront ++;
			$positionfromtail ++
		}
	}
	
	$allpercenttrigrams = 0;
	foreach $country (keys %foundtrigrams)
	{
		$allpercenttrigrams += $foundtrigrams{$country};
#		printf STDERR "TRIGRAM: %s %5.2f%%\n",$country,$trigramcountrycount{$country}/$trigramcountrymaxcount;
		
	}
	while( ($country,$count)=each(%foundtrigrams) )
	{
#		$foundtrigrams{$country}= (int(($count*10000)/$allpercenttrigrams))/100;
		$foundtrigrams{$country}= ($trigramcountrycount{$country}/$trigramcountrymaxcount)*(int(($count*10000)/$allpercenttrigrams))/100;
	}
	
	return %foundtrigrams;
}


sub trigramsFromWord
{
	my ($self,$word) = @_;
	my @letters = split(//,$word);
	my @trigrams;
	
	while( $#letters > 1 )
	{
		push(@trigrams,$letters[0].$letters[1].$letters[2]);
		shift @letters;
	}
	return @trigrams;
}	

1;
