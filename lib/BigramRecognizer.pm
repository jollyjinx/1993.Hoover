
package BigramRecognizer;

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
	my %bigramcache;
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
					@bigrams = $self -> bigramsFromWord($word);
					printf STDERR "WORD $word bigramS @bigrams\n" if $self->{'debug'} > 1;
					while( $bigram = shift(@bigrams) )
					{
						$bigramcache{$country}{$bigram} += $factor;
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

	$self->{'internalbigramcache'}=\%bigramcache;
	$self->{'countryfiles'}=\@countryfiles;
	return $self;
}


sub recognizeSentence
{
	my ($self,@words) = @_;
	my %foundbigrams = ();
	my %sorted = ();
	my @countryfiles = @{$self->{'countryfiles'}};
	my %bigramcache = %{$self->{'internalbigramcache'}};
	my $allpercentbigrams = 0;
	my $word;
	

	while( $word = shift(@words) )
	{
		@bigrams = $self -> bigramsFromWord($word);
		while( $bigram = shift(@bigrams) )
		{
			my %bigramfactor = ();
			my $bigramsum = 0;
			
			foreach $country ( @countryfiles )
			{
				if( $factor = $bigramcache{$country}{$bigram} )
				{
					$bigramsum += $factor;
					$bigramfactor{$country} = $factor;
	
					printf STDERR "$country SUM:%5.4e FAC:%5.4e\n", $bigramsum,$factor	if $self->{'debug'};
				}			
			}
			
			foreach $country (keys %bigramfactor)
			{
				$foundbigrams{$country} += ($bigramfactor{$country}/$bigramsum) ;
				printf STDERR "COUNTRY:%s %5.4f %5.4f %5.4f\n",$country, $bigramsum,$percentthistime, $foundbigrams{$country} if $self->{'debug'};
			}		
		}
	}
	
	$allpercentbigrams = 0;
	foreach $country (keys %foundbigrams)
	{
		$allpercentbigrams += $foundbigrams{$country};
	}
	while( ($country,$count)=each(%foundbigrams) )
	{
		$foundbigrams{$country}= (int(($count*10000)/$allpercentbigrams))/100;
	}
	
	return %foundbigrams;
}


sub bigramsFromWord
{
	my ($self,$word) = @_;
	my @letters = split(//,$word);
	my @bigrams;
	
	while( $#letters > 0 )
	{
		push(@bigrams,$letters[0].$letters[1]);
		shift @letters;
	}
	return @bigrams;
}	

1;
