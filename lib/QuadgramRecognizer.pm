
package QuadgramRecognizer;

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
	my %quadgramcache;
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
					@quadgrams = $self -> quadgramsFromWord($word);
					printf STDERR "WORD $word quadgramS @quadgrams\n" if $self->{'debug'} > 1;
					while( $quadgram = shift(@quadgrams) )
					{
						$quadgramcache{$country}{$quadgram} += $factor;
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

	$self->{'internalquadgramcache'}=\%quadgramcache;
	$self->{'countryfiles'}=\@countryfiles;
	return $self;
}


sub recognizeSentence
{
	my ($self,@words) = @_;
	my %foundquadgrams = ();
	my %sorted = ();
	my @countryfiles = @{$self->{'countryfiles'}};
	my %quadgramcache = %{$self->{'internalquadgramcache'}};
	my $allpercentquadgrams = 0;
	my $word;
	

	while( $word = shift(@words) )
	{
		@quadgrams = $self -> quadgramsFromWord($word);
		while( $quadgram = shift(@quadgrams) )
		{
			my %quadgramfactor = ();
			my $quadgramsum = 0;
			
			foreach $country ( @countryfiles )
			{
				if( $factor = $quadgramcache{$country}{$quadgram} )
				{
					$quadgramsum += $factor;
					$quadgramfactor{$country} = $factor;
	
					printf STDERR "$country SUM:%5.4e FAC:%5.4e\n", $quadgramsum,$factor	if $self->{'debug'};
				}			
			}
			
			foreach $country (keys %quadgramfactor)
			{
				$foundquadgrams{$country} += ($quadgramfactor{$country}/$quadgramsum) ;
				printf STDERR "COUNTRY:%s %5.4f %5.4f %5.4f\n",$country, $quadgramsum,$percentthistime, $foundquadgrams{$country} if $self->{'debug'};
			}		
		}
	}
	
	$allpercentquadgrams = 0;
	foreach $country (keys %foundquadgrams)
	{
		$allpercentquadgrams += $foundquadgrams{$country};
	}
	while( ($country,$count)=each(%foundquadgrams) )
	{
		$foundquadgrams{$country}= (int(($count*10000)/$allpercentquadgrams))/100;
	}
	
	return %foundquadgrams;
}


sub quadgramsFromWord
{
	my ($self,$word) = @_;
	my @letters = split(//,$word);
	my @quadgrams;
	
	while( $#letters > 2 )
	{
		push(@quadgrams,$letters[0].$letters[1],$letters[2].$letters[3]);
		shift @letters;
	}
	return @quadgrams;
}	

1;
