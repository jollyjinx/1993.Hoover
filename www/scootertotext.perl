
require "HTMLRecognizer.pm";

$commandline{'minword'} = 1;
$commandline{'maxword'} = '';
$commandline{'maxequalwordspersentence'}=3;
$commandline{'minsentencelength'}=8;

while(<>)
{
	if( /^@\s*\+\s*http:(\S*)/ )
	{
		$flag=0;
		$newurl = 'URL:'.$1."\n";
		
		$_ = $url;
		if( /\.lt(\/|\:)/ )
		{
			print STDOUT $url;
			@sentences = &htmlToSentences($contents);
			
			while( $sentence = shift(@sentences) )
			{
				@words = &sentenceToWords($sentence);
				print STDOUT 'SEN:'.join(':',@words)."\n" if $#words > $commandline{'minsentencelength'};
			}
		}
		$url = $newurl;
		undef $contents;
		undef @sentences;
	}
	else
	{	
		$contents.=$_ if $flag;
		
		if( /^\s*$/ )
		{
			$flag=1;
		}
	}
}