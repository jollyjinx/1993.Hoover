#!/usr/bin/perl

$cleandictionary = shift(@ARGV);
$webdictionary = shift(@ARGV);

$reversed=1 if shift(@ARGV);

print STDERR "Using $cleandictionary as CLEAN and $webdictionary as WEB\n";
open(CLEAN,$cleandictionary);
while($_=<CLEAN>)
{
	chop;
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
		$fasel=$1;
		$fasel =~ s/&szlig;/ss/g;
		$fasel =~ s/&auml;/ae/g;
		$fasel =~ s/&ouml;/oe/g;
		$fasel =~ s/&uuml;/ue/g;
		
		print $_ if $clean{$fasel} && !$reversed;
		print $_ if !$clean{$fasel} && $reversed;
	}

}
close(WEB);

