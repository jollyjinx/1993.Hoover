
package TrigramRecognizer;

sub version		{return '3';}
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
					@trigrams = $self -> specialTrigramsFromWord($word);
					
					$standalonecache{$country}{$word} = $factor;
					if( 0 < $#trigrams )
					{
						$prefixcache{$country}{$trigrams[0]} += $factor;
						$postfixcache{$country}{$trigrams[$#trigrams]} += $factor;
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

	$self->{'standalonecache'}=\%standalonecache;
	$self->{'prefixcache'}=\%prefixcache;
	$self->{'postfixcache'}=\%postfixcache;
	$self->{'countryfiles'}=\@countryfiles;
	return $self;
}


sub recognizeSentence
{
	my ($self,@words) = @_;
	my %foundtrigrams = ();
	my %sorted = ();
	my @countryfiles = @{$self->{'countryfiles'}};
	my %standalonecache = %{$self->{'standalonecache'}};
	my %prefixcache = %{$self->{'prefixcache'}};
	my %postfixcache = %{$self->{'postfixcache'}};
	
	my $allpercenttrigrams = 0;
	my $word;
	
	my %trigramcount = ();
	my $trigramcount = 0;
	
	while( $word = shift(@words) )
	{
		my %trigramfactor = ();
		my $trigramfactorsum = 0;
	
		@trigrams = $self -> specialTrigramsFromWord($word);
		
		$trigramcount+=2;
		$wordisknown = 0;
		foreach $country ( @countryfiles )
		{
			if( $factor = $standalonecache{$country}{$word} )
			{
				$wordisknown = 0;
				$trigramfactorsum += $factor;
				$trigramfactor{$country} += $factor;
				$trigramcount{$country}+=2;
				printf STDERR "Standalone $country $word\n" if $self->{'debug'};
			}
		}

		if( !$wordisknown && (0 < $#trigrams) )
		{
			$trigramcount+=2;
			foreach $country ( @countryfiles )
			{
				if( $factor = $prefixcache{$country}{$trigrams[0]} )
				{
					$trigramfactorsum = +$factor;
					$trigramfactor{$country} += $factor;
					$trigramcount{$country}++;
					printf STDERR "Prefix $country $trigrams[0] from front\n" if $self->{'debug'};
				}			
				if( $factor = $postfixcache{$country}{$trigrams[$#trigrams]} )
				{
					$trigramfactorsum = +$factor;
					$trigramfactor{$country} += $factor;
					$trigramcount{$country}++;
					printf STDERR "Postfix $country $trigrams[$#trigrams] from tail\n" if $self->{'debug'};
				}			
			}
		}
		foreach $country (keys %trigramfactor)
		{
			$foundtrigrams{$country} += ($trigramfactor{$country}/$trigramfactorsum);
		}		
	}
	
	$allpercenttrigrams = 0;
	foreach $country (keys %foundtrigrams)
	{
		$allpercenttrigrams += $foundtrigrams{$country};   # *($trigramcount{$country}/$trigramcount);
	}
	while( ($country,$count)=each(%foundtrigrams) )
	{
		$foundtrigrams{$country}= ($trigramcount{$country}/$trigramcount) *(int(($count*10000)/$allpercenttrigrams))/100;
	}
	
	return %foundtrigrams;
}


sub specialTrigramsFromWord
{
	my ($self,$word) = @_;
	my @trigrams;
	
	if( 3 == length($word) )
	{
		@trigrams = ( $word );
	}
	else
	{	
		if( length($word) >3 )
		{
			my @letters = split(//,$word);
			@trigrams = ( $letters[0].$letters[1].$letters[2] , $letters[$#word-2].$letters[$#word-1].$letters[$#word] );
		}
	}
	return @trigrams;
}	

1;
