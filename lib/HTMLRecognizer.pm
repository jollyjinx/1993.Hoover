#!/usr/bin/perl


require "myEntityConverter.perl";

sub htmlToSentences
{	
	local($contents)=@_;
	local(@sentences);
	undef @sentences;
	
	$_=$contents;

	# remove special tags

	s{<!-- (.*?) -->}{ HTMLCOMMAND }gsix;						# remove metadata
	s{<ADDRESS (.*?) /ADDRESS>}{ HTMLCOMMAND }gsix;				# remove addresses
	s{<SCRIPT (.*?) /SCRIPT>}{ HTMLCOMMAND }gsix;				# remove scripts
	s{<PRE (.*?) /PRE>}{ $mom=$1;$mom=~s/\n/<br>/g;$mom}gsiex;	# split preformated lines into lines 
	s{<IMG\s[^>]*ALT="([^"]+)[^>]*> }{$1}gix; 					# '<IMG="fasel.gif" ALT="Katzenbild">' becomes 'Katzenbild'

	s{ \-<br> }{}gix;											# 'Bundes-<br>regierung' becomes 'Bundesregierung'
	s/<br>/HTMLCOMMAND/gsix;									# every other brake is a space									

	s{ <\/? (A|I|B|U|STRIKE|BIG|SMALL|SUB|SUP|EM|STRONG|FONT) [^>]* >}{}gsix;
	s{ < [^>]* > }{ HTMLCOMMAND }gsx;							# remove every other command and let paragraphes be there


	&decode_entities($_);
	s/[!\?]+/ . /g;												# exclamation and question marks now fullstops
	s/[\;\,]+/ /g;												# semicoli,kommata now spaces
	&encode_entities($_);
	s/&#?[0-9 ]*;/ /g;					 						# remove every special html character
	s/[^0-9a-zA-Z&;!?.@-]+/ /g;									# remove unneeded characters
	s/(-)+/-/g;													# '--- this ---' becomes '- this -'
	s/\d\.\s/ /g;												# '1. Januar'  becomes 'Januar'
	s/\s-/ /g;													# 'fasel -bla' becomes 'fasel bla'
	s/-\s/ /g;													# 'fasel - bla' becomes 'fasel- bla'  gets 'fasel bla'
	
																# now we have paragraphs 
	s/\.\s/HTMLCOMMAND/g;										# split in sentences
	s/\s+/ /g;
	s{(HTMLCOMMAND\s*)+}{HTMLCOMMAND}gx;
	
	@sentences = split('HTMLCOMMAND',$_);
	
	print "Sentences :\n".join("\n#####SENTENCE\n", @sentences)."\n" if $debug{'sentences'};
	return @sentences;
}




sub htmlToURLContents
{
	local($contents,*mylinkContents)=@_;
	local($link);

	$_=$contents;
	s/[\r\n\s]+/ /g;
	s{ \-<br> }{}gix;											# 'Bundes-<br>regierung' becomes 'Bundesregierung'
	s/<br>/ /gix;									
	s{ <\/? (I|B|U|STRIKE|BIG|SMALL|SUB|SUP|EM|STRONG|FONT) [^>]* >}{}gix;
	s{<IMG\s[^>]*ALT="([^"]+)[^>]*>}{$1}gix; 					# '<IMG="fasel.gif" ALT="Katzenbild">' becomes 'Katzenbild'
	s{<A\s[^>]*HREF="([^"]+)[^>]*>(.*?)</A>}
	{
		$link=$1;
		$content=$2;
		$content=~ s{<[^>]>}{}gx;
		$content= &decode_entities($content);
		$content= &encode_entities($content);
		$content=~ s/&#?[0-9 ]*;/ /g;					 		# remove unknown html character
		$content=~ s/(-)+/-/g;									# '--- this ---' gets '- this -'
		$content=~ s/([0-9])\./$1/;								# '1. Januar'  gets '1 Januar'
		$content=~ s/\s-/ /g;									# 'fasel -bla' gets 'fasel bla'
		$content=~ s/-\s/ /g;									# 'fasel - bla' and 'fasel- bla'  gets 'fasel bla'
		$content=~ s/[^0-9a-zA-Z&;!?.@-]+/ /g;					# remove unneeded characters

		if($link && $content)
		{
			$mylinkContents{$link}=$content;
		}  
	}giesx;

	return;
}


sub generalizeURLs
{	
	local(@urls)=@_;
	local(@newurls);
	undef @newurls;
		
	while( $_ = pop(@urls) )
	{
		if(/^http:\/\/([^:\/]*)(.*)/ )
		{
			$server = $1;
			$server =~ s/\.$//;
			$server =~ tr/A-Z/a-z/;
			push(@newurls,$server.$2);
		}
	}
	return @newurls;
}


sub sentenceToWords
{
	local($sentence)=@_;
	local(@words);
	local %wordcounter;
	local $momword;
	
	@words=grep(/^([A-Za-z0-9-]|\&[ABCabc]{1}\d{2}\;){$commandline{'minword'},$commandline{'maxword'}}$/, (split(/ /,$sentence)) );
	
	foreach $momword (@words)
	{
		$wordcounter{$momword}++;
		return if $wordcounter{$momword} > $commandline{'maxequalwordspersentence'};
	}
	
	return @words;
}

sub sentenceToBigrams
{
	local($sentence)=@_;
	local(@words,$word,@bigrams);
	undef @words;
	undef $word;
	undef @bigrams;
	
	@words = &sentenceToWords($sentence);
	while( $word = shift(@words) )
	{
		push(@bigrams,$word.'|'.$words[0]) if $words[0];
	}
	return @bigrams;
}

sub sentenceToTrigrams
{
	local($sentence)=@_;
	local(@words,$word,$letter,@letters,@trigrams);
	undef @words;
	undef $word;
	undef @letters;
	undef $letter;
	undef @trigrams;
	
	@words = &sentenceToWords($sentence);
	while( $word = pop(@words) )
	{
		@letters = split('',$word);
		while( $letter = shift(@letters) )
		{
			push(@trigrams,$letter.$letters[0].$letters[1]) if $letters[1];
		}
	}
	return @trigrams;
}


1;
