
package Recognizer;

sub version		{return '2';}
sub revision	{return '01';}
sub author		{return 'Patrick Stein <jolly@cis.uni-muenchen.de>'};
sub date		{return 'Sat Feb  1 16:57:31 MET 1997'};

sub new
{
	my $self = bless {};
	$self->{'countrydirectory'} = $ENV{'DICTIONARY_DIRECTORY'}.'dictionary';
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


sub recognizeSentence
{
	my ($self,@words) = @_;
	my %foundwords = ();
	my %sorted = ();
	my @countryfiles;
	my $allpercent = 0;
	my $word;
	
	if( opendir(COUNTRYDIR, $self->{'countrydirectory'}) )
	{
		@countryfiles = grep(/^[a-zA-Z0-9].*$/,readdir(COUNTRYDIR));
		closedir(COUNTRYDIR);
	}
	else
	{
		print STDERR 'Error reading '.$self->{'countrydirectory'}."\n";
		return;
	}

	while( $word = shift(@words) )
	{
		my %wordfactor = ();
		my $wordsum = 0;
		foreach $country ( @countryfiles )
		{
			if( defined($cache{$country}{$word}) )
			{
						$factor = $cache{$country}{$word};
						$wordsum += $factor;
						$wordfactor{$country} = $factor;			
			}
			else
			{
				$languagefilename = sprintf "%s/%s",$self->{'countrydirectory'},$country;
				if( open(COUNTRYFILE,"look \'$word\:\' $languagefilename |") )
				{
					print STDERR "Reading $languagefilename\n" if $self->{'debug'};
					while( $_ = <COUNTRYFILE> )
					{
						if( /^$word:(\d+)\/(\d+)$/)
						{
							$factor = ($1/$2);
							$wordsum += $factor;
							$wordfactor{$country} = $factor;
							$cache{$country}{$word}=$factor  if $self->{'cache'}==1;
							printf STDERR "$country SUM:%5.4e FAC:%5.4e\n",$wordsum,$factor	if $self->{'debug'};
						}
					}
					close(COUNTRYFILE);
				}
				else
				{
					print STDERR "Can't open $languagefilename\n";
				}
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
