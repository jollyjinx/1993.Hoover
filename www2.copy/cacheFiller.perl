#
#	title	:	wwwCacheFiller.perl						WWW proxycache fill
#	author	:	Patrick Stein <jolly@cis.uni-muenchen.de>
#	version	:	2.20
#	date	:	Fri Sep 27 09:09:20 MET DST 1996

require 5.002;
use GDBM_File;

$retrytime=1000;								#	maximum time before retry to a refused page

$user_agent = "CIS WordSearcher 2.20";			#	name of this program to tell the httpd's
$|=1;											#	flush files immediate

@picturearray=(	'\.gif$','\.tif$', '\.jpg$','\.jpeg$', 
				'\.gz$',  '\.z$', '\.zip$',
				'\.ps$', '\.eps$', 
				'\.mov$','\.avi$','\.mpg$','\.mpeg$');
@neverfollowarray=('\/cgi-bin\/','\.map$','^mailto:','^gopher:','^ftp:');


if(!grep(/url/,@ARGV) && !grep(/reuse/,@ARGV))
{
	print <<EOF;
NAME
    $0 - get all links from a begining url

SYNOPSIS
    $0 [ option ]... url=http...

OPTIONS :
    database=[remove|reuse]
    languages=[none|remove|reuse]   create a database of all words found.
        heuristic=[words|bigrams]   languagedatabase gets stored either
                                    as single words or as bigrams.
        
    debug=[database]:[words]:[sentences]:[bigrams]:[linkarrays]
        
    follow/links=[option]:[option]:...
        with option text:   follow only .html and htm documents
                    !pictures   never get picutres
                    [!]us       [never] get things from .edu .mil .com .net ....
                    [!]de       [never] get things from .de .leo.org ....
                    regex       enter regular expression like \.uk\/ to get 
                                just links from the uk
    
    maxdepth=<int>  Searchtree ends at depth.
    sentencelength=<int>    minimal size a sentence needs to be one
    minword=<int>           minimal length a word has to have
    maxword=<int>           maximal length a word has to have
    timeout=<int>           maximal time to wait for a url to resolve
    
    url=http                begin at url.

EXAMPLES
    
    perl5 wwwCacheFiller.pl url=http://www.next.com/ database=remove
	perl5 wwwCacheFiller.perl links=\\!pictures:\\!us:\\!de:\\!\\\\.org:\\!\\\\.uk:\\!\\\\.uk:text \
url=http://www.w3.org/hypertext/DataSources/WWW/Servers.html \
database=remove languages=remove heuristic=bigrams

BUGS
    Needs GDBM_File command - so perl5.003 or higher is mandatory.

EOF
	exit(1);
}

$commandline{'database'}='reuse';
$commandline{'dictionary'}='none';
$commandline{'languages'}='none';
$commandline{'heuristic'}='words';
$commandline{'url'}='http://www.next.com/';
$commandline{'maxdepth'}=30;
$commandline{'sentencelength'}=30;
$commandline{'minword'}=3;
$commandline{'maxword'}='';
$commandline{'timeout'}=5;


while($_=pop(@ARGV))
{
	$commandline{'dictionary'}=$1 		if /^dictionary=(.*)/;
	$commandline{'database'}=$1 		if /^database=(.*)/;
	$commandline{'languages'}=$1 		if /^languages=(.*)/;
	$commandline{'heuristic'}=$1 		if /^heuristic=(.*)/;
	$commandline{'url'}=$1				if /^url=(.*)/;
	$commandline{'maxdepth'}=$1			if /^maxdepth=(\d+)/;
	$commandline{'sentencelength'}=$1	if /^sentencelength=(\d+)/;
	$commandline{'minword'}=$1			if /^minword=(\d+)/;
	$commandline{'maxword'}=$1			if /^maxword=(\d+)/;
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
			if(/^us$/)			{	push(@followarray, ('\.us[:\/]','\.ca[:\/]','\.edu[:\/]',
														'\.com[:\/]','\.mil[:\/]','\.net[:\/]',
														'\.gov[:\/]'));								next;}
			if(/^!us$/)			{	push(@neverfollowarray, ('\.us[:\/]','\.ca[:\/]','\.edu[:\/]',
															'\.com[:\/]','\.mil[:\/]','\.net[:\/]',
															'\.gov[:\/]'));							next;}
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

print	"Database     :",$commandline{'database'},"\n";
print	"Dictionary   :",$commandline{'dictionary'},"\n";
print	"Languages    :",$commandline{'languages'},"\n";
print	"Heuristic    :",$commandline{'heuristic'},"\n";
print	"Never Follow :\n$neverfollow\n";
print	"Only Follow  :\n$onlyfollow\n";
print	"Begin        :",$commandline{'url'},"\n";
print	"Maxdepth     :",$commandline{'maxdepth'},"\n";
print	"min. Sentence:",$commandline{'sentencelength'},"\n";
print	"min. Word    :",$commandline{'minword'},"\n";
print	"max. Word    :",$commandline{'maxword'},"\n";
print	"Timeout      :",$commandline{'timeout'},"\n";


$SIG{'INT'}='signalhandler';
$SIG{'TERM'}='signalhandler';
$SIG{'ABRT'}='signalhandler';
dbmopen(%visited,'links.visited.gdbm',0666);
dbmopen(%unknownLink,'links.unknown.gdbm',0666);
dbmopen(%nextStage,'links.nextstage.gdbm',0666);


%words=() if $commandline{'dictionary'} eq 'remove';

if($commandline{'database'} eq 'remove')
{
	print "Removing link database:";
	%visited=();
	%unknownLink=();
	%nextStage=();
	$nextStage{$commandline{'url'}}=pack("L L",0,0);
	print "done.\n";
}
else
{
	print "reusing link database:";
	%nextStage=%unknownLink;
	print "done.\n";
}


if($commandline{'languages'} ne 'none')
{
	dbmopen(%languageUrlDatabase,'language.url.gdbm',0666) || die "Can't open languageUrlDatabase\n";
	dbmopen(%languageWordDatabase,'language.word.gdbm',0666)|| die "Can't open languageWordDatabase\n";
	dbmopen(%languageBigramDatabase,'language.bigram.gdbm',0666)|| die "Can't open languageBigramDatabase\n";
}

if($commandline{'languages'} eq 'remove')
{
	print "Removing language database:";
	$languageUrlCount=0;
	%languageUrlDatabase=();
	%languageWordDatabase=();
	%languageBigramDatabase=();
	print "done.\n";
}
else
{
	print "Reusing language database:";
	$languageUrlCount=scalar(keys(%languageUrlDatabase));
	print "done.\n";
}





require "entityConverter.perl";
require "wwwbot.pl";
require "wwwhtml.pl";




for(0..$commandline{'maxdepth'})
{	
	$actualdepth=$_;
	
	print "Entering Stage $actualdepth\n";
	print "Database swap:";%unknownLink=%nextStage;%nextStage=();print "done.\n";
	
	
	while( ($url,$value) = each(%unknownLink) )
	{
		print "Got from database $url \n" if $debug{'database'};
		($lasttimeTried,$linkDepth)=unpack("L L",$value);
		next if $visited{$url};
		next if $lasttimeTried gt time()-$retrytime;

		$unkownLink{$url}=pack("L L",time(),$linkDepth);

		undef $headers;
		undef @headers;
		undef %headers;		
		undef $contents;
		undef @contents;
		undef %contents;
		undef @links;
		undef %links;
	
		printf "%3d %70s",$linkDepth,$url;
			$response=&www'request('GET',$url,*headers,*contents,$commandline{'timeout'});		
		print "[$response] $httpResponse{$response}\n";
	
		if($response eq 603)
		{
			$nextStage{$url}=pack("L L",time(),$linkDepth);
			next;
		}
		$visited{$url}=time();
		
		
		$_=$url;
		eval $neverextract;
		next if (!$url);

		if( ($response eq 200)
			&& ($commandline{'languages'} ne 'none')
			&& (@sentences = &htmlToSentences($contents)) )	
		{
			$languageUrlCount++;
			$languageUrlDatabase{$languageUrlCount}=$url;
			
			while($sentence=pop(@sentences))
			{
				@words = &sentenceToWords($sentence);
				
				while($word=pop(@words))
				{
					if(!defined($languageWordDatabase{$word}))
					{
						$languageWordDatabase{$word}=$languageUrlCount;
					}
					else
					{
						@mom=split(':', $languageWordDatabase{$word});
						push(@mom, $languageUrlCount) if(! grep(/$languageUrlCount/,@mom));
						$languageWordDatabase{$word}=join(':',@mom);
					}
					print '$languageWordDatabase{'.$word.'}='.$languageWordDatabase{$word}."\n" if $debug{'words'};
				}
				
				
				if( $commandline{'heuristic'} eq 'bigrams' )
				{
					@bigrams = &sentenceToBigrams($sentence);
					
					while($bigram=pop(@bigrams))
					{
						if(!defined($languageBigramDatabase{$bigram}))
						{
							$languageBigramDatabase{$bigram}=$languageUrlCount;
						}
						else
						{
							@mom=split(':', $languageBigramDatabase{$bigram});
							push(@mom, $languageUrlCount) if(! grep(/$languageUrlCount/,@mom));
							$languageBigramDatabase{$bigram}=join(':',@mom);
						}
						print '$languageBigramDatabase{'.$bigram.'}='.$languageBigramDatabase{$bigram}."\n" if $debug{'bigrams'};
					}

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
				$small =~ tr/A-Z/a-z/;
				$newlink =~ s/http:\/\/([^:\/]*)/http:\/\/$small/;
			}
			if( !defined($visited{$newlink}) && !defined( $nextStage{$newlink} ) )
			{
				print 'Adding to nextStage:'.$newlink."\n" if $debug{'database'};
				$nextStage{$newlink} = pack("L L",0, $linkDepth);
			}
		}
	}
}



dbmclose(%unknownLink);
dbmclose(%nextStage);
dbmclose(%visited);
dbmclose(%words);
exit;


sub signalhandler
{
	print "\nGot signal - saving\n";
	dbmclose(%unknownLink);
	dbmclose(%nextStage);
	dbmclose(%visited);
	dbmclose(%words);
	dbmclose(%languageUrlDatabase);
	dbmclose(%languageSentenceDatabase);
	dbmclose(%languageWordDatabase);
	exit(0);
}




sub htmlToSentences
{	
	local($contents)=@_;
	local(@sentences);
	undef @sentences;
	
	$_=$contents;
	
	# remove <!-- --> comments
	s{	<!(.*?)(--.*?--\s*)+(.*?)> }{	if ($1 || $3) {	"<!$1 $3>"; } }gesx;

	# remove special tags
	s{ <\/? (A|I|B|U|STRIKE|BIG|SMALL|SUB|SUP|EM|STRONG) >}{}gix;
	s/<A[^>]*>//gi;
	# remove everything else
	s{ < [^>]* > }{ HTMLCOMMAND }gx;

	&decode_entities($_);
	s/[\;\&]/. /;								# semicoli now fullstops
	&encode_entities($_);
	s/&#?[0-9 ]*;/ /g;					 		# remove every special html character
	s/(-)+\s/ /g;								# 'fasel - bla' gets 'fasel bla'
	s/[^a-zA-Z&;!?.@-]+/ /g;					# remove unneeded characters
	
												# now we have paragraphs 
	s/[!?.]/HTMLCOMMAND/g;						# split in sentences
	s/\s+/ /g;
	s{(HTMLCOMMAND\s*)+}{HTMLCOMMAND}gx;
	
	@sentences = split('HTMLCOMMAND',$_);
	
	print 'Sentences :\n'.join("\n#####SENTENCE\n", @sentences)."\n" if $debug{'sentences'};
	return @sentences;
}


sub sentenceToWords
{
	local($sentence)=@_;
	local(@words);
	
	@words=grep(/[A-Za-z-&;]{$commandline{'minword'},$commandline{'maxword'}}/, (split(/ /,$sentence)) );
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
		push(@bigrams,$word.'|'.@words[0]) if @words[0];
	}
	return @bigrams;
}





