
package Recognizer;

sub version		{return '1';}
sub revision	{return '01';}
sub author		{return 'Patrick Stein <jolly@cis.uni-muenchen.de>'};
sub date		{return 'Sun Dec  1 11:05:00 MET 1996'};

sub new
{
	my $self = bless {};
	$self->{'countrydirectory'} = $ENV{'DICTIONARY_DIRECTORY'}.'/bla';
	return $self;
}

sub buildCache
{
	my ($self) =@_;
	my %cache;
	my @countryfiles;
	
	if( opendir(COUNTRYDIR, $self->{'countrydirectory'}) )
	{
		@countryfiles = grep(!/zipfkurve/,(grep(/^[a-zA-Z0-9].*$/,readdir(COUNTRYDIR))));
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
					printf STDERR "$country SUM:%5.4e FAC:%5.4e\n",$wordsum,($2/$3)	if $self->{'debug'};
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
	
	while( $word = shift(@words) )
	{
		my %wordfactor = ();
		my $wordsum = 0;
		foreach $country ( @countryfiles )
		{
			if( $cache{$country}{$word} )
			{
				$factor = $cache{$country}{$word};
				$wordsum += $factor;
				$wordfactor{$country} = $factor;

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
		$foundwords{$country}= (int(($count*10000)/$allpercent))/100;
	}
	
	return %foundwords;
}


1;
