#
#	title	:	wwwCacheFiller.perl						WWW proxycache fill
#	author	:	Patrick Stein <jolly@cis.uni-muenchen.de>
#	version	:	4.00
#	date	:	Fri Nov 22 17:00:33 MET 1996

require 5.002;

$user_agent = "CIS WordSearcher 3.01";			#	name of this program to tell the httpd's
select(STDOUT);$|=1;							#	flush files immediate

@picturearray=(	'\.gif$','\.tif$', '\.jpg$','\.jpeg$', 
				'\.gz$',  '\.z$', '\.zip$',
				'\.ps$', '\.eps$', 
				'\.mov$','\.avi$','\.mpg$','\.mpeg$');
@neverfollowarray=('\/cgi-bin\/','\.map$','^mailto:','^gopher:','^ftp:');

####
# program defaults
####

$commandline{'database'}			='reuse';
$commandline{'htmlpages'}			='none';

$commandline{'languages'}			='examine';
$commandline{'sentences'}			='examine';
$commandline{'contents'}			='none';
$commandline{'wordspersentence'}	=5;
$commandline{'minword'}				=2;
$commandline{'maxword'}				='';
$commandline{'languagemax'}			=40;

$commandline{'url'}					='http://www.w3.org/pub/DataSources/WWW/Servers.html';
$commandline{'maxdepth'}			=30;
$commandline{'timeout'}				=5;
$commandline{'retrytime'}			=1000;




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
       
    htmlpages=[none*|save]
                If set, all pages fetched are saved to disk to the directory
                htmlpages.
                
    languages=[none|examine*] 
                If set, the program will exmaine every html document depending 
                on one of the following algorithms.
    
        sentences=[none|examine*]
                If set, sentences of fetched url's are appended to the files 
                country/name. Name is the topmost internet domain of the fetched
                url. It then appends : URL:urlname
                                       SEN:word1:word2:...
                                       SEN:...                      to the file.
        
        wordspersentence=<int>
                Only sentences with greater and equal number of words will be 
                appended to the sentencesfiles. Default is $commandline{'wordspersentence'}.
        
        minword=<int>
                Minimal length a word has to have. Default is $commandline{'minword'}.
        maxword=<int>
                Maximal length a word has to have. Default is $commandline{'maxword'} (''== endless).
        languagemax=<int>
                Maximal size in megabytes of the language files. Default is $commandline{'languagemax'}.     

    debug=[database]:[sentences]:[contents]:[linkarrays]
        
    follow/links=[option]:[option]:...
        with option: text        follow only .html and .htm documents
                     !pictures   never get picutres
                     [!]us       [never] get things from .edu .mil .com .net ...
                     [!]de       [never] get things from .de .leo.org ...
                     regex       enter regular expression like \.uk\/ to get 
                                 just links from the uk
    
    url={urlname}
                Begin the searchtree with the url named. Default is
                $commandline{'url'}.
    maxdepth=<int>          
                Searchtree ends at depth. Default is $commandline{'maxdepth'}.
    timeout=<int>           
                Maximum time in seconds to wait for an url to resolve. 
                Default is $commandline{'timeout'}.
    retrytime=<int>           
                Minimum time in seconds to wait before an url might be retried. 
                Default is $commandline{'retrytime'}.


EXAMPLES
    
    perl5 wwwCacheFiller.pl url=http://www.next.com/ database=remove
    perl5 wwwCacheFiller.perl links=\\!us:\\!de:text

BUGS
    perl5.002 or higher is mandatory.

EOF
	exit(1);
}



####
# Command Line Options - iterates over all arguments given 
####

while($_=pop(@ARGV))
{
	$_='links=!us:!de:!\.jp:!\.org:!\.uk:text'	if /^default$/;
	
	$commandline{'database'}=$1 		if /^database=(.*)/;
	$commandline{'htmlpages'}=$1 		if /^htmlpages=(.*)/;

	$commandline{'languages'}=$1 		if /^languages=(.*)/;
	$commandline{'sentences'}=$1		if /^sentences=(.*)/;
	$commandline{'wordspersentence'}=$1	if /^wordspersentence=(\d+)/;
	$commandline{'minword'}=$1			if /^minword=(\d+)/;
	$commandline{'maxword'}=$1			if /^maxword=(\d+)/;
	$commandline{'languagemax'}=$1		if /^languagemax=(\d+)/;

	$commandline{'url'}=$1				if /^url=(.*)/;
	$commandline{'maxdepth'}=$1			if /^maxdepth=(\d+)/;
	$commandline{'timeout'}=$1			if /^timeout=(\d+)/;
	$commandline{'retrytime'}=$1		if /^retrytime=(\d+)/;
	
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
print	"Database      :".$commandline{'database'}."\n";
print	"HTML Pages    :".$commandline{'htmlpages'}."\n";
print	"Languages     :".$commandline{'languages'}."\n";
print	"Sentences     :".$commandline{'sentences'}."\n";
print	"Words/sentence:".$commandline{'wordspersentence'}."\n";
print	"min. Word     :".$commandline{'minword'}."\n";
print	"max. Word     :".$commandline{'maxword'}."\n";
print	"max. Langfile :".$commandline{'languagemax'}." MByte\n";
print	"Begin         :".$commandline{'url'}."\n";
print	"Maxdepth      :".$commandline{'maxdepth'}."\n";
print	"Timeout       :".$commandline{'timeout'}."\n";
print	"Retrytime     :".$commandline{'retrytime'}."\n";
print	"Debugging     :",keys(%debug),"\n";

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




####
# MAIN Loop - iterates over url's
####

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
		if( $lasttimeTried gt time()-$commandline{'retrytime'} )
		{
			print NEXTSTAGE $lasttimeTried.':'.$linkDepth.':'.$url."\n";
			next;
		}

		undef %headers;		
		undef $contents;
		undef @links;
		undef @labs;
		undef @lorig;
		undef @ltype;
	
	
		@mom = &wwwurl'parse($url);																	# extract the site of the url
		$country = $mom[1];																			# lowercase and get the country
		$country =~ tr/A-Z/a-z/;																	# part like 'se' from 'uri.ifo.se'
		$country =~ s/.*\.([^\.]+)$/$1/;
		
		
		printf "%2d %65s",$linkDepth,$url;
		if( -f "countries/$country"																	# Don't get more than 
			&& (@fasel=stat(_)) 																	# languguagemax Megabytes for
			&& ( $fasel[7]>($commandline{'languagemax'}*1000000) ))									# any country - this even's out
		{																							# fast access to specific countries
			print " File full\n";
			next;
		}
		
		$response=&www'request('GET',$url,*headers,*contents,$commandline{'timeout'});				# get the url
		print ' '.$httpResponse{$response}."\n";
		
		if($response eq 603 || $response eq 400)													# in case of 'Timed out (603)'
		{																							# 'Bad request (400)' try that
			print NEXTSTAGE time().':'.$linkDepth.':'.$url."\n";									# page later
			next;
		}

		$_=$url;																					# never parse pictures or the
		eval $neverextract;																			# like, furthermore we won't parse 
		next if ( !$url && (200 ne response) );														# url's we didn't get
		
		
		$HTMLcontents 	= $contents;																# contents gets destroyed in
		&wwwhtml'extract_links($url,*headers,*contents,*links,*labs,*lorig,*ltype);					# wwwhtml'extractlinks so save them
		for $i (0..$#links)
		{																							# lowercase all server names
			@mom = &wwwurl'parse($links[$i]);														# to get uniform url's
			$mom[1] =~ tr/A-Z/a-z/;
			$mom[1] =~ s/\.+$//g;
			$links[$i] = &wwwurl'compose(@mom);
		}


		if( $commandline{'htmlpages'} eq 'save' )
		{
			undef $path;
		
			($scheme, $site, $port, $path, $query, $frag) =	&wwwurl'parse($url);
			$_=$path;
			s/^\///;
			undef $path;
			undef $file;
			if( !/\// )
			{
				$file=$_;
				$path='';
			}
			else
			{
				/^(.+)\/([^\/]*)$/;
				$path = $1;
				$file = $2;
			}
			$path = '.' if !length($path);
			$file = '.html' if !length($file);
			`mkdirs html/$site/$path` if( ! -d "html/$site/$path");
			if( open(HTML,">html/$site/$path/$file") )
			{
				print HTML $HTMLcontents;
				close(HTML);
			}
			else
			{
				print "Can't open html/$site/$path/$file\n";
			}			

		}



		if( $commandline{'languages'} ne 'none' && (length($country)>1) )
		{
			open(COUNTRY,">> countries/$country") || die "Can't open countries/$country:[$!]\n";	# It' fatal not beeing able to write
			print COUNTRY 'URL:'.$url."\n";

			&htmlToURLContents($HTMLcontents,*linkContent);											# extract links and linktext
			
			for $i (0..$#lorig)																		# save absolute links and their text
			{
				print COUNTRY 'LIN:'.$links[$i].' '.$linkContent{$lorig[$i]}."\n" if $linkContent{$lorig[$i]};
			}
			undef %linkContent;
			
			@sentences = &htmlToSentences($HTMLcontents);	
			while($sentence=shift(@sentences))														# get sentences of the page and
			{																						# save them in seperate lines
				@words = &sentenceToWords($sentence);
				if($#words > $commandline{'wordspersentence'} )
				{
					print COUNTRY 'SEN:'.join(':',grep(!/^[0-9\-\;]+$/,@words))."\n";
				}
			}
			close(COUNTRY);
		}



		print VISITED $url."\n";																	# Yes, we did parse the url 
		$visited{$url}=1;																			# correctly - save that
				
		print "Linkarray pre:$#links\n".join("\n",@links)."\n" if $debug{'linkarrays'};
		eval $onlyfollow;
		eval $neverfollow;
		print "Linkarray post:$#links\n".join("\n",@links)."\n" if $debug{'linkarrays'};
		
		$linkDepth++;
		while( $newlink=pop(@links) )
		{
			$_ = $newlink;
			if( /^http:\/\// && !/\d+/ && (!defined($visited{$newlink})) )
			{
				print NEXTSTAGE '0:'.$linkDepth.':'.$newlink."\n";
				print 'Adding to nextStage:'.$newlink."\n" if $debug{'database'};
			}
		}
	}

	
	print "Database swap:";
	close(UNKNOWN);
	`rm -f links.unknown`;
	close(NEXTSTAGE);
	`mv links.nextstage links.unknown`;
	
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
		$content=~ s/&#?[0-9 ]*;/ /g;					 		# remove every special html character
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
	
	@words=grep(/^([A-Za-z0-9-]|\&[A-Za-z]+\;){$commandline{'minword'},$commandline{'maxword'}}$/, (split(/ /,$sentence)) );
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




