#!/usr/local/bin/perl5.002

while( $filename = shift(@ARGV) )
{
	if( open(FILE,"<$filename") )
	{
		$allwords=0;
		%recalculatedWords=();
		
		open(CLEAN,"|sort >$filename.recalc");
		while( $_ = <FILE>)
		{
			if( /^(.*):(\d+)\/(\d+)$/ )
			{
				$wordZaehler{$1} += $2;
				$wordNenner{$1} += $3;
			}
		}
		close(FILE);
		
						
		while( ($word,$zaehler) = each(%wordZaehler) )
		{
			print CLEAN $word.':'.$zaehler.'/'.$wordNenner{$word}."\n";
		}
		close(CLEAN);

	}
}
