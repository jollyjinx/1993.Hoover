#!/bin/zsh
for i in $*
do
		echo "Generating frequency list for :$i"
		perl -ne '	
					s/^[A-Za-z0-9\.]+:[0-9\.]+:[A-Za-z0-9\.]*:[0-9\.]+:/SEN:/;
					
					if( /^SEN:(.*)/i )		
					{						
						$_=$1;				
						s/:/ /g;				
						print $_."\n";		
					}				
				'	<$i |
					frequency |
				perl -ne '
						if( /^.*:(\d+)\/\d+$/ )
						{
							print $_ if $1 > 1;
						}
						' | sort >$i.frequency				
done


exit



perl5 ~/Diplom/www/removeEnglishFromDictionaries.perl *.frequency

for i in *.noenglish
do
	nname=`echo $i |sed -e 's/noenglish/10000/'`
	echo $nname
	sort -t : +1 -rn <$i |head -10000 |sort >\!$nname
done
