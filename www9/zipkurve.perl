
while(<>)
{
	/^(.*):(\d+)\/(\d+)$/;
	$gwordcount+=$2;
	$counter++;
	if ($gwordcount/$3 >.4 && !$flag)
	{
		$importantword{$_}='';
		$flag=1;
		print keys(%importantword);
	}
	else
	{
		$importantword{$_}='';
	}
}
