
require "HTMLRecognizer.pm";

$commandline{'minword'} = 2;
$commandline{'maxword'} = '';
$commandline{'maxequalwordspersentence'}=3;
$commandline{'minsentencelength'}=8;

while(<>)
{
	if( /^URL:/i )
	{
		$newurl = $_;

		print STDOUT $url;
		@sentences = &htmlToSentences($contents);
		
		while( $sentence = shift(@sentences) )
		{
			@words = &sentenceToWords($sentence);
			print STDOUT 'SEN:'.join(':',@words)."\n" if $#words > $commandline{'minsentencelength'};
		}

		$url = $newurl;
		undef $contents;
		undef @sentences;
	}
	else
	{	
		if( (!/^CONTENTTYPE:/) && (!/^CONTENT:/) )
		{
			$contents.=$_;
		}
	}
}
