#!/usr/bin/perl

$cleandictionary = shift(@ARGV);
$webdictionary = shift(@ARGV);

$reversed=1 if shift(@ARGV);

print STDERR "Using $cleandictionary as CLEAN and $webdictionary as WEB\n";
open(CLEAN,$cleandictionary);
while($_=<CLEAN>)
{
	chop;
	s/\s+//g;
	s/\r//g;
	tr/A-Z/a-z/;
	$clean{$_}=1;
}
close(CLEAN);

open(WEB,$webdictionary);
while($_=<WEB>)
{
	if( /^(.*):\d+\/\d+$/ )
	{
		print $_ if $clean{$1} && !$reversed;
		print $_ if !$clean{$1} && $reversed;
	}

}
close(WEB);

