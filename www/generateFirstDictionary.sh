#!/bin/zsh
for lang in $*
do
	perl5 ~/Diplom/www/hoovertotext.perl $lang |								\
	tr A-Z a-z |																\
	perl5 ~/Diplom/converter/mycoding2iso.perl >$lang.sen
	~/Diplom/www/generateFrequencylistsFromSentences.sh $lang.sen
	perl5 ~/Diplom/www/compareCleanWithWebDictionary.perl 						\
			~/LocalNetwork/warlock/dictionaries/perfect/english.latin1			\
			$lang.sen.frequency 1 >$lang.noeng
	perl5 ~/Diplom/www/compareCleanWithWebDictionary.perl 						\
			~/LocalNetwork/warlock/dictionaries/perfect/Webwords				\
			$lang.noeng 1 >$lang.noeng.noweb

done