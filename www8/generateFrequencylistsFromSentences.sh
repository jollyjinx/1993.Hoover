#!/bin/zsh
for i in $*
do
	filesize=`wc -l $i | sed -e 's/^[^0-9]*\([0-9]*\)[^0-9]*$/\1/g'` 
	if [[ $filesize -lt 10000 ]]
	then
		echo "File to small"
	else
		echo "Generating frequency list for :$i"
		perl -ne '	while(<>)					
					{							
						if( /^SEN:(.*)/ )		
						{						
							$_=$1;				
							tr/A-Z/a-z/;
							s/:/ /g;				
							print $_."\n";		
						}				
					}'	<$i |
					~/Binaries/osf4.0/frequency |
				perl -ne 'while( <STDIN> )
					{
						if( /^.*:(\d+)\/\d+$/ )
						{
							print $_ if $1 > 5;
						}
					}' | sort >$i.frequency				
	fi		
done

perl5 ~/Diplom/www/removeEnglishFromDictionaries.perl *.frequency

for i in *.noenglish
do
	nname=`echo $i |sed -e 's/noenglish/10000/'`
	echo $nname
	sort -t : +1 -rn <$i |head -10000 |sort >\!$nname
done
