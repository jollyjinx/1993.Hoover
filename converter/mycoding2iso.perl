#!/usr/bin/perl

$hash{'A'} = 0xA0;
$hash{'a'} = 0xB0;
$hash{'B'} = 0xC0;
$hash{'C'} = 0xD0;
$hash{'b'} = 0xE0;
$hash{'c'} = 0xF0;

while(<>)
{
	s{ \&([ABCabc]{1})(\d{2});}{ chr($hash{$1} + $2) }gxe;
	print $_;
}
