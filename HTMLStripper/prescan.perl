#!/usr/bin/perl
use strict;

my $urlname;
my $pagecontent;
$|=1;
while(<>)
{	
	s/[\x00-\x09\x0b-\x0c\x0e-\x19]+/ /g;
	if( (/\<\!\-\-\s*URL:\s*http:\/\/(\S+)\s*/) || (/Hoover-Url:\s*(\S+)/) )
    {
		my $momurl=$1;
		chomp($momurl);
		my $len = length($pagecontent);
		if($urlname && $len>200 && $len<10000000)		# be aware of very large documents
		{
    		printf "Hoover-Url: %s Size: %d\n",$urlname, $len;
			print $pagecontent."\n\n\n";
		}
		$urlname =$momurl;
        $pagecontent = undef;
	}
	else
	{
		$pagecontent.=$_;
	}
}


if($urlname)
{
	printf "Hoover-Url: %s Size: %d\n",$urlname,length($pagecontent);
	print $pagecontent."\n";
}
close(STDOUT);

exit;
