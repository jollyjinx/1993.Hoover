
while(<>)
{
	/^(\d+)\s.*/;
	$wordcount{$1}++;
	$gwordcount+=$1;
}

foreach $key (keys(%wordcount))
{
	printf "%3d Anzahl:%5d Verhaeltnis:%5.4f%%\n",$key,$wordcount{$key},($key/$gwordcount)*100;
}