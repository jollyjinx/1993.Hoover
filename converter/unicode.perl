#!/usr/bin/perl

$unicodedir = $ENV{'UNICODETABLES_DIRECTORY'};
$tounicode = 1;

while( $_ = shift(@ARGV) )
{
	if( /-table/ )
	{
		$tablename = shift(@ARGV);
	}
	if( /-uni/ )
	{
		$tounicode = 1;
	}
	if( /-rev/ )
	{
		$tounicode = -1;
	}
}

$tablefile = 0;
$tablefile = $tablename if -f $tablename;
$tablefile = $unicodedir.'/'.$tablename if -f $unicodedir.'/'.$tablename;
$tablefile = $unicodedir.'/'.$tablename.'.txt' if -f $unicodedir.'/'.$tablename.'.txt';
$tablefile = $unicodedir.'/'.$tablename.'.TXT' if -f $unicodedir.'/'.$tablename.'.TXT';

if( ! $tablefile )
{
	print STDERR "Usage $ARGV[0] [-rev|-uni] [-table tablename] <input >output\n";
	exit 1;
}

foreach $i ( 0..255 )
{
	$unicodeforchar{pack("C",$i)}=pack("S",$i);
	$charforunicode{pack("S",$i)}=pack("C",$i);
}

open(TABLE,$tablefile) || die "Can't open $tablefile\n";
while( $_ = <TABLE> )
{
	if( /^0x([0-9A-Fa-f]+)\s+0x([0-9A-Fa-f]+).*/ )
	{
		$unicodeforchar{pack("C",hex $1)}=pack("S",hex $2);
		$charforunicode{pack("S",hex $2)}=pack("C",hex $1);
	}
}
close(TABLE);

print STDERR "Table read\n";

if( 1 == $tounicode )
{
	print STDOUT pack("S",0xfeff);
	while( 1 == read(STDIN,$character,1) )
	{
		print STDOUT $unicodeforchar{$character};
	}
}
else
{
	while( 2 == read(STDIN,$character,2) )
	{	
		print STDOUT $charforunicode{$character};
	}
}
