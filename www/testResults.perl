
$rightlanguage = shift(@ARGV);
$filename = shift(@ARGV);
open(FILE,"<$filename") || die "Can't open $filename : $!\n";
while($_=<FILE>)
{
	if( /^([a-zA-Z0-9\.]+):(\d+)\.\d+:/ )
	{
		if( $1 eq $rightlanguage )
		{
			$percent{$2}++;
		}
		else
		{
			$percent{-1*$2}++;
		}
	}
}
close(FILE);
for $i ( -100..100 )
{
	print $percent{$i}."\n";
}
