#
#
#
#perl5 ~/Perl/www2/lookupLanguageDatabase.perl trigrams | perl5 -n -e 'if( /^(\d+)([a-z]+)(\d+)\s+(.*)$/ && $1 eq $3 && $1>5 ){print $2." ".$4."\n";}'

$filename = shift(@ARGV);

open(WORDFILE,"<$filename") || "Can't open $filename [$!]\n";
while( $_ = <WORDFILE> )
{
	$globalword{$2}=$1 if /^([a-z0-9]+)\s+(.*)$/;
}
close(WORDFILE);

$|=1;
print STDERR "Done reading database\n";

while( $line = <STDIN> )
{
	chop($line);
	$wordcount = 0;
	%foundcountries = ();
	
	@words = split(/ /,$line);
	$wordsinsentence = $#words+1;
	while( $word = shift(@words) )
	{
		$countries = $globalword{$word};
		printf STDERR "%15s $countries\n",$word;
		
		$wordsum=0;
		%wordvalue=();
		while($countries)
		{
			$_=$countries;
			/^(\d+)([a-z]+)(.*)$/;
			$count   = $1;
			$country = $2;
			$countries=$3;
			
			$wordsum+=$count;
			$wordvalue{$country}=$count;
		}
		
		while( ($country,$count)=each(%wordvalue) )
		{
			$foundcountries{$country}+= ($count/$wordsum)/$wordsinsentence;
		}
	}
	
	while( ($country,$count)=each(%foundcountries) )
	{
		printf STDOUT "$country %2.2f %%\n",$count*100;
	}
	
	
	
}


