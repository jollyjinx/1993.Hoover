
while( $filename = shift(@ARGV) )
{
	open(COUNTRYIN,"<$filename") || die "Can't read $filename[$!] \n";
	while( $_ = <COUNTRYIN>)
	{
		chop;
		($count,$word) = split(/ /,$_); 
		$globalwords{$word} .=$count.$filename;
	}
	close(COUNTRYIN);
}

while( ($word,$value) = each %globalwords )
{
	print $value."\t\t".$word."\n";
}




