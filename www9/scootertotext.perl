
require "HTMLRecognizer.pm";

$commandline{'minword'} = 1;
$commandline{'maxword'} = '';


while(<>)
{
	if( /^@\+\s+http:/ )
	{
		$newurl = $_;
		@sentences = &htmlToSentences($contents);
		
		print STDOUT $url;
		while( $sentence = shift(@sentences) )
		{
			@words = &sentenceToWords($sentence);
			print STDOUT 'SEN:'.join(':',@words)."\n" if $#words > 20;
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