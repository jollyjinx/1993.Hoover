#
#	title	:	wwwCacheFiller.pl		WWW proxycache fill
#	author	:	Patrick Stein <jolly@joker.de>
#	version	:	2.11
#	date	:	Mon Sep  2 16:30:39 MET DST 1996

use GDBM_File;

$retrytime=1000;								#	maximum time before retry to a refused page

$user_agent = "CIS WordSearcher 2.11";			#	name of this program to tell the httpd's
$|=1;											#	flush files immediate

@picturearray=('\.gif$', '\.GIF$', '\.TIF$', '\.tif$', '\.jpg$', '\.JPG$', '\.jpeg$', '\.JPEG$', '\.gz$', '\.Z$', '\.z$', '\.zip$', '\.ps$', '\.PS$', '\.eps$', '\.EPS$','\.mov$','\.MOV$','\.avi$','\.AVI$','\.mpg$','\.MPG$','\.mpeg$','\.MPEG$');
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
    dictionary=[none|remove|reuse]
    languages=[none|remove|reuse]	create a database of all words found.
		heuristic=[words|bigrams]	languagedatabase gets stored either
							as single words or as bigrams.
		
    debug=[database]:[dictionary]:[paragraphs]:[sentences]:[linkarrays]
        
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
    timeout=<int>			maximal time to wait for a url to resolve
	
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
			if(/^text$/)		{	$onlyfollow='@linksOK=grep(/\.html$/,@links);'."\n".
												'push(@linksOK,grep(/\.htm$/,@links));'."\n".
												'@links=@linksOK;'."\n";															next;}
			if(/^!pictures$/)	{	push(@neverfollowarray, @picturearray);															next;}
			if(/^de$/)			{	push(@onlyfollowarray, ('\.de[:\/]','\.leo\.org[:\/]','\.ch[:\/]','\.at[:\/]'));				next;}
			if(/^!de$/)			{	push(@neverfollowarray, ('\.de[:\/]','\.leo\.org[:\/]','\.ch[:\/]','\.at[:\/]'));				next;}
			if(/^us$/)			{	push(@followarray, ('\.us[:\/]','\.ca[:\/]','\.edu[:\/]','\.com[:\/]','\.mil[:\/]','\.net[:\/]','\.gov[:\/]'));		next;}
			if(/^!us$/)			{	push(@neverfollowarray, ('\.us[:\/]','\.ca[:\/]','\.edu[:\/]','\.com[:\/]','\.mil[:\/]','\.net[:\/]','\.gov[:\/]'));										next;}
			if(/^!(.*)/)		{	push(@neverfollowarray,$1);																		next;}
			push(@onlyfollowarray,$_);
		}
	}
}
$neverextract = '$url=0 if /'.join('/ || /', @picturearray).'/;';
$neverfollow = '@links=grep(!/'.join('/,@links);'."\n".'@links=grep(!/', @neverfollowarray).'/,@links);'."\n";
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
dbmopen(%visited,'visited',0666);
dbmopen(%unknownLink,'unknownLink',0666);
dbmopen(%nextStage,'nextStage',0666);

dbmopen(%words,'words',0666) if $commandline{'dictionary'} ne 'none';
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
	dbmopen(%languageUrlDatabase,'languageUrlDatabase',0666);
	dbmopen(%languageSentenceDatabase,'languageSentenceDatabase',0666);
	dbmopen(%languageWordDatabase,'languageWordsDatabase',0666);
}
if($commandline{'languages'} eq 'remove')
{
	print "Removing language database:";

	%languageUrlDatabase=();
	%languageSentenceDatabase=();
	$languageSentenceCount=0;
	%languageWordDatabase=();
	print "done.\n";
}
else
{
	print "Reusing language database:";
	$languageSentenceCount=scalar(keys(%languageSentenceDatabase));
	print "done.\n";
}




%RespMessage = (           # Define all response messages for use by callers
    000, 'Unknown Error',
    200, 'OK',
    201, 'CREATED',
    202, 'Accepted',
    203, 'Partial Information',
    204, 'No Response',
    301, 'Moved',
    302, 'Found',
    303, 'Method',
    304, 'Not Modified',
    400, 'Bad Request',
    401, 'Unauthorized',
    402, 'Payment Required',
    403, 'Forbidden',
    404, 'Not Found',
    500, 'Internal Error',
    501, 'Not Implemented',
    502, 'Bad Response',
    503, 'Too Busy',
    600, 'Bad Request in Client',
    601, 'Not Implemented in Client',
    602, 'Connection Failed',
    603, 'Timed Out',
);

require "wwwbot.pl";
require "wwwhtml.pl";




for(0..$commandline{'maxdepth'})
{	
	$actualdepth=$_;
	
	print "Entering Stage $actualdepth\n";
	print "Database swap:";
	%unknownLink=%nextStage;
	%nextStage=();
	print "done.\n";
	
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
		print "[$response] $RespMessage{$response}\n";
	
		if($response eq 603)
		{
			$nextStage{$url}=pack("L L",time(),$linkDepth);
			next;
		}
		$visited{$url}=time();

		
		$_=$url;
		eval $neverextract;
		next if (!$url);

		if($response eq 200 && $commandline{'languages'} ne 'none')
		{
			if(@sentences = &htmlToSentences($url,$contents))
			{
				while($momsentence=pop(@sentences))
				{
					$languageSentenceCount++;
					$languageUrlDatabase{$languageSentenceCount}=$url;
					
					$languageSentenceDatabase{$languageSentenceCount}=$momsentence;
					if( $commandline{'heuristic'} eq 'bigrams' )
					{
						@momwords = &sentenceToBigrams($momsentence);
					}
					else
					{	
						@momwords = &sentenceToWords($momsentence);
					}
						
					if(@momwords)
					{
						while($momword=pop(@momwords))
						{
							if(!defined($languageWordDatabase{$momword}))
							{
								$languageWordDatabase{$momword}=$languageSentenceCount;
							}
							else
							{
								@mom=split(':', $languageWordDatabase{$momword});
								push(@mom,$languageSentenceCount) if(! grep(/$languageSentenceCount/,@mom));
								$languageWordDatabase{$momword}=join(':',@mom);
							}
							print 'languageWordDatabase{'.$momword.'}='.$languageWordDatabase{$momword}."\n" if $debug{'languages'};
	
						}
					}
				}
			}
		}	
			
		if($response eq 200 && $commandline{'dictionary'} ne 'none')
		{
			@newwords=&htmlToWords($url,$contents);
			print "Adding from $url words:".join(', ',@newwords)."\n" if $debug{'dictionary'};
			foreach $mom ( @newwords )
			{
				$words{$mom}++;
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



sub htmlToWords
{
	local($url,$contents)=@_;
	local(@mom);
	undef @mom;
	
	@sentences = &htmlToSentences($url,$contents);

	$contents=join(' ',@sentences);
	$contents =~ s/&uuml;/ue/g;
	$contents =~ s/&Uuml;/Ue/g;
	$contents =~ s/&auml;/ae/g;
	$contents =~ s/&Auml;/Ae/g;
	$contents =~ s/&ouml;/oe/g;
	$contents =~ s/&Ouml;/Oe/g;
	$contents =~ s/&szlig;/ss/g;
	
	$contents =~ tr/a-z/A-Z/;
	$_=$contents;
	push(@mom,/ [A-Z-]{$commandline{'minword'},$commandline{'maxword'}} /g);
	
	return @mom;
}


sub htmlToSentences
{	
	local($url,$contents)=@_;
	local($mom, @paragraphs, @sentences, @foundSentences);
	undef $mom;
	undef @paragraphs;
	undef @sentences;
	undef @foundSentences;
	
	$contents =~ s/\n+//g;
	$contents =~ s/\n+//g;
	$contents =~ s/\s+/ /g;
	$contents =~ s/<[^>]+>/HTMLCOMMAND/g;

	@paragraphs = split('HTMLCOMMAND',$contents);
	
	print 'Paragraph :'.join("\n#####PARAGRAPH#######\n", @paragraphs)."\n" if $debug{'paragraphs'};
		
	foreach $mom (@paragraphs)
	{
		$mom =~ s/[\.\?\!]/HTMLSENTENCE/g;
	
		@sentences = split('HTMLSENTENCE', $mom);
		foreach $mom (@sentences)
		{
			if( (length($mom)>$commandline{'sentencelength'}) && !/\\/)
			{
				print "#####SENTENCE:$mom\n" if $debug{'sentences'};
				push(@foundSentences,$mom);
			}
		}
	}
	return @foundSentences;
}


sub sentenceToWords
{
	local($sentence)=@_;
	local(@words,$mom);
	undef @words;
	undef $mom;
		
#	$sentence =~ tr/a-z/A-Z/;
	$sentence =~ s/[,;] / /g;
	
	@spacedthings=split(/\s/,$sentence);
	@words=grep(/[A-Za-z-&;]{$commandline{'minword'},$commandline{'maxword'}}/,@spacedthings);
	return @words;
}



sub sentenceToBigrams
{
	local($sentence)=@_;
	local(@words,@bigrams,$mom);
	undef $mom;
	undef @words;
	undef @bigrams;
	
	@words = &sentenceToWords($sentence);
	while( $mom = shift(@words) )
	{
		push(@bigrams,$mom.'|'.@words[0]) if @words[0];
	}
	return @bigrams;
}





