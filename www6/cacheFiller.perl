#
#	title	:	wwwCacheFiller.perl						WWW proxycache fill
#	author	:	Patrick Stein <jolly@cis.uni-muenchen.de>
#	version	:	3.01
#	date	:	Thu Nov  7 15:58:24 MET 1996

require 5.002;

$retrytime=1000;								#	maximum time before retry to a refused page

$user_agent = "CIS WordSearcher 3.01";			#	name of this program to tell the httpd's
select(STDOUT);$|=1;							#	flush files immediate

@picturearray=(	'\.gif$','\.tif$', '\.jpg$','\.jpeg$', 
				'\.gz$',  '\.z$', '\.zip$',
				'\.ps$', '\.eps$', 
				'\.mov$','\.avi$','\.mpg$','\.mpeg$');
@neverfollowarray=('\/cgi-bin\/','\.map$','^mailto:','^gopher:','^ftp:');


if(!grep(/url/,@ARGV) && !grep(/default/,@ARGV) && !grep(/reuse/,@ARGV))
{
	print <<EOF;
NAME
    $0 - get all html pages beginning at a specific url.

SYNOPSIS
    $0 [ option ]... url=http...

OPTIONS :
    default
    database=[remove|reuse*]
                The links to follow are stored in a database. This database
                consists of three files:
                    'links.visited'     - Contains links that the program 
                                            already has followed.
                    'links.nextstage'   - Links that are new in this round are
                                            stored here. Those links will be 
                                            fetched in the next round.
                    'links.unknown'     - Links that get fetched in this round.
        
    languages=[none|examine*] 
                If set, the program will exmaine every html document depending 
                on one of the following algorithms.
    
        sentences=[none|examine*]
                If set, sentences of fetched url's are appended to the files 
                country/name. Name is the topmost internet domain of the fetched
                url. It then appends : URL:urlname
                                       SEN:word1:word2:...
                                       SEN:...                      to the file.
        
        wordsinsentence=<int>
                Only sentences with greater and equal number of words will be 
                appended to the sentencesfiles. Default is 5.
        
        minword=<int>
                Minimal length a word has to have. Default is 2.
        maxword=<int>
                Maximal length a word has to have. Default is ''(endless).
		languagemax=<int>
				Maximal size in megabytes of the language files. Default is 40     

    debug=[database]:[sentences]:[contents]:[linkarrays]
        
    follow/links=[option]:[option]:...
        with option: text        follow only .html and .htm documents
                     !pictures   never get picutres
                     [!]us       [never] get things from .edu .mil .com .net ...
                     [!]de       [never] get things from .de .leo.org ...
                     regex       enter regular expression like \.uk\/ to get 
                                 just links from the uk
    
    url={urlname}
                Begin the searchtree with the url named.
    maxdepth=<int>          
                Searchtree ends at depth. Default is 30.
    timeout=<int>           
                Maximum time in seconds to wait for an url to resolve. 
                Default is 1.


EXAMPLES
    
    perl5 wwwCacheFiller.pl url=http://www.next.com/ database=remove
    perl5 wwwCacheFiller.perl links=\\!us:\\!de:text

BUGS
    Needs GDBM_File command - so perl5.002 or higher is mandatory.

EOF
	exit(1);
}

$commandline{'database'}='reuse';

$commandline{'languages'}='examine';
$commandline{'sentences'}='examine';
$commandline{'contents'}='none';
$commandline{'wordspersentence'}=5;
$commandline{'minword'}=2;
$commandline{'maxword'}='';
$commandline{'languagemax'}=40;

$commandline{'url'}='http://www.w3.org/hypertext/DataSources/WWW/Servers.html';
$commandline{'maxdepth'}=30;
$commandline{'timeout'}=1;


while($_=pop(@ARGV))
{
	$_='links=!us:!de:!\.jp:!\.org:!\.uk:text'	if/^default$/;
	
	$commandline{'database'}=$1 		if /^database=(.*)/;

	$commandline{'languages'}=$1 		if /^languages=(.*)/;
	$commandline{'sentences'}=$1		if /^sentences=(.*)/;
	$commandline{'wordspersentence'}=$1	if /^wordspersentence=(\d+)/;
	$commandline{'minword'}=$1			if /^minword=(\d+)/;
	$commandline{'maxword'}=$1			if /^maxword=(\d+)/;
	$commandline{'languagemax'}=$1		if /^languagemax=(\d+)/;

	$commandline{'url'}=$1				if /^url=(.*)/;
	$commandline{'maxdepth'}=$1			if /^maxdepth=(\d+)/;
	$commandline{'timeout'}=$1			if /^timeout=(\d+)/;
	
	if(/debug=(.*)/)
	{
		@mom=split(/:/,$1);
		while($_=pop(@mom))
		{
			$debug{$_}=1;
		}
	}

	if(/^follow=(.*)/ || /^links=(.*)/)
	{
		@mom=split(/:/,$1);
		while($_=pop(@mom))
		{
			if(/^text$/)		{	$onlyfollow='@linksOK=grep(/\.html$/i,@links);'."\n".
												'push(@linksOK,grep(/\.htm$/i,@links));'."\n".
												'@links=@linksOK;'."\n";							next;}
			if(/^!pictures$/)	{	push(@neverfollowarray, @picturearray);							next;}
			if(/^de$/)			{	push(@onlyfollowarray, ('\.de[:\/]','\.leo\.org[:\/]',
															'\.ch[:\/]','\.at[:\/]'));				next;}
			if(/^!de$/)			{	push(@neverfollowarray, ('\.de[:\/]','\.leo\.org[:\/]',
															'\.ch[:\/]','\.at[:\/]'));				next;}
			if(/^us$/)			{	push(@onlyfollowarray, ('\.us[:\/]','\.ca[:\/]','\.edu[:\/]',
														'\.com[:\/]','\.mil[:\/]','\.net[:\/]',
														'\.gov[:\/]','\.au[:\/]'));					next;}
			if(/^!us$/)			{	push(@neverfollowarray, ('\.us[:\/]','\.ca[:\/]','\.edu[:\/]',
															'\.com[:\/]','\.mil[:\/]','\.net[:\/]',
															'\.gov[:\/]','\.au[:\/]'));				next;}
			if(/^!(.*)/)		{	push(@neverfollowarray,$1);										next;}
			push(@onlyfollowarray,$_);
		}
	}
}
$neverextract = '$url=0 if /'.join('/ || /', @picturearray).'/i;';
$neverfollow = '@links=grep(!/'.join('/i,@links);'."\n".'@links=grep(!/', @neverfollowarray).'/,@links);'."\n";
@onlyfollowarray=('^http:\/\/') if !@onlyfollowarray;
$onlyfollow .=	'@linksOK=();'."\n"
				.'push(@linksOK,grep(/'
				.join('/,@links));'."\n".'push(@linksOK,grep(/', @onlyfollowarray)
				.'/,@links));'."\n"
				.'@links=@linksOK;'."\n".'undef @linksOK;'."\n";

print	"Never Follow  :\n$neverfollow\n";
print	"Only Follow   :\n$onlyfollow\n";
print	"Database      :",$commandline{'database'},"\n";
print	"Languages     :",$commandline{'languages'},"\n";
print	"Sentences     :",$commandline{'sentences'},"\n";
print	"Words/sentence:",$commandline{'wordspersentence'},"\n";
print	"min. Word     :",$commandline{'minword'},"\n";
print	"max. Word     :",$commandline{'maxword'},"\n";
print	"max. Langfile :",$commandline{'languagemax'},"MByte\n";
print	"Begin         :",$commandline{'url'},"\n";
print	"Maxdepth      :",$commandline{'maxdepth'},"\n";
print	"Timeout       :",$commandline{'timeout'},"\n";


$SIG{'INT'}='signalhandler';
$SIG{'TERM'}='signalhandler';
$SIG{'ABRT'}='signalhandler';



if($commandline{'database'} eq 'remove')
{
	print "Removing link database:";
	`rm -f links.visited`;
	`rm -f links.unknown`;
	`rm -f links.nextstage`;
	print "done.\n";
}


if( ! -f 'links.unknown' )
{
	open(UNKNOWN,'>links.unknown');
	print UNKNOWN '0:0:'.$commandline{'url'}."\n";
	close(UNKNOWN);
}

require "entityConverter.perl";
require "wwwbot.pl";
require "wwwhtml.pl";



for(0..$commandline{'maxdepth'})
{	
	$actualdepth=$_;
	
	print "Entering Stage $actualdepth\n";
	
	if( open(VISITED,'<links.visited') )
	{
		while( $_ = <VISITED> )
		{
			chop;
			$visited{$_} = 1;
		}
		close(VISITED);
	}
	else
	{
		print STDERR "Can't open links.visited\n";
	}
	open(VISITED,'>>links.visited'); select(VISITED);$|=1;
	open(NEXTSTAGE,'>links.nextstage'); select(NEXTSTAGE);$|=1;
	open(UNKNOWN,'<links.unknown'); select(UNKNOWN);$|=1;
	
	
	select(STDOUT);$|=1;
	while( $_ = <UNKNOWN> )
	{
		if(/^(\d+):(\d+):(.*)$/)
		{
			$lasttimeTried = $1;
			$linkDepth = $2;
			$url = $3;
		}

		print "Got from database $url \n" if $debug{'database'};
		
		next if $visited{$url};
		next if $lasttimeTried gt time()-$retrytime;

		undef $headers;
		undef @headers;
		undef %headers;		
		undef $contents;
		undef @contents;
		undef %contents;
		undef @links;
		undef %links;
	
		$country = $url;
		$country =~ s/^http:\/\/([^\/:]+).*$/$1/;
		$country =~ s/.*\.([^\.]+)$/$1/;
		
		
		printf "%2d %65s",$linkDepth,$url;
		if( -f "countries/$country" && (@fasel=stat(_)) && ( $fasel[7]>($commandline{'languagemax'}*1000000) ))
		{
			print " File full\n";
			next;
		}
			$response=&www'request('GET',$url,*headers,*contents,$commandline{'timeout'});		
		print ' '.$httpResponse{$response}."\n";
	
		if($response eq 603 || $response eq 400)
		{
			print NEXTSTAGE time().':'.$linkDepth.':'.$url."\n";
			next;
		}
		
		print VISITED $url."\n";
		$visited{$url}=1;
		
		
		$_=$url;
		eval $neverextract;
		next if (!$url);

		if( ($response eq 200) && ($commandline{'languages'} ne 'none') )
		{
			if( ($commandline{'sentences'} ne 'none') && (@sentences = &htmlToSentences($contents)) )	
			{
				if(length($country)>1)
				{
					open(COUNTRY,">> countries/$country") || die "Can't open countries/$country:[$!]\n";
					print COUNTRY 'URL:'.$url."\n";
					if( @names=&htmlToContents($contents) )
					{
						print COUNTRY 'LIN:'.join("\nLIN:",@names)."\n";
					}
					while($sentence=shift(@sentences))
					{
						@words = &sentenceToWords($sentence);
						if($#words > $commandline{'wordspersentence'} )
						{
							print COUNTRY 'SEN:'.join(':',grep(!/^[0-9\-\;]+$/,@words))."\n";
						}
					}
					close(COUNTRY);
				}
			}	

		}
				
		undef @links;
		&wwwhtml'extract_links($url,*headers,*contents,*links,*labs,*lorig,*ltype);
		print "Linkarray pre:$#links\n".join("\n",@links)."\n" if $debug{'linkarrays'};
		eval $onlyfollow;
		eval $neverfollow;
		print "Linkarray post:$#links\n".join("\n",@links)."\n" if $debug{'linkarrays'};
		
		$linkDepth++;
		while( $newlink=pop(@links) )
		{
			$_ = $newlink;
			if( /http:\/\/([^:\/]*)/ )
			{
				$small = $1;
				$small =~ s/\.$//;
				$small =~ tr/A-Z/a-z/;
				$_ = $small;
				if( !/\d+/ )
				{
					$newlink =~ s/http:\/\/([^:\/]*)/http:\/\/$small/;
					$newlink=~ s/\/$//;

					if( !defined($visited{$newlink}) )
					{
						print 'Adding to nextStage:'.$newlink."\n" if $debug{'database'};
						print NEXTSTAGE '0:'.$linkDepth.':'.$newlink."\n";
					}
				}
			}
		}
	}

	
	print "Database swap:";
	`rm -f links.unknown`;
	`mv links.nextstage		links.unknown`;
	close(NEXTSTAGE);
	close(UNKNOWN);
	close(VISITED);
	undef %visited;
	
	print "done.\n";
}
exit;

#####################
######## Subroutines
#####################




sub signalhandler
{
	print "\nGot signal - saving\n";
	
	$SIG{'INT'}='IGNORE';
	$SIG{'TERM'}='IGNORE';
	$SIG{'ABRT'}='IGNORE';
	$SIG{'ALRM'}='IGNORE';
	exit(0);
}




sub htmlToSentences
{	
	local($contents)=@_;
	local(@sentences);
	undef @sentences;
	
	$_=$contents;
	
	# remove special tags
	s{ \-<br> }{}gix;							# 'Bundes-<br>regierung' becomes 'Bundesregierung'
	s/<br>/ /gix;								# every other brake is a space									
	s{ <\/? (A|I|B|U|STRIKE|BIG|SMALL|SUB|SUP|EM|STRONG|FONT) [^>]* >}{}gix;
	s{<IMG\s[^>]*ALT="([^"]+)[^>]*>}{$1}gix; 	# '<IMG="fasel.gif" ALT="Katzenbild">' becomes 'Katzenbild'
	# remove everything else
	s{ < [^>]* > }{ HTMLCOMMAND }gx;

	&decode_entities($_);
	s/[!\?]+/ . /g;								# exclamation and question marks now fullstops
	s/[\;\,]+/ /g;								# semicoli,kommata now spaces
	&encode_entities($_);
	s/&#?[0-9 ]*;/ /g;					 		# remove every special html character
	s/[^0-9a-zA-Z&;!?.@-]+/ /g;					# remove unneeded characters
	s/(-)+/-/g;									# '--- this ---' becomes '- this -'
	s/\d\./$1/;									# '1. Januar'  becomes '1 Januar'
	s/\s-/ /g;									# 'fasel -bla' becomes 'fasel bla'
	s/-\s/ /g;									# 'fasel - bla' becomes 'fasel- bla'  gets 'fasel bla'
	
												# now we have paragraphs 
	s/\.\s/HTMLCOMMAND/g;						# split in sentences
	s/\s+/ /g;
	s{(HTMLCOMMAND\s*)+}{HTMLCOMMAND}gx;
	
	@sentences = split('HTMLCOMMAND',$_);
	
	print "Sentences :\n".join("\n#####SENTENCE\n", @sentences)."\n" if $debug{'sentences'};
	return @sentences;
}


sub sentenceToWords
{
	local($sentence)=@_;
	local(@words);
	
	@words=grep(/^([A-Za-z0-9-]|\&[A-Za-z]+\;){$commandline{'minword'},$commandline{'maxword'}}$/, (split(/ /,$sentence)) );
	return @words;
}


sub htmlToContents
{	
	local($contents)=@_;
	local($link,$content);
	local(@linksonthispage, @namesonthispage);
	undef @linksonthispage;
	undef @namesonthispage;

	$_=$contents;
	s/[\r\n\s]+/ /g;
	# get all links
	s{ \-<br> }{}gix;							# 'Bundes-<br>regierung' becomes 'Bundesregierung'
	s/<br>/ /gix;									
	s{ <\/? (I|B|U|STRIKE|BIG|SMALL|SUB|SUP|EM|STRONG|FONT) [^>]* >}{}gix;
	s{<IMG\s[^>]*ALT="([^"]+)[^>]*>}{$1}gix; 	# '<IMG="fasel.gif" ALT="Katzenbild">' becomes 'Katzenbild'
	s{<A\s[^>]*HREF="([^"]+)[^>]*>(.*?)</A>}
	{
		$link=$1;
		$content=$2;
		$link=~ s/\/$//;
		$content=~ s{<[^>]>}{}gx;
		$content= &decode_entities($content);
		$content= &encode_entities($content);
		$content=~ s/&#?[0-9 ]*;/ /g;					 		# remove every special html character
		$content=~ s/(-)+/-/g;									# '--- this ---' gets '- this -'
		$content=~ s/([0-9])\./$1/;								# '1. Januar'  gets '1 Januar'
		$content=~ s/\s-/ /g;									# 'fasel -bla' gets 'fasel bla'
		$content=~ s/-\s/ /g;									# 'fasel - bla' and 'fasel- bla'  gets 'fasel bla'
		$content=~ s/[^0-9a-zA-Z&;!?.@-]+/ /g;					# remove unneeded characters

		if($link && $content)
		{
			push(@linksonthispage,($link.' '.$content));
		}  
	}giesx;
	# get the structure
	
	print "Links :\n".join("\n#####\n", @linksonthispage)."\n" if $debug{'contents'};
	
	return @linksonthispage;
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




