
package Recognizer;

sub version		{return '1';}
sub revision	{return '01';}
sub author		{return 'Patrick Stein <jolly@cis.uni-muenchen.de>'};
sub date		{return 'Sun Dec  1 11:05:00 MET 1996'};

sub new
{
	my $self = bless {};
	
	$self->{'countrydirectory'} = '/usr/import/watzmann_data/Watzmann_data/jolly/sprachen';
	$self->{'countryfileextension'} = 'frequency';	
	my @countryfiles = ('cz','de','dk','ee','en','es','fi','fr','gr','hk','hu','is','it','nl','no','pl','pt','se','sk','tr' );

	$self->{'countryfiles'} = \@countryfiles;
	return $self;
}

sub recognizeSentence
{
	my ($self,@words) = @_;										# @words contains all words in the sentence
	my %foundwords = ();										# %foundwords 
	my %sorted = ();
	my @countryfiles = @{$self->{'countryfiles'}};				# @countryfiles is an array that contains the filenames of the 
																# dictionarys ( frequency lists )
	my $allpercent = 0;											# sum of all percentages of all words 
	my $word;													# $word contains the word that get's computed right now
	
	while( $word = shift(@words) )								# iterate over all words in the sentence
	{
		my %wordfactor = ();									# %wordfactor{$country} contains the frequency of the word in a country
		my $wordsum = 0;										# $wordsum : sum of frequencies for the word
		foreach $country ( @countryfiles )						# iterate over all countries
		{														
			if( defined($cache{$country}{$word}) )				# we cache frequencys so first lookup a frequency if it's in the cache
			{
						$factor = $cache{$country}{$word};
						$wordsum += $factor;
						$wordfactor{$country} = $factor;			
			}
			else												# else look it up in the frequencylist in that country
			{													# the lookup is done by the unixprogram 'look' which
																# which uses a binary search on a dictionary file
																# to lookup a word ( pretty fast )
				$languagefilename = sprintf "%s/%s.%s",$self->{'countrydirectory'},$country,$self->{'countryfileextension'};
				if( open(COUNTRYFILE,"look \'$word\:\' $languagefilename |") )		
				{
					print STDERR "Reading $languagefilename\n" if $self->{'debug'};
					while( $_ = <COUNTRYFILE> )
					{
						if( /^$word:(\d+)\/(\d+)$/)				# since 'look' reports all occurences of a word we have to
						{										# use a regular expression to get the right line of the 'look' output
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
		
		foreach $country (keys %wordfactor)						# calculate the percentage a word belongs to a country in respect
		{														# of the relativity the word is spoken i a specific country
			$foundwords{$country} += ($wordfactor{$country}/$wordsum) ;
			printf STDERR "COUNTRY:%s %5.4f %5.4f %5.4f\n",$country,$wordsum,$percentthistime, $foundwords{$country} if $self->{'debug'};
		}		
	}
		
	$allpercent = 0;											# add up all percentages of the countries and
	foreach $country (keys %foundwords )
	{
		$allpercent += $foundwords{$country};
	}

	while( ($country,$count)=each(%foundwords) )				# relative to the result return all percentages of countries.
	{
		$foundwords{$country}= (int(($count*10000)/$allpercent))/100;
	}
	
	return %foundwords;
}


1;
