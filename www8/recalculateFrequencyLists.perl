#!/usr/local/bin/perl5.002

while( $filename = shift(@ARGV) )
{
	if( open(FILE,"<$filename") )
	{
		$allwords=0;
		%recalculatedWords=();
		
		open(CLEAN,">$filename.recalc");
		while( $_ = <FILE>)
		{
			
			if( /^(.*):(\d+)\/(\d+)$/ )
			{
				$recalculatedWords{$1} += $2;
				$allwords +=$2;
				
			}
		}
		close(FILE);
		
						
		while( ($word,$value) = each(%recalculatedWords) )
		{
			print CLEAN $word.':'.$value.'/'.$allwords."\n";
		}
		close(CLEAN);

	}
}
