#!/usr/local/bin/perl5.002

while( $_ = <> )
{
	if( /^(.*):(\d+)\/(\d+)$/ )
	{
		$wordZaehler{$1} += $2;
		$wordNenner{$1} += $3;
	}
}

while( ($word,$zaehler) = each(%wordZaehler) )
{
	print $word.':'.$zaehler.'/'.$wordNenner{$word}."\n";
}

