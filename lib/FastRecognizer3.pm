
package Recognizer;

sub version		{return '2';}
sub revision	{return '01';}
sub author		{return 'Patrick Stein <jolly@cis.uni-muenchen.de>'};
sub date		{return 'Fri Feb  7 12:53:12 MET 1997'};

sub new
{
	my $self = bless {};
	$self->{'countrydirectory'} = $ENV{'DICTIONARY_DIRECTORY'}.'/dictionary';
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
	my %cache;
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
					$cache{$country}{$1}=($2/$3);
					printf STDERR "$country $1 SUM:%5.4e FAC:%5.4e\n",$wordsum,($2/$3)	if $self->{'debug'};
				}
			}
			close(COUNTRYFILE);
		}
		else
		{
				print STDERR "Can't open $languagefilename\n";
		}
	}

	$self->{'internalcache'}=\%cache;
	$self->{'countryfiles'}=\@countryfiles;
	return $self;
}


sub recognizeSentence
{
	my ($self,@words) = @_;
	my %foundwords = ();
	my %sorted = ();
	my @countryfiles = @{$self->{'countryfiles'}};
	my %cache = %{$self->{'internalcache'}};
	my $allpercent = 0;
	my $word;
	my %wordcountrycount = ();
	my $wordcountrymaxcount = 0;
	
	while( $word = shift(@words) )
	{
		my %wordfactor = ();
		my $wordsum = 0;

		$wordcountrymaxcount++;
		foreach $country ( @countryfiles )
		{
			if( $cache{$country}{$word} )
			{
				$factor = $cache{$country}{$word};
				$wordsum += $factor;
				$wordfactor{$country} = $factor;
				$wordcountrycount{$country}++;

				printf STDERR "$country SUM:%5.4e FAC:%5.4e\n",$wordsum,$factor	if $self->{'debug'};
			}
		}
		
		foreach $country (keys %wordfactor)
		{
			$foundwords{$country} += ($wordfactor{$country}/$wordsum) ;
			printf STDERR "COUNTRY:%s %5.4f %5.4f %5.4f\n",$country,$wordsum,$percentthistime, $foundwords{$country} if $self->{'debug'};
		}		
	}
		
	$allpercent = 0;
	foreach $country (keys %foundwords )
	{
		$allpercent += $foundwords{$country};
	}

	while( ($country,$count)=each(%foundwords) )
	{
		$foundwords{$country}= ($wordcountrycount{$country}/$wordcountrymaxcount)*(int(($count*10000)/$allpercent))/100;
	}
	
	return %foundwords;
}


1;
